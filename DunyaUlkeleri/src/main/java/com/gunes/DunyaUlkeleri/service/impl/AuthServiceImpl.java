package com.gunes.DunyaUlkeleri.service.impl;

import com.gunes.DunyaUlkeleri.dto.request.*;
import com.gunes.DunyaUlkeleri.dto.response.AuthResponse;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.security.JwtUtil;
import com.gunes.DunyaUlkeleri.service.AuthService;
import com.gunes.DunyaUlkeleri.service.EmailService;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional; 
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final EmailService emailService;
    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder passwordEncoder;

    @Override
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("Bu kullanıcı adı zaten alınmış!");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Bu e-posta adresi zaten kullanılıyor!");
        }

        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setVerified(false);
        user.setGuest(false);
        user.setAvatarId(1);

        String code = generateCode();
        user.setVerificationCode(code);
        
        // 🚨 GÜVENLİK: Kodu ve saati doğrudan veritabanına yazıyoruz (RAM'e değil)
        user.setCodeGenerationTime(LocalDateTime.now());
        user.setFailedAttemptCount(0);
        
        userRepository.save(user);
        emailService.sendVerificationCode(user.getEmail(), code);

        return createResponse(null, user.getUsername(), "Kayıt Başarılı! Lütfen e-postanızı doğrulayın.");
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Kullanıcı adı veya şifre yanlış!"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Kullanıcı adı veya şifre yanlış!");
        }

        if (!user.isVerified() && !user.isGuest()) {
            throw new IllegalArgumentException("Lütfen önce e-postanızı doğrulayın!");
        }

        String token = jwtUtil.generateToken(user.getUsername());
        return createResponse(token, user.getUsername(), "Giriş Başarılı! Hoş geldin " + user.getUsername());
    }

    @Override
    public AuthResponse guestLogin() {
        String guestUsername = "Misafir_" + UUID.randomUUID().toString().substring(0, 8);
        
        User guestUser = new User();
        guestUser.setEmail(guestUsername + "@misafir.com");
        guestUser.setUsername(guestUsername);
        guestUser.setPassword(passwordEncoder.encode(UUID.randomUUID().toString())); 
        guestUser.setGuest(true);
        guestUser.setAvatarId(1);
        guestUser.setVerified(true);
        userRepository.save(guestUser);

        String token = jwtUtil.generateToken(guestUser.getUsername());
        return createResponse(token, guestUser.getUsername(), "Misafir girişi başarılı!");
    }

    @Override
    public AuthResponse verifyEmail(VerifyCodeRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Bu e-posta adresine ait kullanıcı bulunamadı!"));

        // 🚨 GÜVENLİK: Veritabanı üzerinden süre ve kaba kuvvet kontrolü
        checkBruteForceAndExpiration(user);

        if (request.getCode().equals(user.getVerificationCode())) {
            user.setVerified(true);
            
            // Başarılı olunca kodları, saatleri ve hatalı denemeleri temizle
            user.setVerificationCode(null);
            user.setCodeGenerationTime(null);
            user.setFailedAttemptCount(0);
            
            userRepository.save(user);
            return createResponse(null, user.getUsername(), "Hesabınız başarıyla doğrulandı!");
        }
        
        // Yanlış girildiyse deneme sayısını artırıp DB'ye kaydet
        increaseFailedAttempt(user);
        throw new IllegalArgumentException("Doğrulama kodu geçersiz!");
    }

    @Override
    public AuthResponse forgotPassword(ResetPasswordRequest request) {
        String input = request.getEmail(); 
        
        Optional<User> userOpt = userRepository.findByEmail(input);
        if (userOpt.isEmpty()) {
            userOpt = userRepository.findByUsername(input);
        }

        userOpt.ifPresent(user -> {
            String resetCode = generateCode();
            user.setResetCode(resetCode);
            
            // 🚨 GÜVENLİK: Şifre sıfırlama kodunu ve saati veritabanına kaydet
            user.setCodeGenerationTime(LocalDateTime.now());
            user.setFailedAttemptCount(0);
            
            userRepository.save(user);
            emailService.sendPasswordResetEmail(user.getEmail(), resetCode);
        });
        
        return createResponse(null, null, "Eğer bu bilgilere ait bir hesap varsa, şifre sıfırlama kodu gönderilmiştir.");
    }

    @Override
    public AuthResponse resetPassword(NewPasswordRequest request) {
        String input = request.getEmail(); 
        
        Optional<User> userOpt = userRepository.findByEmail(input);
        if (userOpt.isEmpty()) {
            userOpt = userRepository.findByUsername(input);
        }

        User user = userOpt.orElseThrow(() -> new IllegalArgumentException("Kullanıcı bulunamadı veya e-posta/kullanıcı adı hatalı!"));

        // 🚨 GÜVENLİK: Veritabanı üzerinden süre ve kaba kuvvet kontrolü
        checkBruteForceAndExpiration(user);

        if (request.getResetCode() != null && request.getResetCode().equals(user.getResetCode())) {
            user.setPassword(passwordEncoder.encode(request.getNewPassword()));
            
            // Başarılı olunca temizlik
            user.setResetCode(null); 
            user.setCodeGenerationTime(null);
            user.setFailedAttemptCount(0);
            
            userRepository.save(user);
            return createResponse(null, user.getUsername(), "Şifreniz başarıyla değiştirildi! Yeni şifrenizle giriş yapabilirsiniz.");
        }
        
        increaseFailedAttempt(user);
        throw new IllegalArgumentException("Doğrulama kodu geçersiz veya süresi dolmuş!");
    }

    // --- 🚨 VERİTABANI ODAKLI GÜVENLİK METODLARI ---
    
    private void checkBruteForceAndExpiration(User user) {
        // 1. ZAMAN AŞIMI KONTROLÜ (10 Dakika)
        if (user.getCodeGenerationTime() != null && user.getCodeGenerationTime().plusMinutes(10).isBefore(LocalDateTime.now())) {
            // Süre dolduysa kodları sıfırla
            user.setVerificationCode(null);
            user.setResetCode(null);
            user.setFailedAttemptCount(0);
            userRepository.save(user);
            throw new IllegalArgumentException("Doğrulama kodunun süresi dolmuş (10 dakika). Lütfen yeni bir kod isteyin.");
        }

        // 2. KABA KUVVET (BRUTE FORCE) KONTROLÜ (Max 5 Hak)
        if (user.getFailedAttemptCount() >= 5) {
            throw new IllegalArgumentException("Çok fazla yanlış deneme yaptınız. Güvenliğiniz için lütfen yeni bir kod isteyin.");
        }
    }

    private void increaseFailedAttempt(User user) {
        user.setFailedAttemptCount(user.getFailedAttemptCount() + 1);
        userRepository.save(user);
    }
    // ------------------------------------------------

    private String generateCode() {
        SecureRandom secureRandom = new SecureRandom();
        return String.format("%06d", secureRandom.nextInt(999999));
    }

    private AuthResponse createResponse(String token, String username, String message) {
        AuthResponse response = new AuthResponse();
        response.setToken(token);
        response.setUsername(username);
        response.setMessage(message);
        return response;
    }
}