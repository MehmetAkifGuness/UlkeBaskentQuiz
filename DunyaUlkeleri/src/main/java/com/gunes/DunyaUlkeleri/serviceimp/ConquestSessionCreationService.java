package com.gunes.DunyaUlkeleri.serviceimp;

import java.time.Instant;
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
import com.gunes.DunyaUlkeleri.repository.ConquestPlayableCountryRepository;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestSessionCreationService {

    private static final Logger log = LoggerFactory.getLogger(ConquestSessionCreationService.class);
    private static final int INITIAL_LIVES = 3;

    private final ConquestSessionStore sessionStore;
    private final ConquestRoomCodeAllocator roomCodeAllocator;
    private final ConquestPlayableCountryRepository playableCountryRepository;

    public CreateConquestSessionResponse createSession(
            CreateConquestSessionRequest request,
            boolean quickMatch
    ) {
        final String username = safeTrim(request == null ? null : request.getUsername());
        final String colorHex = safeTrim(request == null ? null : request.getColorHex());
        final String continentFilter = normalizeContinentFilter(
                request == null ? null : request.getContinentFilter()
        );

        if (username == null || username.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "KullanÄ±cÄ± adÄ± boÅŸ olamaz.");
        }
        if (colorHex == null || colorHex.isBlank()) {
            throw AppException.badRequest("COLOR_REQUIRED", "Renk bilgisi (colorHex) boÅŸ olamaz.");
        }
        if (continentFilter == null || continentFilter.isBlank()) {
            throw AppException.badRequest("CONTINENT_REQUIRED", "KÄ±ta filtresi boÅŸ olamaz.");
        }

        final String sessionId = UUID.randomUUID().toString();
        final String roomCode = roomCodeAllocator.allocateUniqueRoomCode();
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

        session.setPlayableIsoCodes(playableCountryRepository.resolvePlayableIsoCodes(continentFilter));
        session.addPlayer(player);

        sessionStore.save(session);

        log.info(
                "Conquest session created: sessionId={}, roomCode={}, playerId={}, quickMatch={}",
                sessionId,
                roomCode,
                playerId,
                quickMatch
        );

        return new CreateConquestSessionResponse(sessionId, roomCode, playerId);
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
