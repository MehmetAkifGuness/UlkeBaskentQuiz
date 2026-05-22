package com.gunes.DunyaUlkeleri.serviceimp;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.CreateDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.JoinDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.LeaveDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.SubmitDuelAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.CreateDuelSessionResponse;
import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.dto.response.JoinDuelSessionResponse;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.service.DuelGameService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelGameServiceImpl implements DuelGameService {

    private final DuelSessionCreationService sessionCreationService;
    private final DuelQuickMatchService quickMatchService;
    private final DuelJoinService joinService;
    private final DuelAnswerService answerService;
    private final DuelPlayerPresenceService presenceService;
    private final DuelSessionQueryService queryService;

    @Override
    public CreateDuelSessionResponse createSession(CreateDuelSessionRequest request) {
        return sessionCreationService.createSession(request, false);
    }

    @Override
    public CreateDuelSessionResponse quickMatch(CreateDuelSessionRequest request) {
        return quickMatchService.quickMatch(request);
    }

    @Override
    public JoinDuelSessionResponse joinSession(String roomCode, JoinDuelSessionRequest request) {
        return joinService.joinSession(roomCode, request);
    }

    @Override
    public DuelSessionStateDto submitAnswer(SubmitDuelAnswerRequest request) {
        return answerService.submitAnswer(request);
    }

    @Override
    public DuelSessionStateDto leaveSession(LeaveDuelSessionRequest request) {
        return presenceService.leaveSession(request);
    }

    @Override
    public DuelSessionStateDto getSessionState(String sessionId) {
        return queryService.getSessionState(sessionId);
    }

    @Override
    public DuelGameSession findSessionById(String sessionId) {
        return queryService.findSessionById(sessionId);
    }

    @Override
    public DuelGameSession findSessionByRoomCode(String roomCode) {
        return queryService.findSessionByRoomCode(roomCode);
    }

    @Override
    public void handleDisconnect(String sessionId, String playerId) {
        presenceService.handleDisconnect(sessionId, playerId);
    }
}

