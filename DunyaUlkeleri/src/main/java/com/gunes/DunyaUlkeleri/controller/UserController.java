package com.gunes.DunyaUlkeleri.controller;

import com.gunes.DunyaUlkeleri.dto.request.UpdateProfileRequest;
import com.gunes.DunyaUlkeleri.dto.response.UserProfileResponse;
import com.gunes.DunyaUlkeleri.dto.response.RecentSessionResponse;
import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
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

import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

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
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));
        return ResponseEntity.ok(user.getCategoryBestScores());
    }

    @GetMapping("/recent-sessions")
    public ResponseEntity<List<RecentSessionResponse>> getRecentSessions(
            Authentication authentication,
            @RequestParam(defaultValue = "3") int limit) {
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        int safeLimit = Math.max(1, Math.min(limit, 10));
        List<GameSession> sessions = gameSessionRepository.findTop10ByUserAndIsFinishedTrueOrderByUpdateAtDesc(user);

        List<RecentSessionResponse> response = sessions.stream()
                .limit(safeLimit)
                .map(session -> {
                    RecentSessionResponse dto = new RecentSessionResponse();
                    dto.setId(session.getId());
                    dto.setCategory(session.getCategory() == null ? "Dünya" : session.getCategory());
                    dto.setGameMode(session.getGameMode() == null ? "MIXED" : session.getGameMode());
                    dto.setCurrentScore(session.getCurrentScore());
                    dto.setRemainingLives(session.getRemainingLives());
                    dto.setFinished(session.isFinished());
                    dto.setCreatedAt(session.getCreatedAt());
                    dto.setUpdateAt(session.getUpdateAt());
                    return dto;
                })
                .toList();

        return ResponseEntity.ok(response);
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
        } else if ("ENDLESS".equalsIgnoreCase(mode)) {
            // Sonsuz mod ayrı bir leaderboard olarak tutuluyor (kategori aynı olsa bile karışmamalı).
            topUsers = gameSessionRepository.findTop10ByCategoryAndMode(category, "ENDLESS", PageRequest.of(0, 10));
        } else {
            // Mod seçimi kaldırıldı: Kategori (kıta) bazında tüm quiz modlarındaki en iyi skor.
            topUsers = gameSessionRepository.findTop10ByCategoryOverall(category, PageRequest.of(0, 10));
        }

        List<String> usernames = new ArrayList<>();
        for (Object[] record : topUsers) {
            if (record != null && record.length > 0 && record[0] != null) {
                usernames.add(record[0].toString());
            }
        }

        Map<String, Integer> avatarIdByUsername = new HashMap<>();
        Map<String, String> displayNameByUsername = new HashMap<>();
        if (!usernames.isEmpty()) {
            List<Object[]> profileRows = userRepository.findLeaderboardProfileByUsernames(usernames);
            for (Object[] row : profileRows) {
                if (row == null || row.length < 2 || row[0] == null) continue;

                String username = row[0].toString();

                Integer avatarId = null;
                if (row[1] instanceof Number number) {
                    avatarId = number.intValue();
                }

                avatarIdByUsername.put(username, avatarId);

                String displayName = (row.length > 2 && row[2] != null) ? row[2].toString() : null;
                displayNameByUsername.put(username, displayName);
            }
        }
        
        List<Map<String, Object>> leaderboard = new ArrayList<>();
        for (Object[] record : topUsers) {
            Map<String, Object> map = new HashMap<>();
            String username = record[0] == null ? null : record[0].toString();
            map.put("username", username);
            map.put("score", record[1]);

            if (username != null) {
                Integer avatarId = avatarIdByUsername.get(username);
                if (avatarId != null) {
                    map.put("avatarId", avatarId);
                }

                String displayName = displayNameByUsername.get(username);
                if (displayName != null && !displayName.isBlank()) {
                    map.put("displayName", displayName);
                }
            }
            leaderboard.add(map);
        }
        return ResponseEntity.ok(leaderboard);
    }

    private final QuestionRepository questionRepository; 

    @GetMapping("/mistakes")
    public ResponseEntity<Set<Question>> getUserMistakes(Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));
        return ResponseEntity.ok(user.getFailedQuestions());
    }

    @DeleteMapping("/mistakes/{questionId}")
    public ResponseEntity<String> removeMistake(@PathVariable Long questionId, Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));
        
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

    @PutMapping("/profile")
    public ResponseEntity<UserProfileResponse> updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(userService.updateDisplayName(username, request.getDisplayName()));
    }

    @PostMapping(value = "/avatar/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UserProfileResponse> uploadCustomAvatar(@RequestParam("avatar") MultipartFile avatar) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        try {
            return ResponseEntity.ok(userService.uploadCustomAvatar(username, avatar.getBytes(), avatar.getContentType()));
        } catch (Exception e) {
            throw AppException.badRequest("AVATAR_IMAGE_INVALID", "Profil fotoğrafı okunamadı.");
        }
    }

    @DeleteMapping("/avatar/custom")
    public ResponseEntity<Void> clearCustomAvatar() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        userService.clearCustomAvatar(username);
        return ResponseEntity.noContent().build();
    }
}
