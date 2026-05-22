package com.gunes.DunyaUlkeleri.repository;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;

import org.springframework.stereotype.Repository;

@Repository
public class InMemoryDuelQuickMatchQueue implements DuelQuickMatchQueue {

    private final Map<String, Object> locksByKey = new ConcurrentHashMap<>();
    private final Map<String, String> waitingByKey = new ConcurrentHashMap<>();

    @Override
    public <T> T withLock(String matchmakingKey, Supplier<T> action) {
        final String key = matchmakingKey == null ? "DEFAULT" : matchmakingKey;
        final Object lock = locksByKey.computeIfAbsent(key, k -> new Object());
        synchronized (lock) {
            return action.get();
        }
    }

    @Override
    public String getWaitingSessionId(String matchmakingKey) {
        return waitingByKey.get(matchmakingKey);
    }

    @Override
    public void putWaitingSessionId(String matchmakingKey, String sessionId) {
        waitingByKey.put(matchmakingKey, sessionId);
    }

    @Override
    public boolean removeWaitingSessionId(String matchmakingKey, String sessionId) {
        return waitingByKey.remove(matchmakingKey, sessionId);
    }
}

