package com.gunes.DunyaUlkeleri.service.impl;

import java.time.Instant;
import java.util.Locale;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.SubmitConquestAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.entity.ConquestRound;
import com.gunes.DunyaUlkeleri.mapper.ConquestSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.service.ConquestRoundService;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestAnswerService {

    private static final Logger log = LoggerFactory.getLogger(ConquestAnswerService.class);

    private final ConquestSessionStore sessionStore;
    private final ConquestRoundService roundService;
    private final ConquestRoundScheduler roundScheduler;
    private final ConquestSessionStateMapper stateMapper;
    private final ConquestLeagueAwarder leagueAwarder;
    private final LeagueService leagueService;

    public ConquestSessionStateDto submitAnswer(SubmitConquestAnswerRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        final String selectedIsoCode = safeTrim(request == null ? null : request.getSelectedIsoCode());

        final ConquestGameSession session = sessionStore.requireById(sessionId);

        Optional<ConquestLeagueAwarder.MatchResult> matchResult = Optional.empty();
        ConquestSessionStateDto stateDto;

        synchronized (session) {
            if (session.getStatus() == ConquestGameStatus.FINISHED) {
                final String winnerId = session.getCurrentRound() == null
                        ? null
                        : session.getCurrentRound().getWinnerPlayerId();
                stateDto = toStateDto(session, "Oyun bitti.", winnerId, true);
                matchResult = leagueAwarder.tryMarkFinishedGame(session);
                roundScheduler.clear(session.getSessionId());
            } else {
                if (session.getStatus() != ConquestGameStatus.STARTED) {
                    throw AppException.conflict("GAME_NOT_STARTED", "Oyun başlamadı.");
                }

                if (playerId == null || playerId.isBlank()) {
                    throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
                }

                final ConquestRound round = session.getCurrentRound();
                if (round == null) {
                    roundService.pickNextTargetCountry(session, null);
                    session.touch();
                    sessionStore.save(session);
                    return toStateDto(session, "Yeni tur başlatıldı.", null, false);
                }

                if (round.isLocked()) {
                    return toStateDto(session, null, round.getWinnerPlayerId(), true);
                }

                final ConquestPlayer player = session.getPlayer(playerId);
                if (player == null) {
                    throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadı.");
                }

                if (player.getRemainingLives() <= 0) {
                    if (roundService.areAllPlayersOutOfLives(session)) {
                        lockSkippedRound(round);
                        session.touch();
                        sessionStore.save(session);
                        stateDto = toStateDto(session, "İki tarafın da canı bitti. Ülke atlandı.", null, true);
                        roundScheduler.reschedule(session);
                        return stateDto;
                    }
                    return toStateDto(session, "Bu tur için canın bitti.", null, false);
                }

                if (selectedIsoCode == null || selectedIsoCode.isBlank()) {
                    throw AppException.badRequest("ISO_REQUIRED", "Ülke kodu (ISO) boş olamaz.");
                }

                final String normalizedSelectedIso = selectedIsoCode.trim().toUpperCase(Locale.ROOT);
                final String normalizedTargetIso = safeTrim(round.getTargetIsoCode());

                if (normalizedTargetIso != null && normalizedTargetIso.equalsIgnoreCase(normalizedSelectedIso)) {
                    roundService.finishRound(session, player, round);
                    session.touch();
                    sessionStore.save(session);

                    if (session.isFinished()) {
                        session.setStatus(ConquestGameStatus.FINISHED);
                        sessionStore.save(session);
                        matchResult = leagueAwarder.tryMarkFinishedGame(session);
                        log.info("Game finished: sessionId={}, roomCode={}", session.getSessionId(), session.getRoomCode());
                        stateDto = toStateDto(session, "Tebrikler! Tüm ülkeler fethedildi.", player.getPlayerId(), true);
                        roundScheduler.clear(session.getSessionId());
                    } else {
                        stateDto = toStateDto(session, "Round kazanıldı.", player.getPlayerId(), true);
                        roundScheduler.reschedule(session);
                        return stateDto;
                    }
                } else {
                    player.setRemainingLives(Math.max(0, player.getRemainingLives() - 1));
                    session.touch();
                    sessionStore.save(session);

                    log.info(
                            "Wrong answer: sessionId={}, playerId={}, selectedIso={}, remainingLives={}",
                            session.getSessionId(),
                            playerId,
                            normalizedSelectedIso,
                            player.getRemainingLives()
                    );

                    if (roundService.areAllPlayersOutOfLives(session)) {
                        lockSkippedRound(round);
                        session.touch();
                        sessionStore.save(session);
                        stateDto = toStateDto(session, "İki tarafın da canı bitti. Ülke atlandı.", null, true);
                        roundScheduler.reschedule(session);
                        return stateDto;
                    }

                    return toStateDto(session, "Yanlış cevap (-1 can).", null, false);
                }
            }
        }

        matchResult.ifPresent(result -> leagueService.applyMatchResult(result.winnerUsername(), result.loserUsername()));
        return stateDto;
    }

    private ConquestSessionStateDto toStateDto(
            ConquestGameSession session,
            String lastEventMessage,
            String lastWinnerPlayerId,
            boolean roundLocked
    ) {
        return stateMapper.toStateDto(session, lastEventMessage, lastWinnerPlayerId, roundLocked);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static void lockSkippedRound(ConquestRound round) {
        if (round == null || round.isLocked()) return;
        round.setLocked(true);
        round.setWinnerPlayerId(null);
        round.setFinishedAt(Instant.now());
    }
}
