package com.gunes.DunyaUlkeleri.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import com.gunes.DunyaUlkeleri.dto.request.LeaveDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.SubmitDuelAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.DuelErrorDto;
import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.service.DuelGameService;

import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
public class DuelWebSocketController {

    private static final Logger log = LoggerFactory.getLogger(DuelWebSocketController.class);

    private final SimpMessagingTemplate messagingTemplate;
    private final DuelGameService duelGameService;

    @MessageMapping("/duel.answer")
    public void submitAnswer(SubmitDuelAnswerRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        try {
            DuelSessionStateDto state = duelGameService.submitAnswer(request);
            publishState(state);
        } catch (Exception e) {
            log.warn("Duel answer failed: sessionId={}, error={}", sessionId, e.getMessage());
            publishError(sessionId, "ANSWER_FAILED", e.getMessage());
        }
    }

    @MessageMapping("/duel.state")
    public void publishStateRequest(LeaveDuelSessionRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        try {
            DuelSessionStateDto state = duelGameService.getSessionState(sessionId);
            publishState(state);
        } catch (Exception e) {
            log.warn("Duel state request failed: sessionId={}, error={}", sessionId, e.getMessage());
            publishError(sessionId, "STATE_FAILED", e.getMessage());
        }
    }

    @MessageMapping("/duel.leave")
    public void leave(LeaveDuelSessionRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        try {
            DuelSessionStateDto state = duelGameService.leaveSession(request);
            publishState(state);
        } catch (Exception e) {
            log.warn("Duel leave failed: sessionId={}, error={}", sessionId, e.getMessage());
            publishError(sessionId, "LEAVE_FAILED", e.getMessage());
        }
    }

    private void publishState(DuelSessionStateDto state) {
        if (state == null || state.getSessionId() == null) return;
        messagingTemplate.convertAndSend("/topic/duel/" + state.getSessionId(), state);
    }

    private void publishError(String sessionId, String code, String message) {
        if (sessionId == null) return;
        messagingTemplate.convertAndSend(
                "/topic/duel/" + sessionId + "/errors",
                new DuelErrorDto(code, message)
        );
    }
}

