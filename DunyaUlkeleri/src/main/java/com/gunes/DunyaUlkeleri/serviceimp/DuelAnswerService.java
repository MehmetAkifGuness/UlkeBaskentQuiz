package com.gunes.DunyaUlkeleri.serviceimp;

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
import com.gunes.DunyaUlkeleri.service.AnswerScoreCalculator;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelAnswerService {

    private static final Logger log = LoggerFactory.getLogger(DuelAnswerService.class);

    private final DuelSessionStore sessionStore;
    private final DuelRoundService roundService;
    private final DuelSessionStateMapper stateMapper;
    private final AnswerScoreCalculator scoreCalculator;
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
                    return toState(session, "Yeni tur başlatıldı.");
                }

                expireRoundIfNeeded(session);

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
                final boolean correct = safeEqualsIgnoreCase(selectedOption, round.getCorrectAnswer());
                final int earnedScore = correct ? scoreCalculator.calculateEarnedScore(timeTakenMs / 1000.0) : 0;

                round.getSelectedByPlayerId().put(playerId, selectedOption);
                round.getTimeTakenMsByPlayerId().put(playerId, timeTakenMs);
                round.getEarnedScoreByPlayerId().put(playerId, earnedScore);
                player.setScore(player.getScore() + earnedScore);

                log.info(
                        "Duel answer: sessionId={}, playerId={}, correct={}, earnedScore={}",
                        session.getSessionId(),
                        playerId,
                        correct,
                        earnedScore
                );

                finalizeRoundIfReady(session);
                session.touch();
                sessionStore.save(session);

                stateDto = toState(session, correct ? "Doğru!" : "Yanlış.");

                if (session.getStatus() == DuelGameStatus.FINISHED) {
                    matchResult = leagueAwarder.tryMarkFinished(session);
                }
            }
        }

        matchResult.ifPresent(result -> leagueService.applyMatchResult(result.winnerUsername(), result.loserUsername()));
        return stateDto;
    }

    private void expireRoundIfNeeded(DuelGameSession session) {
        final DuelRound round = session.getCurrentRound();
        if (round == null) return;
        if (!roundService.isRoundExpired(round)) return;

        // Timeout: mark missing answers as wrong (0 points) and finish the round.
        List<DuelPlayer> players = Optional.ofNullable(session.getPlayers()).orElseGet(List::of);
        for (DuelPlayer p : players) {
            if (p == null || p.getPlayerId() == null) continue;
            if (round.getSelectedByPlayerId().containsKey(p.getPlayerId())) continue;
            round.getSelectedByPlayerId().put(p.getPlayerId(), "");
            round.getTimeTakenMsByPlayerId().put(p.getPlayerId(), computeTimeTakenMs(round));
            round.getEarnedScoreByPlayerId().put(p.getPlayerId(), 0);
        }

        finalizeRoundIfReady(session);
    }

    private void finalizeRoundIfReady(DuelGameSession session) {
        final DuelRound round = session.getCurrentRound();
        if (round == null || round.isLocked()) return;

        final int expected = Optional.ofNullable(session.getPlayers()).orElseGet(List::of).size();
        if (round.getSelectedByPlayerId().size() < expected) return;

        round.setLocked(true);
        round.setWinnerPlayerId(determineRoundWinner(session, round));

        if (round.getRoundNumber() >= session.getMaxRounds()) {
            session.setStatus(DuelGameStatus.FINISHED);
            return;
        }

        roundService.startNextRound(session);
    }

    private String determineRoundWinner(DuelGameSession session, DuelRound round) {
        if (session == null || round == null) return null;
        List<DuelPlayer> players = Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .toList();
        if (players.size() != 2) return null;

        String p1 = players.get(0).getPlayerId();
        String p2 = players.get(1).getPlayerId();
        Integer s1 = round.getEarnedScoreByPlayerId().get(p1);
        Integer s2 = round.getEarnedScoreByPlayerId().get(p2);
        if (s1 == null || s2 == null) return null;
        if (s1.equals(s2)) return null;
        return s1 > s2 ? p1 : p2;
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

