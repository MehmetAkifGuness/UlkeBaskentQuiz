package com.gunes.DunyaUlkeleri.repository;

import java.util.Locale;
import java.util.Map;
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
    private final Map<String, String> sessionIdToRoomCode =
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
        final String sessionId = safeTrim(session.getSessionId());
        if (sessionId == null) return;

        sessionsById.put(sessionId, session);

        final String roomCode = safeTrim(session.getRoomCode());
        if (roomCode != null && !roomCode.isBlank()) {
            final String normalizedRoomCode = roomCode.toUpperCase(Locale.ROOT);
            final String previous = sessionIdToRoomCode.put(sessionId, normalizedRoomCode);
            if (previous != null && !previous.equals(normalizedRoomCode)) {
                roomCodeToSessionId.remove(previous, sessionId);
            }
            roomCodeToSessionId.put(normalizedRoomCode, sessionId);
            return;
        }

        final String previous = sessionIdToRoomCode.remove(sessionId);
        if (previous != null && !previous.isBlank()) {
            roomCodeToSessionId.remove(previous, sessionId);
        }
    }

    @Override
    public void remove(String sessionId) {
        final String normalizedId = safeTrim(sessionId);
        if (normalizedId == null || normalizedId.isBlank()) return;

        sessionsById.remove(normalizedId);

        final String normalizedRoomCode = sessionIdToRoomCode.remove(normalizedId);
        if (normalizedRoomCode == null || normalizedRoomCode.isBlank()) return;
        roomCodeToSessionId.remove(normalizedRoomCode, normalizedId);
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
