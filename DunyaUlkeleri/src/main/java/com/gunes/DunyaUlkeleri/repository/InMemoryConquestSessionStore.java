package com.gunes.DunyaUlkeleri.repository;

import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Repository;

import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

@Repository
public class InMemoryConquestSessionStore implements ConquestSessionStore {

    private final Map<String, ConquestGameSession> sessionsById =
            new ConcurrentHashMap<>();
    private final Map<String, String> roomCodeToSessionId =
            new ConcurrentHashMap<>();

    @Override
    public ConquestGameSession requireById(String sessionId) {
        final String normalizedId = safeTrim(sessionId);
        if (normalizedId == null || normalizedId.isBlank()) {
            throw AppException.badRequest("SESSION_ID_REQUIRED", "SessionId boş olamaz.");
        }

        final ConquestGameSession session = sessionsById.get(normalizedId);
        if (session == null) {
            throw AppException.notFound(
                    "SESSION_NOT_FOUND",
                    "Session bulunamadı: " + normalizedId
            );
        }

        return session;
    }

    @Override
    public ConquestGameSession requireByRoomCode(String roomCode) {
        final String normalizedRoomCode = safeTrim(roomCode);
        if (normalizedRoomCode == null || normalizedRoomCode.isBlank()) {
            throw AppException.badRequest("ROOM_CODE_REQUIRED", "Oda kodu boş olamaz.");
        }

        final String sessionId =
                roomCodeToSessionId.get(normalizedRoomCode.toUpperCase(Locale.ROOT));
        if (sessionId == null) {
            throw AppException.notFound("ROOM_NOT_FOUND", "Oda bulunamadı.");
        }
        return requireById(sessionId);
    }

    @Override
    public void save(ConquestGameSession session) {
        if (session == null) return;
        if (safeTrim(session.getSessionId()) == null) return;

        sessionsById.put(session.getSessionId(), session);

        final String roomCode = safeTrim(session.getRoomCode());
        if (roomCode != null && !roomCode.isBlank()) {
            roomCodeToSessionId.put(roomCode.toUpperCase(Locale.ROOT), session.getSessionId());
        }
    }

    @Override
    public void remove(String sessionId) {
        final String normalizedId = safeTrim(sessionId);
        if (normalizedId == null || normalizedId.isBlank()) return;

        final ConquestGameSession removed = sessionsById.remove(normalizedId);
        if (removed == null) return;

        final String roomCode = safeTrim(removed.getRoomCode());
        if (roomCode != null && !roomCode.isBlank()) {
            roomCodeToSessionId.remove(roomCode.toUpperCase(Locale.ROOT), normalizedId);
        } else {
            // Oda kodu null ise map'ten temizleyebilmek için yedek tarama.
            roomCodeToSessionId.entrySet().removeIf(e -> Objects.equals(e.getValue(), normalizedId));
        }
    }

    @Override
    public boolean isRoomCodeTaken(String roomCode) {
        final String normalized = safeTrim(roomCode);
        if (normalized == null || normalized.isBlank()) return false;
        return roomCodeToSessionId.containsKey(normalized.toUpperCase(Locale.ROOT));
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}
