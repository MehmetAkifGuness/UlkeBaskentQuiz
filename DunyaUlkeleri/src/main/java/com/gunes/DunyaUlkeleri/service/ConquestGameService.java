package com.gunes.DunyaUlkeleri.service;

import com.gunes.DunyaUlkeleri.dto.request.CreateConquestSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.JoinConquestSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.SetConquestReadyRequest;
import com.gunes.DunyaUlkeleri.dto.request.StartConquestGameRequest;
import com.gunes.DunyaUlkeleri.dto.request.SubmitConquestAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.dto.response.CreateConquestSessionResponse;
import com.gunes.DunyaUlkeleri.dto.response.JoinConquestSessionResponse;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;

public interface ConquestGameService {
    CreateConquestSessionResponse createSession(CreateConquestSessionRequest request);

    CreateConquestSessionResponse quickMatch(CreateConquestSessionRequest request);

    JoinConquestSessionResponse joinSession(String roomCode, JoinConquestSessionRequest request);

    ConquestSessionStateDto startGame(StartConquestGameRequest request);

    ConquestSessionStateDto setReady(SetConquestReadyRequest request);

    ConquestSessionStateDto leaveSession(StartConquestGameRequest request);

    ConquestSessionStateDto submitAnswer(SubmitConquestAnswerRequest request);

    ConquestSessionStateDto getSessionState(String sessionId);

    ConquestGameSession findSessionById(String sessionId);

    ConquestGameSession findSessionByRoomCode(String roomCode);

    void handleDisconnect(String sessionId, String playerId);
}
