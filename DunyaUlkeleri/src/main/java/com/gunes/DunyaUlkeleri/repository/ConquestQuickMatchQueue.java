package com.gunes.DunyaUlkeleri.repository;

import java.util.function.Supplier;

public interface ConquestQuickMatchQueue {
    <T> T withLock(Supplier<T> action);

    String getWaitingSessionId(String continentFilter);

    void putWaitingSessionId(String continentFilter, String sessionId);

    boolean removeWaitingSessionId(String continentFilter, String sessionId);
}
