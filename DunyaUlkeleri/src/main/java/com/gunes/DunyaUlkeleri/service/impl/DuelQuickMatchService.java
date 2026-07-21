package com.gunes.DunyaUlkeleri.service.impl;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gunes.DunyaUlkeleri.dto.request.CreateDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.CreateDuelSessionResponse;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.DuelQuickMatchQueue;
import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
import com.gunes.DunyaUlkeleri.util.league.LeagueTier;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelQuickMatchService {

    private static final Logger log = LoggerFactory.getLogger(DuelQuickMatchService.class);

    private final DuelSessionStore sessionStore;
    private final DuelQuickMatchQueue quickMatchQueue;
    private final DuelRoundService roundService;
    private final DuelRoundScheduler roundScheduler;
    private final DuelSessionCreationService sessionCreationService;
    private final UserRepository userRepository;
    private final LeagueService leagueService;

    @Transactional
    public CreateDuelSessionResponse quickMatch(CreateDuelSessionRequest request) {
        final String username = safeTrim(request == null ? null : request.getUsername());
        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }

        final String category = normalizeCategory(request == null ? null : request.getCategory());
        final String mode = normalizeMode(request == null ? null : request.getMode());

        final String matchmakingKey = buildMatchmakingKey(category, mode, username);

        return quickMatchQueue.withLock(
                matchmakingKey,
                () -> quickMatchWithinLock(matchmakingKey, request)
        );
    }

    private CreateDuelSessionResponse quickMatchWithinLock(String matchmakingKey, CreateDuelSessionRequest request) {
        final String waitingSessionId = quickMatchQueue.getWaitingSessionId(matchmakingKey);
        final DuelGameSession waiting = waitingSessionId == null ? null : getWaitingSessionIfValid(matchmakingKey, waitingSessionId);

        if (waiting != null) {
            return pairIntoWaitingSession(matchmakingKey, waitingSessionId, waiting, request);
        }

        final CreateDuelSessionResponse created = sessionCreationService.createSession(request, true);
        applyMatchmakingKey(created.getSessionId(), matchmakingKey);
        quickMatchQueue.putWaitingSessionId(matchmakingKey, created.getSessionId());

        log.info(
                "Duel quick-match enqueued: sessionId={}, roomCode={}, playerId={}",
                created.getSessionId(),
                created.getRoomCode(),
                created.getPlayerId()
        );
        return created;
    }

    private DuelGameSession getWaitingSessionIfValid(String matchmakingKey, String waitingSessionId) {
        final DuelGameSession waiting;
        try {
            waiting = sessionStore.requireById(waitingSessionId);
        } catch (Exception e) {
            quickMatchQueue.removeWaitingSessionId(matchmakingKey, waitingSessionId);
            return null;
        }

        final int size = Optional.ofNullable(waiting.getPlayers()).orElseGet(List::of).size();
        final boolean valid = waiting.getStatus() == DuelGameStatus.WAITING
                && waiting.isQuickMatch()
                && size == 1;
        if (!valid) {
            quickMatchQueue.removeWaitingSessionId(matchmakingKey, waitingSessionId);
            return null;
        }
        return waiting;
    }

    private CreateDuelSessionResponse pairIntoWaitingSession(
            String matchmakingKey,
            String waitingSessionId,
            DuelGameSession waiting,
            CreateDuelSessionRequest request
    ) {
        final String username = safeTrim(request == null ? null : request.getUsername());
        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }

        final String waitingUsername = Optional.ofNullable(waiting.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .map(DuelPlayer::getUsername)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);

        // Same user pressed quick-match again: do not self-pair; return current waiting session info.
        if (waitingUsername != null && waitingUsername.equalsIgnoreCase(username)) {
            return new CreateDuelSessionResponse(waiting.getSessionId(), waiting.getRoomCode(), waiting.getHostPlayerId());
        }

        final String playerId = UUID.randomUUID().toString();
        final DuelPlayer player = new DuelPlayer(playerId, username, 0, true);

        synchronized (waiting) {
            final int currentSize = Optional.ofNullable(waiting.getPlayers()).orElseGet(List::of).size();
            if (waiting.getStatus() != DuelGameStatus.WAITING || currentSize != 1) {
                quickMatchQueue.removeWaitingSessionId(matchmakingKey, waitingSessionId);
                throw AppException.conflict("QUICK_MATCH_EXPIRED", "Eşleşme bulunamadı. Lütfen tekrar deneyin.");
            }

            waiting.addPlayer(player);
            waiting.setStatus(DuelGameStatus.STARTED);
            roundService.startFirstRound(waiting);
            waiting.touch();
            sessionStore.save(waiting);
            roundScheduler.reschedule(waiting);
        }

        quickMatchQueue.removeWaitingSessionId(matchmakingKey, waitingSessionId);
        log.info(
                "Duel quick-match paired: sessionId={}, roomCode={}, playerId={}",
                waiting.getSessionId(),
                waiting.getRoomCode(),
                playerId
        );
        return new CreateDuelSessionResponse(waiting.getSessionId(), waiting.getRoomCode(), playerId);
    }

    private String buildMatchmakingKey(String category, String mode, String username) {
        LeagueTier tier = LeagueTier.BRONZE;
        try {
            Optional<User> userOpt = userRepository.findByUsername(username);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                leagueService.ensureSeason(user);
                tier = leagueService.tierOf(user.getTrophies());
            }
        } catch (Exception ignored) {
            // fallback: BRONZE
        }
        return category + "|" + mode + "|" + tier.name();
    }

    private void applyMatchmakingKey(String sessionId, String matchmakingKey) {
        if (sessionId == null || sessionId.isBlank()) return;
        try {
            DuelGameSession session = sessionStore.requireById(sessionId);
            synchronized (session) {
                session.setMatchmakingKey(matchmakingKey);
                session.touch();
            }
            sessionStore.save(session);
        } catch (Exception ignored) {
            // ignore
        }
    }

    private static String normalizeCategory(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "Dünya";
        return v;
    }

    private static String normalizeMode(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "MIXED";
        return v.trim().toUpperCase();
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}

