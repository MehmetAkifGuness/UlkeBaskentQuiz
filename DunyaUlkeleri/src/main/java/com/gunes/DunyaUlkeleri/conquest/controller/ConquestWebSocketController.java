package com.gunes.DunyaUlkeleri.conquest.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import com.gunes.DunyaUlkeleri.conquest.dto.ConquestErrorDto;
import com.gunes.DunyaUlkeleri.conquest.dto.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.conquest.dto.SetConquestReadyRequest;
import com.gunes.DunyaUlkeleri.conquest.dto.StartConquestGameRequest;
import com.gunes.DunyaUlkeleri.conquest.dto.SubmitConquestAnswerRequest;
import com.gunes.DunyaUlkeleri.conquest.service.ConquestGameService;

import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
public class ConquestWebSocketController {

    private static final Logger log = LoggerFactory.getLogger(ConquestWebSocketController.class);

    private final SimpMessagingTemplate messagingTemplate;
    private final ConquestGameService conquestGameService;

    @MessageMapping("/conquest.start")
    public void startGame(StartConquestGameRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        try {
            ConquestSessionStateDto state = conquestGameService.startGame(request);
            publishState(state);
        } catch (Exception e) {
            log.warn("Conquest start failed: sessionId={}, error={}", sessionId, e.getMessage());
            publishError(sessionId, "START_FAILED", e.getMessage());
        }
    }

    @MessageMapping("/conquest.answer")
    public void submitAnswer(SubmitConquestAnswerRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        try {
            ConquestSessionStateDto state = conquestGameService.submitAnswer(request);
            publishState(state);
        } catch (Exception e) {
            log.warn("Conquest answer failed: sessionId={}, error={}", sessionId, e.getMessage());
            publishError(sessionId, "ANSWER_FAILED", e.getMessage());
        }
    }

    @MessageMapping("/conquest.state")
    public void publishStateRequest(StartConquestGameRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        try {
            ConquestSessionStateDto state = conquestGameService.getSessionState(sessionId);
            publishState(state);
        } catch (Exception e) {
            log.warn("Conquest state request failed: sessionId={}, error={}", sessionId, e.getMessage());
            publishError(sessionId, "STATE_FAILED", e.getMessage());
        }
    }

    @MessageMapping("/conquest.ready")
    public void setReady(SetConquestReadyRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        try {
            ConquestSessionStateDto state = conquestGameService.setReady(request);
            publishState(state);
        } catch (Exception e) {
            log.warn("Conquest ready failed: sessionId={}, error={}", sessionId, e.getMessage());
            publishError(sessionId, "READY_FAILED", e.getMessage());
        }
    }

    @MessageMapping("/conquest.leave")
    public void leave(StartConquestGameRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        try {
            ConquestSessionStateDto state = conquestGameService.leaveSession(request);
            publishState(state);
        } catch (Exception e) {
            log.warn("Conquest leave failed: sessionId={}, error={}", sessionId, e.getMessage());
            publishError(sessionId, "LEAVE_FAILED", e.getMessage());
        }
    }

    private void publishState(ConquestSessionStateDto state) {
        if (state == null || state.getSessionId() == null) return;
        messagingTemplate.convertAndSend("/topic/conquest/" + state.getSessionId(), state);
    }

    private void publishError(String sessionId, String code, String message) {
        if (sessionId == null) return;
        messagingTemplate.convertAndSend(
                "/topic/conquest/" + sessionId + "/errors",
                new ConquestErrorDto(code, message)
        );
    }
}
