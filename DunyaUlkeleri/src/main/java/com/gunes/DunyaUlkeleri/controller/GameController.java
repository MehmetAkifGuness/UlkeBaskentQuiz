package com.gunes.DunyaUlkeleri.controller;

import com.gunes.DunyaUlkeleri.dto.request.GameAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.DictionaryResponse;
import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;
import com.gunes.DunyaUlkeleri.service.GameService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/game")
@RequiredArgsConstructor
public class GameController {

    private final GameService gameService;

    // 1. Yeni oyun başlatma kapısı
    @PostMapping("/start")
    public ResponseEntity<GameStatusResponse> startGame(
            @RequestParam String category,
            @RequestParam String mode,
            Authentication authentication) {
        return ResponseEntity.ok(gameService.startGame(authentication.getName(), category, mode));
    }

    // 2. Soruya cevap verme (Tahmin yürütme) kapısı
    @PostMapping("/submit")
    public ResponseEntity<GameStatusResponse> submitAnswer(
            @RequestBody GameAnswerRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(gameService.submitAnswer(request, authentication.getName()));
    }

    // 3. Sözlük verilerini getirme kapısı
    @GetMapping("/dictionary")
    public ResponseEntity<List<DictionaryResponse>> getDictionary() {
        return ResponseEntity.ok(gameService.getDictionary());
    }

    // 4. 🚨 YENİ EKLENDİ: Yarım kalan oyunu canlandırma kapısı
    @GetMapping("/resume")
    public ResponseEntity<GameStatusResponse> resumeGame(Authentication authentication) {
        GameStatusResponse response = gameService.resumeGame(authentication.getName());
        
        if (response == null) {
            // Yarım kalan oyun yoksa Flutter'a 204 (No Content) kodu yolla
            return ResponseEntity.noContent().build(); 
        }
        
        // Oyun varsa 200 (OK) ile oyun verilerini yolla
        return ResponseEntity.ok(response);
    }
}