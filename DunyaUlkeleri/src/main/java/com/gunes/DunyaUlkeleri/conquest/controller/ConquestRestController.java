package com.gunes.DunyaUlkeleri.conquest.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gunes.DunyaUlkeleri.conquest.dto.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.conquest.dto.CreateConquestSessionRequest;
import com.gunes.DunyaUlkeleri.conquest.dto.CreateConquestSessionResponse;
import com.gunes.DunyaUlkeleri.conquest.dto.JoinConquestSessionRequest;
import com.gunes.DunyaUlkeleri.conquest.dto.JoinConquestSessionResponse;
import com.gunes.DunyaUlkeleri.conquest.service.ConquestGameService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/conquest")
@RequiredArgsConstructor
public class ConquestRestController {

    private final ConquestGameService conquestGameService;
    private final SimpMessagingTemplate messagingTemplate;

    // Oda oluşturma
    @PostMapping("/sessions")
    public ResponseEntity<CreateConquestSessionResponse> createSession(
            @RequestBody CreateConquestSessionRequest request
    ) {
        final CreateConquestSessionResponse response = conquestGameService.createSession(request);
        publishState(response.getSessionId());
        return ResponseEntity.ok(response);
    }

    // Odaya katılma
    @PostMapping("/sessions/{roomCode}/join")
    public ResponseEntity<JoinConquestSessionResponse> joinSession(
            @PathVariable String roomCode,
            @RequestBody JoinConquestSessionRequest request
    ) {
        final JoinConquestSessionResponse response = conquestGameService.joinSession(roomCode, request);
        publishState(response.getSessionId());
        return ResponseEntity.ok(response);
    }

    // Hızlı oyun (matchmaking)
    @PostMapping("/quick-match")
    public ResponseEntity<CreateConquestSessionResponse> quickMatch(
            @RequestBody CreateConquestSessionRequest request
    ) {
        final CreateConquestSessionResponse response = conquestGameService.quickMatch(request);
        publishState(response.getSessionId());
        return ResponseEntity.ok(response);
    }

    // Mevcut state
    @GetMapping("/sessions/{sessionId}")
    public ResponseEntity<ConquestSessionStateDto> getSessionState(@PathVariable String sessionId) {
        return ResponseEntity.ok(conquestGameService.getSessionState(sessionId));
    }

    private void publishState(String sessionId) {
        if (sessionId == null || sessionId.isBlank()) return;
        final ConquestSessionStateDto state = conquestGameService.getSessionState(sessionId);
        messagingTemplate.convertAndSend("/topic/conquest/" + sessionId, state);
    }
}

