package com.gunes.DunyaUlkeleri.controller;

import jakarta.validation.Valid; // GERÇEK GÜVENLİK GÖREVLİSİ BURADA!
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.gunes.DunyaUlkeleri.dto.request.LoginRequest;
import com.gunes.DunyaUlkeleri.dto.request.NewPasswordRequest;
import com.gunes.DunyaUlkeleri.dto.request.RegisterRequest;
import com.gunes.DunyaUlkeleri.dto.request.ResetPasswordRequest;
import com.gunes.DunyaUlkeleri.dto.request.VerifyCodeRequest;
import com.gunes.DunyaUlkeleri.dto.response.AuthResponse;
import com.gunes.DunyaUlkeleri.service.AuthService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService service;
    
    // DİKKAT: @Valid eklendi! Artık şifresi 6 haneden kısa olanlar anında kapı dışarı edilecek.
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request){
        AuthResponse response = service.register(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request){
        AuthResponse response = service.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/guest")
    public ResponseEntity<AuthResponse> guestLogin(){
        AuthResponse response = service.guestLogin();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/verify")
    public ResponseEntity<AuthResponse> verify(@Valid @RequestBody VerifyCodeRequest request){
        AuthResponse response = service.verifyEmail(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<AuthResponse> forgotPassword(@Valid @RequestBody ResetPasswordRequest request){
        AuthResponse response = service.forgotPassword(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/reset-password")
    public ResponseEntity<AuthResponse> resetPassword(@Valid @RequestBody NewPasswordRequest request){
        AuthResponse response = service.resetPassword(request);
        return ResponseEntity.ok(response);
    }
    
    // 🚨 YENİ EKLENDİ: Kodu tekrar gönderme uç noktası
    @PostMapping("/resend-verification")
    public ResponseEntity<AuthResponse> resendVerification(@RequestParam String email) {
        return ResponseEntity.ok(service.resendVerificationCode(email));
    }
}