package com.gunes.DunyaUlkeleri.repository;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;

import org.springframework.stereotype.Repository;

@Repository
public class InMemoryConquestQuickMatchQueue implements ConquestQuickMatchQueue {

    private final Map<String, Object> locksByContinent = new ConcurrentHashMap<>();
    private final Map<String, String> waitingByContinent = new ConcurrentHashMap<>();

    @Override
    public <T> T withLock(String continentFilter, Supplier<T> action) {
        final String key = continentFilter == null ? "ALL" : continentFilter;
        final Object lock = locksByContinent.computeIfAbsent(key, k -> new Object());
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
