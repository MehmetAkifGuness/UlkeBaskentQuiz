package com.gunes.DunyaUlkeleri.serviceimp;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.CreateConquestSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.CreateConquestSessionResponse;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayerType;
import com.gunes.DunyaUlkeleri.repository.ConquestQuickMatchQueue;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.service.ConquestRoundService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestQuickMatchService {

    private static final Logger log = LoggerFactory.getLogger(ConquestQuickMatchService.class);
    private static final int INITIAL_LIVES = 3;

    private final ConquestSessionStore sessionStore;
    private final ConquestQuickMatchQueue quickMatchQueue;
    private final ConquestRoundService roundService;
    private final ConquestSessionCreationService sessionCreationService;

    public CreateConquestSessionResponse quickMatch(CreateConquestSessionRequest request) {
        final String continentFilter = normalizeContinentFilter(
                request == null ? null : request.getContinentFilter()
        );
        if (continentFilter == null || continentFilter.isBlank()) {
            throw AppException.badRequest("CONTINENT_REQUIRED", "KÄ±ta filtresi boÅŸ olamaz.");
        }

        return quickMatchQueue.withLock(() -> quickMatchWithinLock(continentFilter, request));
    }

    private CreateConquestSessionResponse quickMatchWithinLock(
            String continentFilter,
            CreateConquestSessionRequest request
    ) {
        final String waitingSessionId = quickMatchQueue.getWaitingSessionId(continentFilter);
        final ConquestGameSession waiting = waitingSessionId == null
                ? null
                : getWaitingSessionIfValid(continentFilter, waitingSessionId);

        if (waiting != null) {
            return pairIntoWaitingSession(continentFilter, waitingSessionId, waiting, request);
        }

        final CreateConquestSessionResponse created = sessionCreationService.createSession(request, true);
        quickMatchQueue.putWaitingSessionId(continentFilter, created.getSessionId());
        log.info(
                "Quick match enqueued: sessionId={}, roomCode={}, playerId={}",
                created.getSessionId(),
                created.getRoomCode(),
                created.getPlayerId()
        );
        return created;
    }

    private ConquestGameSession getWaitingSessionIfValid(
            String continentFilter,
            String waitingSessionId
    ) {
        final ConquestGameSession waiting;
        try {
            waiting = sessionStore.requireById(waitingSessionId);
        } catch (Exception e) {
            quickMatchQueue.removeWaitingSessionId(continentFilter, waitingSessionId);
            return null;
        }

        final int size = Optional.ofNullable(waiting.getPlayers()).orElseGet(List::of).size();
        final boolean valid = waiting.getStatus() == ConquestGameStatus.WAITING
                && waiting.isQuickMatch()
                && size == 1;
        if (!valid) {
            quickMatchQueue.removeWaitingSessionId(continentFilter, waitingSessionId);
            return null;
        }

        return waiting;
    }

    private CreateConquestSessionResponse pairIntoWaitingSession(
            String continentFilter,
            String waitingSessionId,
            ConquestGameSession waiting,
            CreateConquestSessionRequest request
    ) {
        final String username = safeTrim(request == null ? null : request.getUsername());
        final String colorHex = safeTrim(request == null ? null : request.getColorHex());
        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "KullanÄ±cÄ± adÄ± boÅŸ olamaz.");
        }
        if (colorHex == null || colorHex.isBlank()) {
            throw AppException.badRequest("COLOR_REQUIRED", "Renk bilgisi (colorHex) boÅŸ olamaz.");
        }

        final String playerId = UUID.randomUUID().toString();
        final ConquestPlayer player = new ConquestPlayer(
                playerId,
                username,
                colorHex,
                ConquestPlayerType.HUMAN,
                0,
                0,
                INITIAL_LIVES,
                true,
                true
        );

        synchronized (waiting) {
            final int currentSize = Optional.ofNullable(waiting.getPlayers()).orElseGet(List::of).size();
            if (waiting.getStatus() != ConquestGameStatus.WAITING || currentSize >= 2) {
                quickMatchQueue.removeWaitingSessionId(continentFilter, waitingSessionId);
                throw AppException.conflict(
                        "QUICK_MATCH_EXPIRED",
                        "EÅŸleÅŸme bulunamadÄ±. LÃ¼tfen tekrar deneyin."
                );
            }

            waiting.addPlayer(player);
            waiting.setStatus(ConquestGameStatus.STARTED);

            Optional.ofNullable(waiting.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .filter(Objects::nonNull)
                    .forEach(p -> {
                        p.setReady(true);
                        p.setRemainingLives(INITIAL_LIVES);
                    });

            roundService.pickNextTargetCountry(waiting, null);
            waiting.touch();
        }

        quickMatchQueue.removeWaitingSessionId(continentFilter, waitingSessionId);
        log.info(
                "Quick match paired: sessionId={}, roomCode={}, playerId={}",
                waiting.getSessionId(),
                waiting.getRoomCode(),
                playerId
        );
        return new CreateConquestSessionResponse(waiting.getSessionId(), waiting.getRoomCode(), playerId);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static String normalizeContinentFilter(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "ALL";
        return v;
    }
}
