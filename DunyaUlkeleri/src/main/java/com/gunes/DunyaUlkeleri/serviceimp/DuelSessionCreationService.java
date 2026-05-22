package com.gunes.DunyaUlkeleri.serviceimp;

import java.time.Instant;
import java.util.Locale;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.CreateDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.CreateDuelSessionResponse;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelSessionCreationService {

    private static final Logger log = LoggerFactory.getLogger(DuelSessionCreationService.class);

    private final DuelSessionStore sessionStore;
    private final DuelRoomCodeAllocator roomCodeAllocator;

    public CreateDuelSessionResponse createSession(CreateDuelSessionRequest request, boolean quickMatch) {
        final String username = safeTrim(request == null ? null : request.getUsername());
        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }

        final String category = normalizeCategory(request == null ? null : request.getCategory());
        final String mode = normalizeMode(request == null ? null : request.getMode());

        final String sessionId = UUID.randomUUID().toString();
        final String roomCode = roomCodeAllocator.allocateUniqueRoomCode();
        final String playerId = UUID.randomUUID().toString();

        final DuelPlayer host = new DuelPlayer(playerId, username, 0, true);

        final DuelGameSession session = new DuelGameSession();
        session.setSessionId(sessionId);
        session.setRoomCode(roomCode);
        session.setStatus(DuelGameStatus.WAITING);
        session.setCategory(category);
        session.setMode(mode);
        session.setMatchmakingKey(category + "|" + mode);
        session.setHostPlayerId(playerId);
        session.setQuickMatch(quickMatch);
        session.setCreatedAt(Instant.now());
        session.setUpdatedAt(session.getCreatedAt());
        session.addPlayer(host);

        sessionStore.save(session);

        log.info(
                "Duel session created: sessionId={}, roomCode={}, playerId={}, quickMatch={}",
                sessionId,
                roomCode,
                playerId,
                quickMatch
        );
        return new CreateDuelSessionResponse(sessionId, roomCode, playerId);
    }

    private static String normalizeCategory(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "Dünya";
        return v;
    }

    private static String normalizeMode(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "MIXED";
        return v.toUpperCase(Locale.ROOT);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}

