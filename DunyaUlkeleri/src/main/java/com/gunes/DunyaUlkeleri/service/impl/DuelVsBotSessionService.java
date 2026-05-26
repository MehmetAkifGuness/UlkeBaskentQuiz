package com.gunes.DunyaUlkeleri.service.impl;

import java.util.Optional;
import java.util.UUID;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.CreateDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.CreateDuelSessionResponse;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelVsBotSessionService {

    private static final String BOT_USERNAME = "__BOT__";

    private final DuelSessionCreationService sessionCreationService;
    private final DuelSessionStore sessionStore;
    private final DuelRoundService roundService;
    private final DuelRoundScheduler roundScheduler;

    public CreateDuelSessionResponse createVsBotSession(CreateDuelSessionRequest request) {
        final CreateDuelSessionResponse created = sessionCreationService.createSession(request, false);
        final DuelGameSession session = sessionStore.requireById(created.getSessionId());

        synchronized (session) {
            final int size = Optional.ofNullable(session.getPlayers()).orElseGet(java.util.List::of).size();
            if (session.getStatus() != DuelGameStatus.WAITING || size != 1) {
                return created;
            }

            final String botPlayerId = UUID.randomUUID().toString();
            session.setVsBot(true);
            session.setBotPlayerId(botPlayerId);
            session.setBotDifficulty(request == null ? null : request.getBotDifficulty());
            session.addPlayer(new DuelPlayer(botPlayerId, BOT_USERNAME, 0, true));
            session.setStatus(DuelGameStatus.STARTED);
            roundService.startFirstRound(session);
            roundScheduler.reschedule(session);
            session.touch();
        }

        sessionStore.save(session);
        return created;
    }
}
