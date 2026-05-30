package com.gunes.DunyaUlkeleri.service.impl;

import java.time.Duration;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestRound;
import com.gunes.DunyaUlkeleri.mapper.ConquestSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.service.ConquestRoundService;

import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestRoundScheduler {

    private static final Logger log = LoggerFactory.getLogger(ConquestRoundScheduler.class);
    private static final Duration ROUND_ADVANCE_DELAY = Duration.ofMillis(900);

    private final ConquestSessionStore sessionStore;
    private final ConquestRoundService roundService;
    private final ConquestSessionStateMapper stateMapper;
    private final SimpMessagingTemplate messagingTemplate;

    private final ScheduledThreadPoolExecutor executor = new ScheduledThreadPoolExecutor(1);
    private final ConcurrentHashMap<String, ScheduledFuture<?>> advanceFutureBySessionId = new ConcurrentHashMap<>();

    public void reschedule(ConquestGameSession session) {
        if (session == null) return;
        final String sessionId = safeTrim(session.getSessionId());
        if (sessionId == null || sessionId.isBlank()) return;

        final ConquestGameStatus status;
        final ConquestRound round;
        synchronized (session) {
            status = session.getStatus();
            round = session.getCurrentRound();
            if (status != ConquestGameStatus.STARTED || round == null) {
                clear(sessionId);
                return;
            }
            if (!round.isLocked()) {
                cancelAdvance(sessionId);
                return;
            }
        }

        scheduleAdvance(sessionId, round);
    }

    public void clear(String sessionId) {
        final String sid = safeTrim(sessionId);
        if (sid == null || sid.isBlank()) return;
        cancelAdvance(sid);
    }

    private void cancelAdvance(String sessionId) {
        cancel(advanceFutureBySessionId.remove(sessionId));
    }

    private void scheduleAdvance(String sessionId, ConquestRound round) {
        if (sessionId == null || round == null) return;
        cancelAdvance(sessionId);
        advanceFutureBySessionId.put(
                sessionId,
                executor.schedule(
                        () -> onAdvance(sessionId, keyOf(round)),
                        ROUND_ADVANCE_DELAY.toMillis(),
                        TimeUnit.MILLISECONDS
                )
        );
    }

    private void onAdvance(String sessionId, String expectedKey) {
        final ConquestGameSession session;
        try {
            session = sessionStore.requireById(sessionId);
        } catch (Exception ignored) {
            clear(sessionId);
            return;
        }

        final ConquestSessionStateDto state;
        synchronized (session) {
            if (session.getStatus() != ConquestGameStatus.STARTED) {
                clear(sessionId);
                return;
            }

            final ConquestRound current = session.getCurrentRound();
            if (current == null) {
                clear(sessionId);
                return;
            }

            if (!Objects.equals(expectedKey, keyOf(current))) return;
            if (!current.isLocked()) return;

            roundService.pickNextTargetCountry(session, safeTrim(current.getWinnerPlayerId()));
            session.touch();
            sessionStore.save(session);
            state = stateMapper.toStateDto(session, null, null, false);
        }

        publishState(state);
        if (state != null && "FINISHED".equalsIgnoreCase(safeTrim(state.getStatus()))) {
            clear(sessionId);
        }
    }

    private void publishState(ConquestSessionStateDto state) {
        if (state == null || safeTrim(state.getSessionId()) == null) return;
        messagingTemplate.convertAndSend("/topic/conquest/" + state.getSessionId(), state);
    }

    private static void cancel(ScheduledFuture<?> future) {
        if (future == null) return;
        try {
            future.cancel(false);
        } catch (Exception ignored) {
        }
    }

    private static String keyOf(ConquestRound round) {
        if (round == null) return "";
        final String iso = safeTrim(round.getTargetIsoCode());
        return round.getRoundNumber() + ":" + (iso == null ? "-" : iso);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    @PreDestroy
    public void shutdown() {
        try {
            executor.shutdownNow();
        } catch (Exception e) {
            log.debug("ConquestRoundScheduler shutdown failed: {}", e.getMessage());
        }
    }
}
