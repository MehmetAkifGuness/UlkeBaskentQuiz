package com.gunes.DunyaUlkeleri.conquest.service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.conquest.dto.ConquestPlayerDto;
import com.gunes.DunyaUlkeleri.conquest.dto.ConquestRoundDto;
import com.gunes.DunyaUlkeleri.conquest.dto.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.conquest.dto.CreateConquestSessionRequest;
import com.gunes.DunyaUlkeleri.conquest.dto.CreateConquestSessionResponse;
import com.gunes.DunyaUlkeleri.conquest.dto.JoinConquestSessionRequest;
import com.gunes.DunyaUlkeleri.conquest.dto.JoinConquestSessionResponse;
import com.gunes.DunyaUlkeleri.conquest.dto.SetConquestReadyRequest;
import com.gunes.DunyaUlkeleri.conquest.dto.StartConquestGameRequest;
import com.gunes.DunyaUlkeleri.conquest.dto.SubmitConquestAnswerRequest;
import com.gunes.DunyaUlkeleri.conquest.model.ConquestGameSession;
import com.gunes.DunyaUlkeleri.conquest.model.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.conquest.model.ConquestPlayer;
import com.gunes.DunyaUlkeleri.conquest.model.ConquestPlayerType;
import com.gunes.DunyaUlkeleri.conquest.model.ConquestRound;
import com.gunes.DunyaUlkeleri.exception.AppException;

@Service
public class ConquestGameService {

    private static final Logger log = LoggerFactory.getLogger(ConquestGameService.class);
    private static final int INITIAL_LIVES = 3;

    // Şimdilik in-memory.
    // TODO: Session state Redis veya database üzerinde tutulacak.
    // TODO: Botlar backend tarafında sanal oyuncu olarak GameSession'a eklenecek.
    // TODO: Matchmaking/lobi sistemi geliştirilecek.
    // TODO: Skorlar kalıcı olarak kaydedilecek.
    private final Map<String, ConquestGameSession> sessionsById = new ConcurrentHashMap<>();
    private final Map<String, String> roomCodeToSessionId = new ConcurrentHashMap<>();

    private final Object quickMatchLock = new Object();
    private final Map<String, String> quickMatchWaitingByContinent = new ConcurrentHashMap<>();

    private final SecureRandom random = new SecureRandom();

    private static final List<PlayableCountry> FALLBACK_PLAYABLE_COUNTRIES = List.of(
            new PlayableCountry("TR", "Türkiye", "Europe"),
            new PlayableCountry("DE", "Germany", "Europe"),
            new PlayableCountry("FR", "France", "Europe"),
            new PlayableCountry("US", "United States", "North America"),
            new PlayableCountry("BR", "Brazil", "South America"),
            new PlayableCountry("JP", "Japan", "Asia"),
            new PlayableCountry("CN", "China", "Asia"),
            new PlayableCountry("EG", "Egypt", "Africa"),
            new PlayableCountry("ZA", "South Africa", "Africa"),
            new PlayableCountry("AU", "Australia", "Oceania")
    );

    public CreateConquestSessionResponse createSession(CreateConquestSessionRequest request) {
        return createSessionInternal(request, false);
    }

    public CreateConquestSessionResponse quickMatch(CreateConquestSessionRequest request) {
        final String continentFilter = normalizeContinentFilter(request == null ? null : request.getContinentFilter());
        if (continentFilter == null || continentFilter.isBlank()) {
            throw AppException.badRequest("CONTINENT_REQUIRED", "Kıta filtresi boş olamaz.");
        }

        synchronized (quickMatchLock) {
            final String waitingSessionId = quickMatchWaitingByContinent.get(continentFilter);
            if (waitingSessionId != null) {
                final ConquestGameSession waiting = sessionsById.get(waitingSessionId);
                if (waiting == null
                        || waiting.getStatus() != ConquestGameStatus.WAITING
                        || !waiting.isQuickMatch()
                        || waiting.getPlayers() == null
                        || waiting.getPlayers().size() != 1) {
                    quickMatchWaitingByContinent.remove(continentFilter, waitingSessionId);
                } else {
                    final String username = safeTrim(request == null ? null : request.getUsername());
                    final String colorHex = safeTrim(request == null ? null : request.getColorHex());
                    if (username == null || username.isBlank()) {
                        throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
                    }
                    if (colorHex == null || colorHex.isBlank()) {
                        throw AppException.badRequest("COLOR_REQUIRED", "Renk bilgisi (colorHex) boş olamaz.");
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
                        if (waiting.getStatus() != ConquestGameStatus.WAITING || waiting.getPlayers().size() >= 2) {
                            quickMatchWaitingByContinent.remove(continentFilter, waitingSessionId);
                            throw AppException.conflict("QUICK_MATCH_EXPIRED", "Eşleşme bulunamadı. Lütfen tekrar deneyin.");
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

                        pickNextTargetCountry(waiting, null);
                        waiting.touch();
                    }

                    quickMatchWaitingByContinent.remove(continentFilter, waitingSessionId);

                    log.info("Quick match paired: sessionId={}, roomCode={}, playerId={}", waiting.getSessionId(), waiting.getRoomCode(), playerId);
                    return new CreateConquestSessionResponse(waiting.getSessionId(), waiting.getRoomCode(), playerId);
                }
            }

            final CreateConquestSessionResponse created = createSessionInternal(request, true);
            quickMatchWaitingByContinent.put(continentFilter, created.getSessionId());
            log.info("Quick match enqueued: sessionId={}, roomCode={}, playerId={}", created.getSessionId(), created.getRoomCode(), created.getPlayerId());
            return created;
        }
    }

    private CreateConquestSessionResponse createSessionInternal(
            CreateConquestSessionRequest request,
            boolean quickMatch
    ) {
        final String username = safeTrim(request == null ? null : request.getUsername());
        final String colorHex = safeTrim(request == null ? null : request.getColorHex());
        final String continentFilter = normalizeContinentFilter(request == null ? null : request.getContinentFilter());

        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }
        if (colorHex == null || colorHex.isBlank()) {
            throw AppException.badRequest("COLOR_REQUIRED", "Renk bilgisi (colorHex) boş olamaz.");
        }
        if (continentFilter == null || continentFilter.isBlank()) {
            throw AppException.badRequest("CONTINENT_REQUIRED", "Kıta filtresi boş olamaz.");
        }

        final String sessionId = UUID.randomUUID().toString();
        String roomCode = null;
        for (int attempt = 0; attempt < 20; attempt++) {
            final String candidate = generateRoomCode();
            if (!roomCodeToSessionId.containsKey(candidate)) {
                roomCode = candidate;
                break;
            }
        }
        if (roomCode == null) {
            throw new AppException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "ROOM_CODE_GENERATION_FAILED",
                    "Oda kodu üretilemedi. Lütfen tekrar deneyin."
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
                quickMatch
        );

        final ConquestGameSession session = new ConquestGameSession();
        session.setSessionId(sessionId);
        session.setRoomCode(roomCode);
        session.setStatus(ConquestGameStatus.WAITING);
        session.setSelectedContinentFilter(continentFilter);
        session.setHostPlayerId(playerId);
        session.setQuickMatch(quickMatch);
        session.setCreatedAt(Instant.now());
        session.setUpdatedAt(session.getCreatedAt());

        // TODO: Gerçek ülke verisi CountryService üzerinden alınacak.
        session.setPlayableIsoCodes(resolvePlayableIsoCodes(continentFilter));

        session.addPlayer(player);

        sessionsById.put(sessionId, session);
        roomCodeToSessionId.put(roomCode, sessionId);

        log.info(
                "Conquest session created: sessionId={}, roomCode={}, playerId={}, quickMatch={}",
                sessionId,
                roomCode,
                playerId,
                quickMatch
        );

        return new CreateConquestSessionResponse(sessionId, roomCode, playerId);
    }

    public JoinConquestSessionResponse joinSession(String roomCode, JoinConquestSessionRequest request) {
        final String normalizedRoomCode = safeTrim(roomCode);
        if (normalizedRoomCode == null || normalizedRoomCode.isBlank()) {
            throw AppException.badRequest("ROOM_CODE_REQUIRED", "Oda kodu boş olamaz.");
        }

        final ConquestGameSession session = findSessionByRoomCode(normalizedRoomCode);
        final String username = safeTrim(request == null ? null : request.getUsername());
        final String colorHex = safeTrim(request == null ? null : request.getColorHex());

        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }
        if (colorHex == null || colorHex.isBlank()) {
            throw AppException.badRequest("COLOR_REQUIRED", "Renk bilgisi (colorHex) boş olamaz.");
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
                false
        );

        synchronized (session) {
            if (session.getStatus() == ConquestGameStatus.FINISHED) {
                throw AppException.conflict("ROOM_FINISHED", "Oda kapandı. Lütfen yeni bir oda oluşturun.");
            }
            final int currentSize = Optional.ofNullable(session.getPlayers()).orElseGet(List::of).size();
            if (currentSize >= 2) {
                throw AppException.conflict("ROOM_FULL", "Oda dolu.");
            }
            session.addPlayer(player);
            session.touch();
        }

        log.info("Player joined: sessionId={}, roomCode={}, playerId={}, username={}", session.getSessionId(), session.getRoomCode(), playerId, username);

        return new JoinConquestSessionResponse(session.getSessionId(), session.getRoomCode(), playerId);
    }

    public ConquestSessionStateDto startGame(StartConquestGameRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        if (playerId == null || playerId.isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }

        final ConquestGameSession session = findSessionById(sessionId);

        synchronized (session) {
            if (session.getStatus() == ConquestGameStatus.FINISHED) {
                return toStateDto(session, "Oyun zaten bitti.", null, true);
            }
            if (!session.canStart() && session.getStatus() != ConquestGameStatus.STARTED) {
                throw AppException.conflict("GAME_NOT_STARTABLE", "Rakip bekleniyor. Oyun başlatmak için en az 2 oyuncu gerekli.");
            }

            if (playerId != null && session.getPlayer(playerId) == null) {
                throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadı.");
            }

            final String hostId = safeTrim(session.getHostPlayerId());
            if (hostId != null && !hostId.isBlank() && !hostId.equals(playerId)) {
                throw AppException.forbidden("HOST_ONLY", "Sadece oda sahibi oyunu başlatabilir.");
            }

            final boolean allReady = Optional.ofNullable(session.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .filter(Objects::nonNull)
                    .allMatch(ConquestPlayer::isReady);
            if (!session.isQuickMatch() && !allReady) {
                throw AppException.conflict("PLAYERS_NOT_READY", "Oyunu başlatmak için tüm oyuncular hazır olmalı.");
            }

            if (session.getStatus() != ConquestGameStatus.STARTED) {
                session.setStatus(ConquestGameStatus.STARTED);

                // Yeni maç başlangıcı: herkes 3 can ile başlar.
                Optional.ofNullable(session.getPlayers())
                        .orElseGet(List::of)
                        .stream()
                        .filter(Objects::nonNull)
                        .forEach(p -> p.setRemainingLives(INITIAL_LIVES));

                pickNextTargetCountry(session, null);
                session.touch();
                log.info("Game started: sessionId={}, roomCode={}", session.getSessionId(), session.getRoomCode());
            }

            return toStateDto(session, "Oyun başladı.", null, session.getCurrentRound() != null && session.getCurrentRound().isLocked());
        }
    }

    public ConquestSessionStateDto setReady(SetConquestReadyRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        final boolean ready = request != null && request.isReady();

        if (playerId == null || playerId.isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }

        final ConquestGameSession session = findSessionById(sessionId);
        synchronized (session) {
            final ConquestPlayer player = session.getPlayer(playerId);
            if (player == null) {
                throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadı.");
            }
            player.setReady(ready);
            session.touch();
            return toStateDto(session, ready ? "Hazırım." : "Bekliyorum.", null, false);
        }
    }

    public ConquestSessionStateDto leaveSession(StartConquestGameRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        if (playerId == null || playerId.isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }

        final ConquestGameSession session = findSessionById(sessionId);
        synchronized (session) {
            session.removePlayer(playerId);

            if (session.getPlayers() == null || session.getPlayers().isEmpty()) {
                sessionsById.remove(session.getSessionId());
                if (session.getRoomCode() != null) {
                    roomCodeToSessionId.remove(session.getRoomCode().toUpperCase(Locale.ROOT));
                }
                if (session.isQuickMatch()) {
                    quickMatchWaitingByContinent.remove(
                            normalizeContinentFilter(session.getSelectedContinentFilter()),
                            session.getSessionId()
                    );
                }
                log.info("Session removed (empty): sessionId={}, roomCode={}", session.getSessionId(), session.getRoomCode());
                return null;
            }

            if (session.getStatus() == ConquestGameStatus.STARTED) {
                session.setStatus(ConquestGameStatus.FINISHED);
            }

            Optional.ofNullable(session.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .filter(Objects::nonNull)
                    .forEach(p -> p.setReady(false));

            session.touch();
            return toStateDto(session, "Oyuncu ayrıldı.", null, false);
        }
    }

    public ConquestSessionStateDto submitAnswer(SubmitConquestAnswerRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        final String selectedIsoCode = safeTrim(request == null ? null : request.getSelectedIsoCode());

        final ConquestGameSession session = findSessionById(sessionId);

        synchronized (session) {
            if (session.getStatus() == ConquestGameStatus.FINISHED) {
                final String winnerId = session.getCurrentRound() == null
                        ? null
                        : session.getCurrentRound().getWinnerPlayerId();
                return toStateDto(session, "Oyun bitti.", winnerId, true);
            }
            if (session.getStatus() != ConquestGameStatus.STARTED) {
                return toStateDto(session, "Oyun henüz başlamadı.", null, true);
            }

            final ConquestRound round = session.getCurrentRound();
            if (round == null) {
                pickNextTargetCountry(session, null);
                return toStateDto(session, null, null, false);
            }

            if (round.isLocked()) {
                // Round kilitliyse sonraki cevaplar yok sayılır.
                return toStateDto(session, null, round.getWinnerPlayerId(), true);
            }

            final ConquestPlayer player = session.getPlayer(playerId);
            if (player == null) {
                throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadı.");
            }

            if (player.getRemainingLives() <= 0) {
                if (areAllPlayersOutOfLives(session)) {
                    pickNextTargetCountry(session, null);
                    return toStateDto(session, "İki tarafın da canı bitti. Ülke atlandı.", null, false);
                }
                return toStateDto(session, "Bu tur için canın bitti.", null, false);
            }

            if (selectedIsoCode == null || selectedIsoCode.isBlank()) {
                throw AppException.badRequest("ISO_REQUIRED", "Ülke kodu (ISO) boş olamaz.");
            }

            final String normalizedSelectedIso = selectedIsoCode.trim().toUpperCase(Locale.ROOT);
            final String normalizedTargetIso = safeTrim(round.getTargetIsoCode());

            if (normalizedTargetIso != null && normalizedTargetIso.equalsIgnoreCase(normalizedSelectedIso)) {
                // İlk doğru cevap kazandırır.
                finishRound(session, player, round);
                session.touch();

                if (session.isFinished()) {
                    session.setStatus(ConquestGameStatus.FINISHED);
                    log.info("Game finished: sessionId={}, roomCode={}", session.getSessionId(), session.getRoomCode());
                    return toStateDto(session, "Tebrikler! Tüm ülkeler fethedildi.", player.getPlayerId(), true);
                }

                pickNextTargetCountry(session, player.getPlayerId());
                return toStateDto(session, "Round kazanıldı.", player.getPlayerId(), false);
            }

            // Yanlış cevap: 1 can azalt.
            player.setRemainingLives(Math.max(0, player.getRemainingLives() - 1));
            session.touch();

            log.info("Wrong answer: sessionId={}, playerId={}, selectedIso={}, remainingLives={}",
                    session.getSessionId(),
                    playerId,
                    normalizedSelectedIso,
                    player.getRemainingLives());

            if (areAllPlayersOutOfLives(session)) {
                pickNextTargetCountry(session, null);
                return toStateDto(session, "İki tarafın da canı bitti. Ülke atlandı.", null, false);
            }

            return toStateDto(session, "Yanlış cevap (-1 can).", null, false);
        }
    }

    public ConquestSessionStateDto getSessionState(String sessionId) {
        final ConquestGameSession session = findSessionById(sessionId);
        synchronized (session) {
            return toStateDto(session, null, null, session.getCurrentRound() != null && session.getCurrentRound().isLocked());
        }
    }

    public ConquestGameSession findSessionById(String sessionId) {
        final String normalizedId = safeTrim(sessionId);
        if (normalizedId == null || normalizedId.isBlank()) {
            throw AppException.badRequest("SESSION_ID_REQUIRED", "SessionId boş olamaz.");
        }
        final ConquestGameSession session = sessionsById.get(normalizedId);
        if (session == null) {
            throw AppException.notFound("SESSION_NOT_FOUND", "Session bulunamadı: " + normalizedId);
        }
        return session;
    }

    public ConquestGameSession findSessionByRoomCode(String roomCode) {
        final String normalizedRoomCode = safeTrim(roomCode);
        if (normalizedRoomCode == null || normalizedRoomCode.isBlank()) {
            throw AppException.badRequest("ROOM_CODE_REQUIRED", "Oda kodu boş olamaz.");
        }
        final String sessionId = roomCodeToSessionId.get(normalizedRoomCode.toUpperCase(Locale.ROOT));
        if (sessionId == null) {
            throw AppException.notFound("ROOM_NOT_FOUND", "Oda bulunamadı.");
        }
        return findSessionById(sessionId);
    }

    public void handleDisconnect(String sessionId, String playerId) {
        // TODO: Kullanıcı kimliği JWT/auth sistemiyle bağlanacak.
        if (sessionId == null || playerId == null) return;
        try {
            final ConquestGameSession session = findSessionById(sessionId);
            synchronized (session) {
                final ConquestPlayer player = session.getPlayer(playerId);
                if (player != null) {
                    player.setConnected(false);
                    session.touch();
                    log.info("Player disconnected: sessionId={}, playerId={}", session.getSessionId(), playerId);
                }
            }
        } catch (Exception ignored) {
            // Session yoksa ignore.
        }
    }

    // ------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------

    private String generateRoomCode() {
        // 6 karakterli büyük harf/rakam
        final String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        for (int attempt = 0; attempt < 20; attempt++) {
            final StringBuilder sb = new StringBuilder(6);
            for (int i = 0; i < 6; i++) {
                sb.append(alphabet.charAt(random.nextInt(alphabet.length())));
            }
            final String candidate = sb.toString();
            if (!roomCodeToSessionId.containsKey(candidate)) {
                return candidate;
            }
        }
        // Çok düşük ihtimal, ama garanti olsun.
        return UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase(Locale.ROOT);
    }

    private List<String> resolvePlayableIsoCodes(String continentFilter) {
        final List<PlayableCountry> filtered = filterPlayableCountries(continentFilter);
        return filtered.stream().map(c -> c.isoCode).distinct().collect(Collectors.toCollection(ArrayList::new));
    }

    private List<PlayableCountry> filterPlayableCountries(String continentFilter) {
        final String filter = normalizeContinentFilter(continentFilter);
        if ("ALL".equals(filter)) {
            return FALLBACK_PLAYABLE_COUNTRIES;
        }
        return FALLBACK_PLAYABLE_COUNTRIES.stream()
                .filter(c -> filter.equalsIgnoreCase(c.continent))
                .toList();
    }

    private boolean areAllPlayersOutOfLives(ConquestGameSession session) {
        final List<ConquestPlayer> players = Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .toList();
        if (players.isEmpty()) return false;
        return players.stream().allMatch(p -> p.getRemainingLives() <= 0);
    }

    private void pickNextTargetCountry(ConquestGameSession session, String lastWinnerPlayerId) {
        final List<String> remaining = session.getPlayableIsoCodes().stream()
                .filter(Objects::nonNull)
                .map(v -> v.trim().toUpperCase(Locale.ROOT))
                .filter(v -> !session.isCountryConquered(v))
                .distinct()
                .sorted(Comparator.naturalOrder())
                .collect(Collectors.toCollection(ArrayList::new));

        if (remaining.isEmpty()) {
            session.setStatus(ConquestGameStatus.FINISHED);
            session.setCurrentRound(null);
            session.touch();
            return;
        }

        Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .forEach(p -> p.setRemainingLives(INITIAL_LIVES));

        final String nextIso = remaining.get(random.nextInt(remaining.size()));
        final PlayableCountry meta = FALLBACK_PLAYABLE_COUNTRIES.stream()
                .filter(c -> c.isoCode.equalsIgnoreCase(nextIso))
                .findFirst()
                .orElse(new PlayableCountry(nextIso, nextIso, session.getSelectedContinentFilter()));

        final int nextRoundNumber = Optional.ofNullable(session.getCurrentRound())
                .map(ConquestRound::getRoundNumber)
                .orElse(0) + 1;

        final ConquestRound round = new ConquestRound();
        round.setRoundNumber(nextRoundNumber);
        round.setTargetIsoCode(meta.isoCode);
        round.setTargetCountryName(meta.name);
        round.setLocked(false);
        round.setWinnerPlayerId(null);
        round.setStartedAt(Instant.now());
        round.setFinishedAt(null);

        session.setCurrentRound(round);
        session.setUpdatedAt(Instant.now());

        log.info("Next round picked: sessionId={}, round={}, target={}", session.getSessionId(), nextRoundNumber, meta.isoCode);
    }

    private void finishRound(ConquestGameSession session, ConquestPlayer winner, ConquestRound round) {
        if (round == null || winner == null) return;
        round.setLocked(true);
        round.setWinnerPlayerId(winner.getPlayerId());
        round.setFinishedAt(Instant.now());

        // Score güncelle
        winner.setScore(winner.getScore() + 1);
        winner.setConqueredCount(winner.getConqueredCount() + 1);

        // Ülkeyi fethet
        session.markCountryConquered(round.getTargetIsoCode(), winner);

        log.info("Round won: sessionId={}, round={}, winnerPlayerId={}, iso={}",
                session.getSessionId(),
                round.getRoundNumber(),
                winner.getPlayerId(),
                round.getTargetIsoCode());
    }

    private ConquestSessionStateDto toStateDto(
            ConquestGameSession session,
            String lastEventMessage,
            String lastWinnerPlayerId,
            boolean roundLocked
    ) {
        final List<ConquestPlayerDto> players = Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .map(p -> new ConquestPlayerDto(
                        p.getPlayerId(),
                        p.getUsername(),
                        p.getColorHex(),
                        p.getType() == null ? null : p.getType().name(),
                        p.getScore(),
                        p.getConqueredCount(),
                        p.getRemainingLives(),
                        p.isConnected(),
                        p.isReady()
                ))
                .toList();

        final ConquestRoundDto roundDto = session.getCurrentRound() == null
                ? null
                : new ConquestRoundDto(
                        session.getCurrentRound().getRoundNumber(),
                        session.getCurrentRound().getTargetIsoCode(),
                        session.getCurrentRound().getTargetCountryName(),
                        session.getCurrentRound().isLocked(),
                        session.getCurrentRound().getWinnerPlayerId(),
                        session.getCurrentRound().getStartedAt(),
                        session.getCurrentRound().getFinishedAt()
                );

        return new ConquestSessionStateDto(
                session.getSessionId(),
                session.getRoomCode(),
                session.getStatus() == null ? null : session.getStatus().name(),
                session.getSelectedContinentFilter(),
                session.getHostPlayerId(),
                session.isQuickMatch(),
                players,
                session.getConqueredCountryColors(),
                roundDto,
                session.getPlayableIsoCodes(),
                lastEventMessage,
                lastWinnerPlayerId,
                roundLocked
        );
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static String normalizeContinentFilter(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "ALL";
        // API tarafında standart: ALL / Europe / Asia / Africa / North America / South America / Oceania
        return v;
    }

    private static final class PlayableCountry {
        private final String isoCode;
        private final String name;
        private final String continent;

        private PlayableCountry(String isoCode, String name, String continent) {
            this.isoCode = safeTrim(isoCode) == null ? null : isoCode.trim().toUpperCase(Locale.ROOT);
            this.name = safeTrim(name);
            this.continent = safeTrim(continent);
        }
    }
}
