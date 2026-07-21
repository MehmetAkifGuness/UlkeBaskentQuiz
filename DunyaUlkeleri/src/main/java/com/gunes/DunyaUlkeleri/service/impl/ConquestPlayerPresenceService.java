package com.gunes.DunyaUlkeleri.service.impl;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.SetConquestReadyRequest;
import com.gunes.DunyaUlkeleri.dto.request.StartConquestGameRequest;
import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.mapper.ConquestSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.ConquestQuickMatchQueue;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestPlayerPresenceService {

    private static final Logger log = LoggerFactory.getLogger(ConquestPlayerPresenceService.class);

    private final ConquestSessionStore sessionStore;
    private final ConquestQuickMatchQueue quickMatchQueue;
    private final ConquestSessionStateMapper stateMapper;
    private final ConquestLeagueAwarder leagueAwarder;
    private final LeagueService leagueService;

    public ConquestSessionStateDto setReady(SetConquestReadyRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        final boolean ready = request != null && request.isReady();

        if (playerId == null || playerId.isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }

        final ConquestGameSession session = sessionStore.requireById(sessionId);
        synchronized (session) {
            final ConquestPlayer player = session.getPlayer(playerId);
            if (player == null) {
                throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadı.");
            }
            player.setReady(ready);
            session.touch();
            return toStateDto(session, ready ? "Hazırım." : "Bekliyorum.", null, false);
        }
    }

    public ConquestSessionStateDto leaveSession(StartConquestGameRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        if (playerId == null || playerId.isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }

        final ConquestGameSession session = sessionStore.requireById(sessionId);
        Optional<ConquestLeagueAwarder.MatchResult> matchResult = Optional.empty();
        ConquestSessionStateDto stateDto;
        synchronized (session) {
            final boolean wasHost = playerId.equals(safeTrim(session.getHostPlayerId()));
            final ConquestPlayer leavingPlayer = session.getPlayer(playerId);
            if (leavingPlayer == null) {
                // Idempotent leave: do not mutate session state if the player is already gone.
                session.touch();
                return toStateDto(session, null, null, false);
            }

            if (session.getStatus() == ConquestGameStatus.STARTED ||
                    session.getStatus() == ConquestGameStatus.PAUSED) {
                matchResult = leagueAwarder.tryMarkLeave(session, playerId);
            }

            session.removePlayer(playerId);

            final boolean empty = session.getPlayers() == null || session.getPlayers().isEmpty();
            if (empty) {
                sessionStore.remove(session.getSessionId());
                if (session.isQuickMatch()) {
                    quickMatchQueue.removeWaitingSessionId(
                            normalizeMatchmakingKey(session),
                            session.getSessionId()
                    );
                }
                log.info(
                        "Session removed (empty): sessionId={}, roomCode={}",
                        session.getSessionId(),
                         session.getRoomCode()
                 );
                 return null;
             }

            if (session.getStatus() == ConquestGameStatus.STARTED ||
                    session.getStatus() == ConquestGameStatus.PAUSED) {
                 session.setStatus(ConquestGameStatus.FINISHED);
             }

            if (wasHost && session.getStatus() == ConquestGameStatus.WAITING) {
                final String newHostId = Optional.ofNullable(session.getPlayers())
                        .orElseGet(List::of)
                        .stream()
                        .filter(Objects::nonNull)
                        .map(ConquestPlayer::getPlayerId)
                        .filter(Objects::nonNull)
                        .findFirst()
                        .orElse(null);
                if (newHostId != null && !newHostId.isBlank()) {
                    session.setHostPlayerId(newHostId);
                }
            }

            Optional.ofNullable(session.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .filter(Objects::nonNull)
                    .forEach(p -> p.setReady(false));

            session.touch();
            stateDto = toStateDto(session, "Oyuncu ayrıldı.", null, false);
        }

        matchResult.ifPresent(result -> leagueService.applyMatchResult(result.winnerUsername(), result.loserUsername()));
        return stateDto;
    }

    public void handleDisconnect(String sessionId, String playerId) {
        if (sessionId == null || playerId == null) return;
        try {
            final ConquestGameSession session = sessionStore.requireById(sessionId);
            synchronized (session) {
                final ConquestPlayer player = session.getPlayer(playerId);
                if (player != null) {
                    player.setConnected(false);
                    session.touch();
                    log.info(
                            "Player disconnected: sessionId={}, playerId={}",
                            session.getSessionId(),
                            playerId
                    );
                }
            }
        } catch (Exception ignored) {
            // Session yoksa ignore.
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

    private static String normalizeContinentFilter(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "ALL";
        return v;
    }

    private static String normalizeMatchmakingKey(ConquestGameSession session) {
        if (session == null) return "ALL";
        final String key = safeTrim(session.getMatchmakingKey());
        if (key != null && !key.isBlank()) return key;
        return normalizeContinentFilter(session.getSelectedContinentFilter());
    }
}
