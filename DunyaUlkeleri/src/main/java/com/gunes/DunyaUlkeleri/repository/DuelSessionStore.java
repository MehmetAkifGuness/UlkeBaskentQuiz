package com.gunes.DunyaUlkeleri.repository;

import com.gunes.DunyaUlkeleri.entity.DuelGameSession;

public interface DuelSessionStore {
    DuelGameSession requireById(String sessionId);

    DuelGameSession requireByRoomCode(String roomCode);

    void save(DuelGameSession session);

    void remove(String sessionId);

    boolean isRoomCodeTaken(String roomCode);
}

