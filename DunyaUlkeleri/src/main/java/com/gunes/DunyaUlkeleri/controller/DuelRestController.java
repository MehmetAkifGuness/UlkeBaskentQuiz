package com.gunes.DunyaUlkeleri.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gunes.DunyaUlkeleri.dto.request.CreateDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.JoinDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.request.LeaveDuelSessionRequest;
import com.gunes.DunyaUlkeleri.dto.response.CreateDuelSessionResponse;
import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.dto.response.JoinDuelSessionResponse;
import com.gunes.DunyaUlkeleri.service.DuelGameService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/duel")
@RequiredArgsConstructor
public class DuelRestController {

    private final DuelGameService duelGameService;
    private final SimpMessagingTemplate messagingTemplate;

    @PostMapping("/sessions")
    public ResponseEntity<CreateDuelSessionResponse> createSession(
            @RequestBody CreateDuelSessionRequest request,
            Authentication authentication
    ) {
        if (request == null) {
            request = new CreateDuelSessionRequest();
        }
        if (authentication != null) {
            request.setUsername(authentication.getName());
        }
        final CreateDuelSessionResponse response = duelGameService.createSession(request);
        publishState(response.getSessionId());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/sessions/{roomCode}/join")
    public ResponseEntity<JoinDuelSessionResponse> joinSession(
            @PathVariable String roomCode,
            @RequestBody JoinDuelSessionRequest request,
            Authentication authentication
    ) {
        if (request == null) {
            request = new JoinDuelSessionRequest();
        }
        if (authentication != null) {
            request.setUsername(authentication.getName());
        }
        final JoinDuelSessionResponse response = duelGameService.joinSession(roomCode, request);
        publishState(response.getSessionId());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/quick-match")
    public ResponseEntity<CreateDuelSessionResponse> quickMatch(
            @RequestBody CreateDuelSessionRequest request,
            Authentication authentication
    ) {
        if (request == null) {
            request = new CreateDuelSessionRequest();
        }
        if (authentication != null) {
            request.setUsername(authentication.getName());
        }
        final CreateDuelSessionResponse response = duelGameService.quickMatch(request);
        publishState(response.getSessionId());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/sessions/{sessionId}/leave")
    public ResponseEntity<Void> leaveSession(
            @PathVariable String sessionId,
            @RequestBody LeaveDuelSessionRequest request
    ) {
        if (request == null) {
            request = new LeaveDuelSessionRequest();
        }
        if (request.getSessionId() == null || request.getSessionId().isBlank()) {
            request.setSessionId(sessionId);
        }
        final DuelSessionStateDto state = duelGameService.leaveSession(request);
        if (state != null && state.getSessionId() != null) {
            messagingTemplate.convertAndSend("/topic/duel/" + state.getSessionId(), state);
        }
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/sessions/{sessionId}")
    public ResponseEntity<DuelSessionStateDto> getSessionState(@PathVariable String sessionId) {
        return ResponseEntity.ok(duelGameService.getSessionState(sessionId));
    }

    private void publishState(String sessionId) {
        if (sessionId == null || sessionId.isBlank()) return;
        final DuelSessionStateDto state = duelGameService.getSessionState(sessionId);
        messagingTemplate.convertAndSend("/topic/duel/" + sessionId, state);
    }
}

