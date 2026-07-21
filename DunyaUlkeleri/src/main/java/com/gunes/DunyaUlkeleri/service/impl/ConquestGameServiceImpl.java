package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.CreateConquestSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.JoinConquestSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.SetConquestReadyRequest;
import com.gunes.DunyaUlkeleri.dto.request.StartConquestGameRequest;
import com.gunes.DunyaUlkeleri.dto.request.SubmitConquestAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.dto.response.CreateConquestSessionResponse;
import com.gunes.DunyaUlkeleri.dto.response.JoinConquestSessionResponse;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.service.ConquestGameService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestGameServiceImpl implements ConquestGameService {

    private final ConquestSessionCreationService sessionCreationService;
    private final ConquestQuickMatchService quickMatchService;
    private final ConquestJoinService joinService;
    private final ConquestStartGameService startGameService;
    private final ConquestPauseService pauseService;
    private final ConquestPlayerPresenceService playerPresenceService;
    private final ConquestSessionQueryService sessionQueryService;
    private final ConquestAnswerService answerService;

    @Override
    public CreateConquestSessionResponse createSession(CreateConquestSessionRequest request) {
        return sessionCreationService.createSession(request, false);
    }

    @Override
    public CreateConquestSessionResponse quickMatch(CreateConquestSessionRequest request) {
        return quickMatchService.quickMatch(request);
    }

    @Override
    public JoinConquestSessionResponse joinSession(String roomCode, JoinConquestSessionRequest request) {
        return joinService.joinSession(roomCode, request);
    }

    @Override
    public ConquestSessionStateDto startGame(StartConquestGameRequest request) {
        return startGameService.startGame(request);
    }

    @Override
    public ConquestSessionStateDto pauseGame(StartConquestGameRequest request) {
        return pauseService.pauseGame(request);
    }

    @Override
    public ConquestSessionStateDto resumeGame(StartConquestGameRequest request) {
        return pauseService.resumeGame(request);
    }

    @Override
    public ConquestSessionStateDto setReady(SetConquestReadyRequest request) {
        return playerPresenceService.setReady(request);
    }

    @Override
    public ConquestSessionStateDto leaveSession(StartConquestGameRequest request) {
        return playerPresenceService.leaveSession(request);
    }

    @Override
    public ConquestSessionStateDto submitAnswer(SubmitConquestAnswerRequest request) {
        return answerService.submitAnswer(request);
    }

    @Override
    public ConquestSessionStateDto getSessionState(String sessionId) {
        return sessionQueryService.getSessionState(sessionId);
    }

    @Override
    public ConquestGameSession findSessionById(String sessionId) {
        return sessionQueryService.findSessionById(sessionId);
    }

    @Override
    public ConquestGameSession findSessionByRoomCode(String roomCode) {
        return sessionQueryService.findSessionByRoomCode(roomCode);
    }

    @Override
    public void handleDisconnect(String sessionId, String playerId) {
        playerPresenceService.handleDisconnect(sessionId, playerId);
    }
}
