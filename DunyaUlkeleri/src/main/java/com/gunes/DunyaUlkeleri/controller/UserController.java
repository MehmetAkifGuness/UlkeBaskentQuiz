package com.gunes.DunyaUlkeleri.controller;

import com.gunes.DunyaUlkeleri.dto.response.UserProfileResponse;
import com.gunes.DunyaUlkeleri.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> getUserProfile() {
        // GÜVENLİK: Email'i dışarıdan (URL'den) almıyoruz. 
        // İsteği atan kişinin kimliğini (username) güvenli bir şekilde Token'dan çekiyoruz.
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        
        UserProfileResponse response = userService.getUserProfile(username);
        
        if (response != null) {
            return ResponseEntity.ok(response); // Kullanıcı bulunduysa 200 OK
        }
        return ResponseEntity.notFound().build(); // Bulunamadıysa 404 Not Found
    }
}