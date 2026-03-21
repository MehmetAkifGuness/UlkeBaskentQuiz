package com.gunes.DunyaUlkeleri.controller;

import com.gunes.DunyaUlkeleri.dto.response.UserProfileResponse;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.UserService;
import lombok.RequiredArgsConstructor;

import com.gunes.DunyaUlkeleri.repository.QuestionRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.security.core.Authentication;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final UserRepository userRepository;
    private final GameSessionRepository gameSessionRepository; 

    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> getUserProfile() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        UserProfileResponse response = userService.getUserProfile(username);
        
        if (response != null) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.notFound().build(); 
    }

    @GetMapping("/my-category-scores")
    public ResponseEntity<Map<String, Integer>> getMyCategoryScores(Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
        return ResponseEntity.ok(user.getCategoryBestScores());
    }

    // 🚨 YENİ: mode parametresi eklendi
    @GetMapping("/leaderboard/{category}")
    public ResponseEntity<List<Map<String, Object>>> getCategoryLeaderboard(
            @PathVariable String category,
            @RequestParam(defaultValue = "MIXED") String mode) { // Varsayılan mod Karışıktır
            
        List<Object[]> topUsers;
        
        if ("DailyChallenge".equals(category)) {
            LocalDateTime startOfDay = LocalDate.now().atStartOfDay(); 
            topUsers = gameSessionRepository.findTop10DailyScores(category, startOfDay, PageRequest.of(0, 10));
        } else {
            // 🚨 SİHİRLİ DEĞİŞİM: Artık User tablosundan değil, GameSession'dan mod seçimine göre çekiyoruz
            topUsers = gameSessionRepository.findTop10ByCategoryAndMode(category, mode, PageRequest.of(0, 10));
        }
        
        List<Map<String, Object>> leaderboard = new ArrayList<>();
        for (Object[] record : topUsers) {
            Map<String, Object> map = new HashMap<>();
            map.put("username", record[0]);
            map.put("score", record[1]);
            leaderboard.add(map);
        }
        return ResponseEntity.ok(leaderboard);
    }

    private final QuestionRepository questionRepository; 

    @GetMapping("/mistakes")
    public ResponseEntity<Set<Question>> getUserMistakes(Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
        return ResponseEntity.ok(user.getFailedQuestions());
    }

    @DeleteMapping("/mistakes/{questionId}")
    public ResponseEntity<String> removeMistake(@PathVariable Long questionId, Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
        
        user.getFailedQuestions().removeIf(q -> q.getId().equals(questionId));
        userRepository.save(user); 
        return ResponseEntity.ok("Hata başarıyla silindi.");
    }

    @PutMapping("/avatar/{avatarId}")
    public ResponseEntity<String> updateAvatar(@PathVariable Integer avatarId) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        userService.updateAvatar(username, avatarId);
        return ResponseEntity.ok("Avatar başarıyla güncellendi.");
    }
}