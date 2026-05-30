package com.gunes.DunyaUlkeleri.service.impl;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.entity.DuelRound;
import com.gunes.DunyaUlkeleri.mapper.DuelSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;
import com.gunes.DunyaUlkeleri.service.LeagueService;

import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelRoundScheduler {

    private static final Logger log = LoggerFactory.getLogger(DuelRoundScheduler.class);

    private final DuelSessionStore sessionStore;
    private final DuelRoundService roundService;
    private final DuelBotAnswerGenerator botAnswerGenerator;
    private final DuelSessionStateMapper stateMapper;
    private final SimpMessagingTemplate messagingTemplate;
    private final DuelLeagueAwarder leagueAwarder;
    private final LeagueService leagueService;

    private final ScheduledThreadPoolExecutor executor = new ScheduledThreadPoolExecutor(2);

    private final ConcurrentHashMap<String, String> roundKeyBySessionId = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, ScheduledFuture<?>> botFutureBySessionId = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, ScheduledFuture<?>> timeoutFutureBySessionId = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, ScheduledFuture<?>> advanceFutureBySessionId = new ConcurrentHashMap<>();

    private static final Duration ROUND_ADVANCE_DELAY = Duration.ofMillis(900);

    public void reschedule(DuelGameSession session) {
        if (session == null) return;
        final String sessionId = DuelRoundSchedulerSupport.safeTrim(session.getSessionId());
        if (sessionId == null || sessionId.isBlank()) return;

        final DuelRound round;
        final DuelGameStatus status;
        synchronized (session) {
            status = session.getStatus();
            round = session.getCurrentRound();
            if (status != DuelGameStatus.STARTED || round == null || round.isLocked()) {
                if (status == DuelGameStatus.FINISHED || round == null) {
                    clear(sessionId);
                } else {
                    DuelRoundSchedulerSupport.cancel(botFutureBySessionId.remove(sessionId));
                    DuelRoundSchedulerSupport.cancel(timeoutFutureBySessionId.remove(sessionId));
                    scheduleAdvance(sessionId, round);
                }
                return;
            }
            roundKeyBySessionId.put(sessionId, DuelRoundSchedulerSupport.keyOf(round));
        }

        DuelRoundSchedulerSupport.cancel(botFutureBySessionId.remove(sessionId));
        DuelRoundSchedulerSupport.cancel(timeoutFutureBySessionId.remove(sessionId));
        DuelRoundSchedulerSupport.cancel(advanceFutureBySessionId.remove(sessionId));

        scheduleTimeout(sessionId, round);
        scheduleBotIfNeeded(sessionId);
    }

    public void clear(String sessionId) {
        final String sid = DuelRoundSchedulerSupport.safeTrim(sessionId);
        if (sid == null || sid.isBlank()) return;
        roundKeyBySessionId.remove(sid);
        DuelRoundSchedulerSupport.cancel(botFutureBySessionId.remove(sid));
        DuelRoundSchedulerSupport.cancel(timeoutFutureBySessionId.remove(sid));
        DuelRoundSchedulerSupport.cancel(advanceFutureBySessionId.remove(sid));
    }

    private void scheduleAdvance(String sessionId, DuelRound round) {
        if (sessionId == null || round == null) return;
        DuelRoundSchedulerSupport.cancel(advanceFutureBySessionId.remove(sessionId));
        advanceFutureBySessionId.put(
                sessionId,
                executor.schedule(
                        () -> onAdvance(sessionId, DuelRoundSchedulerSupport.keyOf(round)),
                        ROUND_ADVANCE_DELAY.toMillis(),
                        TimeUnit.MILLISECONDS
                )
        );
    }

    private void onAdvance(String sessionId, String expectedKey) {
        if (DuelRoundSchedulerSupport.safeTrim(sessionId) == null) return;

        final DuelGameSession session;
        try {
            session = sessionStore.requireById(sessionId);
        } catch (Exception ignored) {
            clear(sessionId);
            return;
        }

        Optional<DuelLeagueAwarder.MatchResult> matchResult = Optional.empty();
        DuelSessionStateDto state;

        synchronized (session) {
            if (session.getStatus() != DuelGameStatus.STARTED) {
                clear(sessionId);
                return;
            }

            DuelRound round = session.getCurrentRound();
            if (round == null) {
                clear(sessionId);
                return;
            }

            final String currentKey = DuelRoundSchedulerSupport.keyOf(round);
            if (!Objects.equals(expectedKey, currentKey)) return;
            if (!round.isLocked()) return;

            if (round.getRoundNumber() >= session.getMaxRounds()) {
                session.setStatus(DuelGameStatus.FINISHED);
                session.touch();
                sessionStore.save(session);
                state = stateMapper.toStateDto(session, null);
                matchResult = leagueAwarder.tryMarkFinished(session);
            } else {
                roundService.startNextRound(session);
                session.touch();
                sessionStore.save(session);
                state = stateMapper.toStateDto(session, null);
            }
        }

        publishState(state);
        matchResult.ifPresent(r -> leagueService.applyMatchResult(r.winnerUsername(), r.loserUsername()));
        if (state != null && state.isFinished()) {
            clear(sessionId);
            return;
        }
        reschedule(session);
    }

    private void scheduleTimeout(String sessionId, DuelRound round) {
        if (sessionId == null || round == null || round.getDeadlineAt() == null) return;
        long delayMs = Duration.between(Instant.now(), round.getDeadlineAt()).toMillis();
        if (delayMs < 0) delayMs = 0;
        timeoutFutureBySessionId.put(
                sessionId,
                executor.schedule(
                        () -> onTimeout(sessionId, DuelRoundSchedulerSupport.keyOf(round)),
                        delayMs,
                        TimeUnit.MILLISECONDS
                )
        );
    }

    private void scheduleBotIfNeeded(String sessionId) {
        if (sessionId == null) return;

        final DuelGameSession session;
        try {
            session = sessionStore.requireById(sessionId);
        } catch (Exception ignored) {
            return;
        }

        final DuelRound round;
        final String botPlayerId;
        final String difficulty;
        synchronized (session) {
            if (!session.isVsBot()) return;
            if (session.getStatus() != DuelGameStatus.STARTED) return;
            round = session.getCurrentRound();
            if (round == null || round.isLocked()) return;
            botPlayerId = DuelRoundSchedulerSupport.safeTrim(session.getBotPlayerId());
            difficulty = DuelRoundSchedulerSupport.safeTrim(session.getBotDifficulty());
            if (botPlayerId == null || botPlayerId.isBlank()) return;
        }

        DuelBotAnswerGenerator.BotAnswer botAnswer = botAnswerGenerator.generate(round, difficulty);
        long delayMs = Math.max(0, botAnswer.timeTakenMs());
        botFutureBySessionId.put(
                sessionId,
                executor.schedule(
                        () -> onBotAnswer(sessionId, DuelRoundSchedulerSupport.keyOf(round), botPlayerId, botAnswer.selectedOption()),
                        delayMs,
                        TimeUnit.MILLISECONDS
                )
        );
    }

    private void onBotAnswer(String sessionId, String expectedKey, String botPlayerId, String selectedOption) {
        if (DuelRoundSchedulerSupport.safeTrim(sessionId) == null || DuelRoundSchedulerSupport.safeTrim(botPlayerId) == null) return;

        final DuelGameSession session;
        try {
            session = sessionStore.requireById(sessionId);
        } catch (Exception ignored) {
            clear(sessionId);
            return;
        }

        Optional<DuelLeagueAwarder.MatchResult> matchResult = Optional.empty();
        DuelSessionStateDto state;
        boolean ended = false;

        synchronized (session) {
            if (!isExpectedRound(sessionId, expectedKey, session)) return;

            DuelRound round = session.getCurrentRound();
            DuelPlayer bot = session.getPlayer(botPlayerId);
            if (round == null || bot == null || round.isLocked()) return;
            if (round.getSelectedByPlayerId().containsKey(botPlayerId)) return;

            boolean correct = DuelRoundSchedulerSupport.recordAnswer(round, botPlayerId, selectedOption);
            session.setLastAnsweredPlayerId(botPlayerId);
            session.setLastAnswerCorrect(correct);
            session.setLastAnsweredRoundNumber(round.getRoundNumber());
            if (correct && DuelRoundSchedulerSupport.safeTrim(round.getWinnerPlayerId()) == null) {
                round.setWinnerPlayerId(botPlayerId);
                round.setLocked(true);
                bot.setScore(bot.getScore() + 1);
            }

            ended = lockIfRoundEnded(session, round);
            session.touch();
            sessionStore.save(session);
            state = stateMapper.toStateDto(session, null);

            if (session.getStatus() == DuelGameStatus.FINISHED) {
                matchResult = leagueAwarder.tryMarkFinished(session);
            }
        }

        publishState(state);
        matchResult.ifPresent(r -> leagueService.applyMatchResult(r.winnerUsername(), r.loserUsername()));
        if (state != null && state.isFinished()) {
            clear(sessionId);
            return;
        }
        if (ended) reschedule(session);
    }

    private void onTimeout(String sessionId, String expectedKey) {
        if (DuelRoundSchedulerSupport.safeTrim(sessionId) == null) return;

        final DuelGameSession session;
        try {
            session = sessionStore.requireById(sessionId);
        } catch (Exception ignored) {
            clear(sessionId);
            return;
        }

        Optional<DuelLeagueAwarder.MatchResult> matchResult = Optional.empty();
        DuelSessionStateDto state;
        boolean ended = false;

        synchronized (session) {
            if (!isExpectedRound(sessionId, expectedKey, session)) return;

            DuelRound round = session.getCurrentRound();
            if (round == null || round.isLocked()) return;

            DuelRoundSchedulerSupport.markMissingAnswers(round, session.getPlayers());
            round.setLocked(true);
            session.setLastAnsweredPlayerId(null);
            session.setLastAnswerCorrect(null);
            session.setLastAnsweredRoundNumber(null);
            ended = lockIfRoundEnded(session, round);
            session.touch();
            sessionStore.save(session);
            state = stateMapper.toStateDto(session, "Süre doldu.");

            if (session.getStatus() == DuelGameStatus.FINISHED) {
                matchResult = leagueAwarder.tryMarkFinished(session);
            }
        }

        publishState(state);
        matchResult.ifPresent(r -> leagueService.applyMatchResult(r.winnerUsername(), r.loserUsername()));
        if (state != null && state.isFinished()) {
            clear(sessionId);
            return;
        }
        if (ended) reschedule(session);
    }

    private boolean lockIfRoundEnded(DuelGameSession session, DuelRound round) {
        if (session == null || round == null) return false;

        if (round.isLocked()) {
            if (round.getRoundNumber() >= session.getMaxRounds()) {
                session.setStatus(DuelGameStatus.FINISHED);
            }
            return true;
        }

        final int expected = (int) Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(p -> p != null && DuelRoundSchedulerSupport.safeTrim(p.getPlayerId()) != null)
                .map(DuelPlayer::getPlayerId)
                .map(DuelRoundSchedulerSupport::safeTrim)
                .filter(pid -> pid != null && !pid.isBlank())
                .distinct()
                .count();
        final boolean hasWinner = DuelRoundSchedulerSupport.safeTrim(round.getWinnerPlayerId()) != null;
        final boolean allAnswered = round.getSelectedByPlayerId().size() >= expected;
        final boolean expired = roundService.isRoundExpired(round);
        if (!hasWinner && !allAnswered && !expired) return false;

        round.setLocked(true);
        if (round.getRoundNumber() >= session.getMaxRounds()) {
            session.setStatus(DuelGameStatus.FINISHED);
            return true;
        }
        return true;
    }

    private boolean isExpectedRound(String sessionId, String expectedKey, DuelGameSession session) {
        if (session == null) return false;
        if (session.getStatus() != DuelGameStatus.STARTED) return false;

        DuelRound round = session.getCurrentRound();
        if (round == null) return false;

        final String currentKey = DuelRoundSchedulerSupport.keyOf(round);
        final String lastKey = roundKeyBySessionId.getOrDefault(sessionId, "");
        if (!Objects.equals(lastKey, currentKey)) return false;
        return Objects.equals(expectedKey, currentKey);
    }

    private void publishState(DuelSessionStateDto state) {
        if (state == null || state.getSessionId() == null || state.getSessionId().isBlank()) return;
        messagingTemplate.convertAndSend("/topic/duel/" + state.getSessionId(), state);
    }

    @PreDestroy
    void shutdown() {
        try {
            executor.shutdownNow();
        } catch (Exception e) {
            log.debug("DuelRoundScheduler shutdown failed: {}", e.getMessage());
        }
    }
}
