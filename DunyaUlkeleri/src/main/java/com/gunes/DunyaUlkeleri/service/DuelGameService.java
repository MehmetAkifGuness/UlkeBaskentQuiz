package com.gunes.DunyaUlkeleri.service;

import com.gunes.DunyaUlkeleri.dto.request.CreateDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.JoinDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.LeaveDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.SubmitDuelAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.CreateDuelSessionResponse;
import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.dto.response.JoinDuelSessionResponse;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;

public interface DuelGameService {
    CreateDuelSessionResponse createSession(CreateDuelSessionRequest request);

    CreateDuelSessionResponse quickMatch(CreateDuelSessionRequest request);

    JoinDuelSessionResponse joinSession(String roomCode, JoinDuelSessionRequest request);

    DuelSessionStateDto submitAnswer(SubmitDuelAnswerRequest request);

    DuelSessionStateDto leaveSession(LeaveDuelSessionRequest request);

    DuelSessionStateDto getSessionState(String sessionId);

    DuelGameSession findSessionById(String sessionId);

    DuelGameSession findSessionByRoomCode(String roomCode);

    void handleDisconnect(String sessionId, String playerId);
}

