package com.gunes.DunyaUlkeleri.service.impl;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.SubmitDuelAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.entity.DuelRound;
import com.gunes.DunyaUlkeleri.mapper.DuelSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelAnswerService {

    private static final Logger log = LoggerFactory.getLogger(DuelAnswerService.class);

    private final DuelSessionStore sessionStore;
    private final DuelRoundService roundService;
    private final DuelRoundScheduler roundScheduler;
    private final DuelSessionStateMapper stateMapper;
    private final DuelLeagueAwarder leagueAwarder;
    private final LeagueService leagueService;

    public DuelSessionStateDto submitAnswer(SubmitDuelAnswerRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        final String selectedOption = safeTrim(request == null ? null : request.getSelectedOption());

        if (playerId == null || playerId.isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }

        final DuelGameSession session = sessionStore.requireById(sessionId);

        Optional<DuelLeagueAwarder.MatchResult> matchResult = Optional.empty();
        DuelSessionStateDto stateDto;

        synchronized (session) {
            if (session.getStatus() == DuelGameStatus.FINISHED) {
                stateDto = toState(session, "Oyun bitti.");
                matchResult = leagueAwarder.tryMarkFinished(session);
                // fallthrough to apply trophies outside lock
            } else {
                if (session.getStatus() != DuelGameStatus.STARTED) {
                    throw AppException.conflict("GAME_NOT_STARTED", "Oyun başlamadı.");
                }

                final DuelRound round = session.getCurrentRound();
                if (round == null) {
                    roundService.startNextRound(session);
                    sessionStore.save(session);
                    roundScheduler.reschedule(session);
                    return toState(session, "Yeni tur başlatıldı.");
                }

                final boolean expired = expireRoundIfNeeded(session, round);
                if (expired) {
                    session.touch();
                    sessionStore.save(session);
                    roundScheduler.reschedule(session);
                    return toState(session, null);
                }

                if (round.isLocked()) {
                    return toState(session, null);
                }

                if (selectedOption == null || selectedOption.isBlank()) {
                    throw AppException.badRequest("OPTION_REQUIRED", "Seçenek boş olamaz.");
                }

                final DuelPlayer player = session.getPlayer(playerId);
                if (player == null) {
                    throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadı.");
                }

                // Idempotency: ignore duplicate answers for the same round.
                if (round.getSelectedByPlayerId().containsKey(playerId)) {
                    return toState(session, "Cevabın alındı.");
                }

                final long timeTakenMs = computeTimeTakenMs(round);
                final boolean correct = recordAnswer(round, playerId, selectedOption, timeTakenMs);
                session.setLastAnsweredPlayerId(playerId);
                session.setLastAnswerCorrect(correct);
                session.setLastAnsweredRoundNumber(round.getRoundNumber());

                if (correct && safeTrim(round.getWinnerPlayerId()) == null) {
                    round.setWinnerPlayerId(playerId);
                    round.setLocked(true);
                    player.setScore(player.getScore() + 1);
                }

                final boolean roundEnded = lockIfRoundEnded(session, round);
                session.touch();
                sessionStore.save(session);

                stateDto = toState(session, correct ? "Doğru!" : "Yanlış.");

                if (session.getStatus() == DuelGameStatus.STARTED) {
                    if (roundEnded) {
                        roundScheduler.reschedule(session);
                    }
                } else if (session.getStatus() == DuelGameStatus.FINISHED) {
                    roundScheduler.clear(session.getSessionId());
                }

                if (session.getStatus() == DuelGameStatus.FINISHED) {
                    matchResult = leagueAwarder.tryMarkFinished(session);
                }
            }
        }

        matchResult.ifPresent(result -> leagueService.applyMatchResult(result.winnerUsername(), result.loserUsername()));
        return stateDto;
    }

    private static boolean recordAnswer(DuelRound round, String playerId, String selectedOption, long timeTakenMs) {
        if (round == null) return false;
        final String pid = safeTrim(playerId);
        if (pid == null || pid.isBlank()) return false;

        final long safeMs = Math.max(0, timeTakenMs);
        final String selected = safeTrim(selectedOption);

        round.getSelectedByPlayerId().put(pid, selected == null ? "" : selected);
        round.getTimeTakenMsByPlayerId().put(pid, safeMs);

        return safeEqualsIgnoreCase(selectedOption, round.getCorrectAnswer());
    }

    private boolean expireRoundIfNeeded(DuelGameSession session, DuelRound round) {
        if (session == null || round == null) return false;
        if (!roundService.isRoundExpired(round)) return false;

        List<DuelPlayer> players = Optional.ofNullable(session.getPlayers()).orElseGet(List::of);
        for (DuelPlayer p : players) {
            if (p == null || safeTrim(p.getPlayerId()) == null) continue;
            if (round.getSelectedByPlayerId().containsKey(p.getPlayerId())) continue;
            recordAnswer(round, p.getPlayerId(), "", computeTimeTakenMs(round));
        }
        round.setLocked(true);

        if (round.getRoundNumber() >= session.getMaxRounds()) {
            session.setStatus(DuelGameStatus.FINISHED);
        }
        return true;
    }

    private boolean lockIfRoundEnded(DuelGameSession session, DuelRound round) {
        if (session == null || round == null) return false;

        boolean ended = round.isLocked();
        if (!ended) {
            final int expected = expectedAnswerCount(session);
            ended = round.getSelectedByPlayerId().size() >= expected
                    || safeTrim(round.getWinnerPlayerId()) != null
                    || roundService.isRoundExpired(round);
            if (ended) {
                round.setLocked(true);
            }
        }
        if (!ended) return false;

        if (round.getRoundNumber() >= session.getMaxRounds()) {
            session.setStatus(DuelGameStatus.FINISHED);
        }
        return true;
    }

    private static int expectedAnswerCount(DuelGameSession session) {
        if (session == null) return 0;
        return (int) Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .map(DuelPlayer::getPlayerId)
                .map(DuelAnswerService::safeTrim)
                .filter(pid -> pid != null && !pid.isBlank())
                .distinct()
                .count();
    }

    private static String keyOf(DuelRound round) {
        if (round == null) return "";
        return (round.getQuestionId() == null ? "-" : round.getQuestionId().toString()) + ":" + round.getRoundNumber();
    }

    private DuelSessionStateDto toState(DuelGameSession session, String message) {
        return stateMapper.toStateDto(session, message);
    }

    private static long computeTimeTakenMs(DuelRound round) {
        if (round == null || round.getStartedAt() == null) return 0;
        long ms = Duration.between(round.getStartedAt(), Instant.now()).toMillis();
        if (ms < 0) ms = 0;
        return ms;
    }

    private static boolean safeEqualsIgnoreCase(String left, String right) {
        final String l = safeTrim(left);
        final String r = safeTrim(right);
        if (l == null || r == null) return false;
        return l.equalsIgnoreCase(r);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}

