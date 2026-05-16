package com.gunes.DunyaUlkeleri.serviceimp;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.StartConquestGameRequest;
import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.mapper.ConquestSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.service.ConquestRoundService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestStartGameService {

    private static final Logger log = LoggerFactory.getLogger(ConquestStartGameService.class);
    private static final int INITIAL_LIVES = 3;

    private final ConquestSessionStore sessionStore;
    private final ConquestRoundService roundService;
    private final ConquestSessionStateMapper stateMapper;

    public ConquestSessionStateDto startGame(StartConquestGameRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        if (playerId == null || playerId.isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }

        final ConquestGameSession session = sessionStore.requireById(sessionId);

        synchronized (session) {
            if (session.getStatus() == ConquestGameStatus.FINISHED) {
                return toStateDto(session, "Oyun zaten bitti.", null, true);
            }
            if (!session.canStart() && session.getStatus() != ConquestGameStatus.STARTED) {
                throw AppException.conflict(
                        "GAME_NOT_STARTABLE",
                        "Rakip bekleniyor. Oyun başlatmak için en az 2 oyuncu gerekli."
                );
            }

            if (session.getPlayer(playerId) == null) {
                throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadı.");
            }

            final String hostId = safeTrim(session.getHostPlayerId());
            if (hostId != null && !hostId.isBlank() && !hostId.equals(playerId)) {
                throw AppException.forbidden("HOST_ONLY", "Sadece oda sahibi oyunu başlatabilir.");
            }

            final boolean allReady = Optional.ofNullable(session.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .filter(Objects::nonNull)
                    .allMatch(ConquestPlayer::isReady);
            if (!session.isQuickMatch() && !allReady) {
                throw AppException.conflict(
                        "PLAYERS_NOT_READY",
                        "Oyunu başlatmak için tüm oyuncular hazır olmalı."
                );
            }

            if (session.getStatus() != ConquestGameStatus.STARTED) {
                session.setStatus(ConquestGameStatus.STARTED);

                Optional.ofNullable(session.getPlayers())
                        .orElseGet(List::of)
                        .stream()
                        .filter(Objects::nonNull)
                        .forEach(p -> p.setRemainingLives(INITIAL_LIVES));

                roundService.pickNextTargetCountry(session, null);
                session.touch();
                log.info("Game started: sessionId={}, roomCode={}", session.getSessionId(), session.getRoomCode());
            }

            return toStateDto(
                    session,
                    "Oyun başladı.",
                    null,
                    session.getCurrentRound() != null && session.getCurrentRound().isLocked()
            );
        }
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
}

