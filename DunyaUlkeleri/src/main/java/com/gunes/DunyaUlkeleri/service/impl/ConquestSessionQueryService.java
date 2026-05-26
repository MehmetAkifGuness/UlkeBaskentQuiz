package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.mapper.ConquestSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestSessionQueryService {

    private final ConquestSessionStore sessionStore;
    private final ConquestSessionStateMapper stateMapper;

    public ConquestSessionStateDto getSessionState(String sessionId) {
        final ConquestGameSession session = sessionStore.requireById(sessionId);
        synchronized (session) {
            return stateMapper.toStateDto(
                    session,
                    null,
                    null,
                    session.getCurrentRound() != null && session.getCurrentRound().isLocked()
            );
        }
    }

    public ConquestGameSession findSessionById(String sessionId) {
        return sessionStore.requireById(sessionId);
    }

    public ConquestGameSession findSessionByRoomCode(String roomCode) {
        return sessionStore.requireByRoomCode(roomCode);
    }
}

