package com.gunes.DunyaUlkeleri.controller;

import com.gunes.DunyaUlkeleri.dto.request.GameAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.DictionaryResponse;
import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;
import com.gunes.DunyaUlkeleri.service.GameService;
import lombok.RequiredArgsConstructor;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/game")
@RequiredArgsConstructor
public class GameController {

    private final GameService gameService;

    @PostMapping("/start")
    public ResponseEntity<GameStatusResponse> startGame(@RequestParam(defaultValue = "Dünya") String category) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        // frontend'den gelen kategoriyi servise iletiyoruz
        GameStatusResponse response = gameService.startGame(username, category);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/submit")
    public ResponseEntity<GameStatusResponse> submitAnswer(@RequestBody GameAnswerRequest request) {
        // GÜVENLİK: Oturum çalmayı (IDOR) engellemek için kimliği de gönderiyoruz
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        
        GameStatusResponse response = gameService.submitAnswer(request, username);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/dictionary")
    public ResponseEntity<List<DictionaryResponse>> getDictionary() {
        List<DictionaryResponse> dictionary = gameService.getDictionary();
        return ResponseEntity.ok(dictionary);
    }
}