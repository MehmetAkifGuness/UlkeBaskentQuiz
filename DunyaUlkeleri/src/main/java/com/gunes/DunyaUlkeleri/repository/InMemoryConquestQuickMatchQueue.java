package com.gunes.DunyaUlkeleri.repository;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;

import org.springframework.stereotype.Repository;

@Repository
public class InMemoryConquestQuickMatchQueue implements ConquestQuickMatchQueue {

    private final Object lock = new Object();
    private final Map<String, String> waitingByContinent = new ConcurrentHashMap<>();

    @Override
    public <T> T withLock(Supplier<T> action) {
        synchronized (lock) {
            return action.get();
        }
    }

    @Override
    public String getWaitingSessionId(String continentFilter) {
        return waitingByContinent.get(continentFilter);
    }

    @Override
    public void putWaitingSessionId(String continentFilter, String sessionId) {
        waitingByContinent.put(continentFilter, sessionId);
    }

    @Override
    public boolean removeWaitingSessionId(String continentFilter, String sessionId) {
        return waitingByContinent.remove(continentFilter, sessionId);
    }
}
