package com.gunes.DunyaUlkeleri.repository;

import java.util.function.Supplier;

public interface DuelQuickMatchQueue {
    <T> T withLock(String matchmakingKey, Supplier<T> action);

    String getWaitingSessionId(String matchmakingKey);

    void putWaitingSessionId(String matchmakingKey, String sessionId);

    boolean removeWaitingSessionId(String matchmakingKey, String sessionId);
}

