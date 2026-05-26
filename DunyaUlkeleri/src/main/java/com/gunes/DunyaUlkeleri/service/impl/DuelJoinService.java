package com.gunes.DunyaUlkeleri.service.impl;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.JoinDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.JoinDuelSessionResponse;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelJoinService {

    private static final Logger log = LoggerFactory.getLogger(DuelJoinService.class);

    private final DuelSessionStore sessionStore;
    private final DuelRoundService roundService;
    private final DuelRoundScheduler roundScheduler;

    public JoinDuelSessionResponse joinSession(String roomCode, JoinDuelSessionRequest request) {
        final String normalizedRoomCode = safeTrim(roomCode);
        final String username = safeTrim(request == null ? null : request.getUsername());
        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }

        final DuelGameSession session = sessionStore.requireByRoomCode(normalizedRoomCode);

        synchronized (session) {
            if (session.getStatus() != DuelGameStatus.WAITING) {
                throw AppException.conflict("ROOM_NOT_WAITING", "Oyun zaten başlamış.");
            }

            final String hostUsername = Optional.ofNullable(session.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .filter(Objects::nonNull)
                    .map(DuelPlayer::getUsername)
                    .filter(Objects::nonNull)
                    .findFirst()
                    .orElse(null);

            if (hostUsername != null && hostUsername.equalsIgnoreCase(username)) {
                throw AppException.conflict("SELF_MATCH", "Kendi odana katılamazsın.");
            }

            final int size = Optional.ofNullable(session.getPlayers()).orElseGet(List::of).size();
            if (size != 1) {
                throw AppException.conflict("ROOM_FULL", "Oda dolu.");
            }

            final String playerId = UUID.randomUUID().toString();
            final DuelPlayer player = new DuelPlayer(playerId, username, 0, true);
            session.addPlayer(player);
            session.setStatus(DuelGameStatus.STARTED);
            roundService.startFirstRound(session);
            session.touch();
            sessionStore.save(session);
            roundScheduler.reschedule(session);

            log.info(
                    "Duel join: sessionId={}, roomCode={}, playerId={}",
                    session.getSessionId(),
                    session.getRoomCode(),
                    playerId
            );
            return new JoinDuelSessionResponse(session.getSessionId(), session.getRoomCode(), playerId);
        }
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}

