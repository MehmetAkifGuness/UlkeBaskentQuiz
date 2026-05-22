package com.gunes.DunyaUlkeleri.controller;

import com.gunes.DunyaUlkeleri.dto.request.UpdateProfileRequest;
import com.gunes.DunyaUlkeleri.dto.request.UpdateUsernameRequest;
import com.gunes.DunyaUlkeleri.dto.response.AuthResponse;
import com.gunes.DunyaUlkeleri.dto.response.LeaderboardEntryResponse;
import com.gunes.DunyaUlkeleri.dto.response.RecentSessionResponse;
import com.gunes.DunyaUlkeleri.dto.response.UserAvatarImageResponse;
import com.gunes.DunyaUlkeleri.dto.response.UserProfileResponse;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
import com.gunes.DunyaUlkeleri.service.LeaderboardService;
import com.gunes.DunyaUlkeleri.service.UserProfileQueryService;
import com.gunes.DunyaUlkeleri.service.UserService;
import lombok.RequiredArgsConstructor;
import java.util.List;
import java.util.Map;
import java.util.Set;

import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final LeaderboardService leaderboardService;
    private final UserProfileQueryService userProfileQueryService;

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
        return ResponseEntity.ok(userProfileQueryService.getMyCategoryScores(authentication.getName()));
    }

    @GetMapping("/recent-sessions")
    public ResponseEntity<List<RecentSessionResponse>> getRecentSessions(
            Authentication authentication,
            @RequestParam(defaultValue = "3") int limit) {
        return ResponseEntity.ok(userProfileQueryService.getRecentSessions(authentication.getName(), limit));
    }

    // 🚨 YENİ: mode parametresi eklendi
    @GetMapping("/leaderboard/{category}")
    public ResponseEntity<List<LeaderboardEntryResponse>> getCategoryLeaderboard(
            @PathVariable String category,
            @RequestParam(defaultValue = "MIXED") String mode) {
        return ResponseEntity.ok(leaderboardService.getCategoryLeaderboard(category, mode));
    }

    @GetMapping("/mistakes")
    public ResponseEntity<Set<Question>> getUserMistakes(Authentication authentication) {
        return ResponseEntity.ok(userProfileQueryService.getUserMistakes(authentication.getName()));
    }

    @DeleteMapping("/mistakes/{questionId}")
    public ResponseEntity<String> removeMistake(@PathVariable Long questionId, Authentication authentication) {
        userProfileQueryService.removeMistake(authentication.getName(), questionId);
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

    @PutMapping("/username")
    public ResponseEntity<AuthResponse> updateUsername(@RequestBody UpdateUsernameRequest request) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(userService.updateUsername(username, request.getUsername()));
    }

    @PostMapping(value = "/avatar/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UserProfileResponse> uploadCustomAvatar(@RequestParam("avatar") MultipartFile avatar) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();

        if (avatar == null || avatar.isEmpty()) {
            throw AppException.badRequest("AVATAR_IMAGE_REQUIRED", "Profil fotoğrafı boş olamaz.");
        }

        try {
            return ResponseEntity.ok(
                    userService.uploadCustomAvatar(
                            username,
                            avatar.getBytes(),
                            avatar.getContentType()
                    )
            );
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

    @GetMapping("/avatar/image/{username}")
    public ResponseEntity<byte[]> getCustomAvatarImage(@PathVariable String username) {
        UserAvatarImageResponse imageResponse = userProfileQueryService.getCustomAvatarImage(username);
        byte[] image = imageResponse.bytes();
        String contentType = imageResponse.contentType();
        MediaType mediaType = (contentType == null || contentType.isBlank())
                ? MediaType.APPLICATION_OCTET_STREAM
                : MediaType.parseMediaType(contentType);

        return ResponseEntity.ok()
                .contentType(mediaType)
                .cacheControl(CacheControl.maxAge(1, TimeUnit.DAYS).cachePrivate())
                .body(image);
    }

    @DeleteMapping("/account")
    public ResponseEntity<Void> deleteAccount(Authentication authentication) {
        userService.deleteAccount(authentication.getName());
        return ResponseEntity.noContent().build();
    }
}
