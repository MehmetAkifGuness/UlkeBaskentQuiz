package com.gunes.DunyaUlkeleri.serviceimp;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.JoinConquestSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.JoinConquestSessionResponse;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayerType;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestJoinService {

    private static final Logger log = LoggerFactory.getLogger(ConquestJoinService.class);
    private static final int INITIAL_LIVES = 3;

    private final ConquestSessionStore sessionStore;

    public JoinConquestSessionResponse joinSession(String roomCode, JoinConquestSessionRequest request) {
        final String normalizedRoomCode = safeTrim(roomCode);
        if (normalizedRoomCode == null || normalizedRoomCode.isBlank()) {
            throw AppException.badRequest("ROOM_CODE_REQUIRED", "Oda kodu boş olamaz.");
        }

        final ConquestGameSession session = sessionStore.requireByRoomCode(normalizedRoomCode);
        final String username = safeTrim(request == null ? null : request.getUsername());
        final String colorHex = safeTrim(request == null ? null : request.getColorHex());

        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }
        if (colorHex == null || colorHex.isBlank()) {
            throw AppException.badRequest("COLOR_REQUIRED", "Renk bilgisi (colorHex) boş olamaz.");
        }

        final String playerId = UUID.randomUUID().toString();
        final ConquestPlayer player = new ConquestPlayer(
                playerId,
                username,
                colorHex,
                ConquestPlayerType.HUMAN,
                0,
                0,
                INITIAL_LIVES,
                true,
                false
        );

        synchronized (session) {
            if (session.isQuickMatch()) {
                throw AppException.conflict(
                        "ROOM_NOT_JOINABLE",
                        "Bu oda hızlı oyun odasıdır. Odaya katılamazsınız."
                );
            }
            if (session.getStatus() == ConquestGameStatus.FINISHED) {
                throw AppException.conflict("ROOM_FINISHED", "Oda kapandı. Lütfen yeni bir oda oluşturun.");
            }
            if (session.getStatus() != ConquestGameStatus.WAITING) {
                throw AppException.conflict("ROOM_ALREADY_STARTED", "Oyun başladı. Odaya katılamazsınız.");
            }

            final boolean alreadyInRoom = Optional.ofNullable(session.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .anyMatch(p -> p != null && p.getUsername() != null && p.getUsername().equalsIgnoreCase(username));
            if (alreadyInRoom) {
                throw AppException.conflict("ALREADY_IN_ROOM", "Bu odada zaten varsınız.");
            }

            final String normalizedColor = normalizeColorHex(colorHex);
            if (normalizedColor != null) {
                final boolean colorTaken = Optional.ofNullable(session.getPlayers())
                        .orElseGet(List::of)
                        .stream()
                        .anyMatch(p -> normalizeColorHex(p == null ? null : p.getColorHex())
                                .equalsIgnoreCase(normalizedColor));
                if (colorTaken) {
                    throw AppException.conflict(
                            "COLOR_TAKEN",
                            "Bu renk zaten seçildi. Lütfen farklı bir renk seçin."
                    );
                }
            }

            final int currentSize = Optional.ofNullable(session.getPlayers()).orElseGet(List::of).size();
            if (currentSize >= 2) {
                throw AppException.conflict("ROOM_FULL", "Oda dolu.");
            }
            session.addPlayer(player);
            session.touch();
        }

        log.info(
                "Player joined: sessionId={}, roomCode={}, playerId={}, username={}",
                session.getSessionId(),
                session.getRoomCode(),
                playerId,
                username
        );

        return new JoinConquestSessionResponse(session.getSessionId(), session.getRoomCode(), playerId);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static String normalizeColorHex(String raw) {
        final String v = safeTrim(raw);
        if (v == null || v.isBlank()) return "";

        String cleaned = v.replace("#", "");
        if (cleaned.startsWith("0x") || cleaned.startsWith("0X")) {
            cleaned = cleaned.substring(2);
        }
        cleaned = cleaned.trim().toUpperCase();

        if (cleaned.length() == 6) {
            cleaned = "FF" + cleaned;
        }

        return cleaned;
    }
}
