package com.gunes.DunyaUlkeleri.service.impl;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.LeaveDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.mapper.DuelSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.DuelQuickMatchQueue;
import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelPlayerPresenceService {

    private static final Logger log = LoggerFactory.getLogger(DuelPlayerPresenceService.class);

    private final DuelSessionStore sessionStore;
    private final DuelQuickMatchQueue quickMatchQueue;
    private final DuelSessionStateMapper stateMapper;
    private final DuelRoundScheduler roundScheduler;
    private final DuelLeagueAwarder leagueAwarder;
    private final LeagueService leagueService;

    public DuelSessionStateDto leaveSession(LeaveDuelSessionRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        if (playerId == null || playerId.isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }

        final DuelGameSession session = sessionStore.requireById(sessionId);
        Optional<DuelLeagueAwarder.MatchResult> matchResult = Optional.empty();
        DuelSessionStateDto stateDto;

        synchronized (session) {
            final DuelPlayer leavingPlayer = session.getPlayer(playerId);
            if (leavingPlayer == null) {
                session.touch();
                return toState(session, null);
            }

            if (session.getStatus() == DuelGameStatus.STARTED) {
                matchResult = leagueAwarder.tryMarkLeave(session, playerId);
                session.setStatus(DuelGameStatus.FINISHED);
                roundScheduler.clear(session.getSessionId());
            }

            final boolean wasHost = playerId.equals(safeTrim(session.getHostPlayerId()));
            session.removePlayer(playerId);

            final boolean empty = session.getPlayers() == null || session.getPlayers().isEmpty();
            if (empty) {
                sessionStore.remove(session.getSessionId());
                roundScheduler.clear(session.getSessionId());
                if (session.isQuickMatch()) {
                    quickMatchQueue.removeWaitingSessionId(
                            normalizeMatchmakingKey(session),
                            session.getSessionId()
                    );
                }
                log.info("Duel session removed (empty): sessionId={}, roomCode={}", session.getSessionId(), session.getRoomCode());
                return null;
            }

            if (wasHost && session.getStatus() == DuelGameStatus.WAITING) {
                final String newHostId = Optional.ofNullable(session.getPlayers())
                        .orElseGet(List::of)
                        .stream()
                        .filter(Objects::nonNull)
                        .map(DuelPlayer::getPlayerId)
                        .filter(Objects::nonNull)
                        .findFirst()
                        .orElse(null);
                if (newHostId != null && !newHostId.isBlank()) {
                    session.setHostPlayerId(newHostId);
                }
            }

            session.touch();
            sessionStore.save(session);
            stateDto = toState(session, "Oyuncu ayrıldı.");
        }

        matchResult.ifPresent(result -> leagueService.applyMatchResult(result.winnerUsername(), result.loserUsername()));
        return stateDto;
    }

    public void handleDisconnect(String sessionId, String playerId) {
        if (sessionId == null || playerId == null) return;
        try {
            final DuelGameSession session = sessionStore.requireById(sessionId);
            synchronized (session) {
                final DuelPlayer player = session.getPlayer(playerId);
                if (player != null) {
                    player.setConnected(false);
                    session.touch();
                    log.info("Duel player disconnected: sessionId={}, playerId={}", session.getSessionId(), playerId);
                }
            }
        } catch (Exception ignored) {
            // Session yoksa ignore.
        }
    }

    private DuelSessionStateDto toState(DuelGameSession session, String message) {
        return stateMapper.toStateDto(session, message);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static String normalizeCategory(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "Dünya";
        return v;
    }

    private static String normalizeMatchmakingKey(DuelGameSession session) {
        if (session == null) return "Dünya|MIXED";
        final String key = safeTrim(session.getMatchmakingKey());
        if (key != null && !key.isBlank()) return key;
        return normalizeCategory(session.getCategory()) + "|MIXED";
    }
}

