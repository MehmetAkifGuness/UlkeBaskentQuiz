package com.gunes.DunyaUlkeleri.controller;

import com.gunes.DunyaUlkeleri.dto.request.GameAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.DictionaryResponse;
import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;
import com.gunes.DunyaUlkeleri.service.GameService;
import lombok.RequiredArgsConstructor;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/game")
@RequiredArgsConstructor
public class GameController {

    private final GameService gameService;

    @PostMapping("/start")
    public ResponseEntity<GameStatusResponse> startGame(
            @RequestParam(defaultValue = "Dünya") String category,
            @RequestParam(defaultValue = "COUNTRY_TO_CAPITAL") String mode) { // 🚨 YENİ: mode parametresi
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        // frontend'den gelen kategoriyi servise iletiyoruz
        GameStatusResponse response = gameService.startGame(username, category, mode);
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

    // 🚨 YENİ EKLENDİ: Flutter'ın "Yarım kalan oyunum var mı?" diye soracağı API noktası
    @GetMapping("/resume")
    public ResponseEntity<GameStatusResponse> resumeGame(Authentication authentication) {
        GameStatusResponse response = gameService.resumeGame(authentication.getName());
        if (response == null) {
            return ResponseEntity.noContent().build(); // 204 Döndürür (Oyun yok demek)
        }
        return ResponseEntity.ok(response);
    }
}