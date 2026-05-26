package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.mapper.DuelSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelSessionQueryService {

    private final DuelSessionStore sessionStore;
    private final DuelSessionStateMapper stateMapper;

    public DuelSessionStateDto getSessionState(String sessionId) {
        DuelGameSession session = sessionStore.requireById(sessionId);
        return stateMapper.toStateDto(session, null);
    }

    public DuelGameSession findSessionById(String sessionId) {
        return sessionStore.requireById(sessionId);
    }

    public DuelGameSession findSessionByRoomCode(String roomCode) {
        return sessionStore.requireByRoomCode(roomCode);
    }
}

