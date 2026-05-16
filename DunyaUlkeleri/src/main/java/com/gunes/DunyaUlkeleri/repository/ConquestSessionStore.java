package com.gunes.DunyaUlkeleri.repository;

import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;

public interface ConquestSessionStore {
    ConquestGameSession requireById(String sessionId);

    ConquestGameSession requireByRoomCode(String roomCode);

    void save(ConquestGameSession session);

    void remove(String sessionId);

    boolean isRoomCodeTaken(String roomCode);
}
