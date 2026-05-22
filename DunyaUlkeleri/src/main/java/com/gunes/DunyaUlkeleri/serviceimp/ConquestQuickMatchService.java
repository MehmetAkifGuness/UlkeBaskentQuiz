package com.gunes.DunyaUlkeleri.serviceimp;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gunes.DunyaUlkeleri.dto.request.CreateConquestSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.CreateConquestSessionResponse;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayerType;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.ConquestQuickMatchQueue;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.ConquestRoundService;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.util.league.LeagueTier;
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
    private final UserRepository userRepository;
    private final LeagueService leagueService;

    @Transactional
    public CreateConquestSessionResponse quickMatch(CreateConquestSessionRequest request) {
        final String continentFilter = normalizeContinentFilter(
                request == null ? null : request.getContinentFilter()
        );
        if (continentFilter == null || continentFilter.isBlank()) {
            throw AppException.badRequest("CONTINENT_REQUIRED", "Kıta filtresi boş olamaz.");
        }

        final String username = safeTrim(request == null ? null : request.getUsername());
        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }

        final String matchmakingKey = buildMatchmakingKey(continentFilter, username);

        return quickMatchQueue.withLock(
                matchmakingKey,
                () -> quickMatchWithinLock(matchmakingKey, continentFilter, request)
        );
    }

    private CreateConquestSessionResponse quickMatchWithinLock(
            String matchmakingKey,
            String continentFilter,
            CreateConquestSessionRequest request
    ) {
        final String waitingSessionId = quickMatchQueue.getWaitingSessionId(matchmakingKey);
        final ConquestGameSession waiting = waitingSessionId == null
                ? null
                : getWaitingSessionIfValid(matchmakingKey, waitingSessionId);

        if (waiting != null) {
            return pairIntoWaitingSession(matchmakingKey, continentFilter, waitingSessionId, waiting, request);
        }

        final CreateConquestSessionResponse created = sessionCreationService.createSession(request, true);
        applyMatchmakingKey(created.getSessionId(), matchmakingKey);
        quickMatchQueue.putWaitingSessionId(matchmakingKey, created.getSessionId());
        log.info(
                "Quick match enqueued: sessionId={}, roomCode={}, playerId={}",
                created.getSessionId(),
                created.getRoomCode(),
                created.getPlayerId()
        );
        return created;
    }

    private ConquestGameSession getWaitingSessionIfValid(
            String matchmakingKey,
            String waitingSessionId
    ) {
        final ConquestGameSession waiting;
        try {
            waiting = sessionStore.requireById(waitingSessionId);
        } catch (Exception e) {
            quickMatchQueue.removeWaitingSessionId(matchmakingKey, waitingSessionId);
            return null;
        }

        final int size = Optional.ofNullable(waiting.getPlayers()).orElseGet(List::of).size();
        final boolean valid = waiting.getStatus() == ConquestGameStatus.WAITING
                && waiting.isQuickMatch()
                && size == 1;
        if (!valid) {
            quickMatchQueue.removeWaitingSessionId(matchmakingKey, waitingSessionId);
            return null;
        }

        return waiting;
    }

    private CreateConquestSessionResponse pairIntoWaitingSession(
            String matchmakingKey,
            String continentFilter,
            String waitingSessionId,
            ConquestGameSession waiting,
            CreateConquestSessionRequest request
    ) {
        final String username = safeTrim(request == null ? null : request.getUsername());
        final String colorHex = safeTrim(request == null ? null : request.getColorHex());
        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }
        if (colorHex == null || colorHex.isBlank()) {
            throw AppException.badRequest("COLOR_REQUIRED", "Renk bilgisi (colorHex) boş olamaz.");
        }

        final String waitingUsername = Optional.ofNullable(waiting.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .map(ConquestPlayer::getUsername)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);

        final String waitingColorHex = Optional.ofNullable(waiting.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .map(ConquestPlayer::getColorHex)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);

        // Same user pressed quick-match again: do not self-pair; return current waiting session info.
        if (waitingUsername != null && waitingUsername.equalsIgnoreCase(username)) {
            log.info(
                    "Quick match re-request (same user): sessionId={}, roomCode={}, username={}",
                    waiting.getSessionId(),
                    waiting.getRoomCode(),
                    username
            );
            return new CreateConquestSessionResponse(
                    waiting.getSessionId(),
                    waiting.getRoomCode(),
                    waiting.getHostPlayerId()
            );
        }

        final String normalizedColor = normalizeColorHex(colorHex);
        final String normalizedWaitingColor = normalizeColorHex(waitingColorHex);
        if (!normalizedColor.isBlank()
                && !normalizedWaitingColor.isBlank()
                && normalizedColor.equalsIgnoreCase(normalizedWaitingColor)) {
            throw AppException.conflict(
                    "COLOR_TAKEN",
                    "Bu renk zaten seçildi. Lütfen farklı bir renk seçin."
            );
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
            if (waiting.getStatus() != ConquestGameStatus.WAITING || currentSize != 1) {
                quickMatchQueue.removeWaitingSessionId(matchmakingKey, waitingSessionId);
                throw AppException.conflict(
                        "QUICK_MATCH_EXPIRED",
                        "Eşleşme bulunamadı. Lütfen tekrar deneyin."
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

        quickMatchQueue.removeWaitingSessionId(matchmakingKey, waitingSessionId);
        log.info(
                "Quick match paired: sessionId={}, roomCode={}, playerId={}",
                waiting.getSessionId(),
                waiting.getRoomCode(),
                playerId
        );
        return new CreateConquestSessionResponse(waiting.getSessionId(), waiting.getRoomCode(), playerId);
    }

    private String buildMatchmakingKey(String continentFilter, String username) {
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
        return continentFilter + "|" + tier.name();
    }

    private void applyMatchmakingKey(String sessionId, String matchmakingKey) {
        if (sessionId == null || sessionId.isBlank()) return;
        try {
            ConquestGameSession session = sessionStore.requireById(sessionId);
            synchronized (session) {
                session.setMatchmakingKey(matchmakingKey);
                session.touch();
            }
            sessionStore.save(session);
        } catch (Exception ignored) {
            // ignore
        }
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static String normalizeColorHex(String raw) {
        final String v = safeTrim(raw);
        if (v == null || v.isBlank()) return "";

        String cleaned = v.replace("#", "");
        if (cleaned.startsWith("0x") || cleaned.startsWith("0X")) {
            cleaned = cleaned.substring(2);
        }
        cleaned = cleaned.trim().toUpperCase();

        if (cleaned.length() == 6) {
            cleaned = "FF" + cleaned;
        }

        return cleaned;
    }

    private static String normalizeContinentFilter(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "ALL";
        return v;
    }
}
