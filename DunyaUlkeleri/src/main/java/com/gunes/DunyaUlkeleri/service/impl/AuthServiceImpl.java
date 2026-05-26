package com.gunes.DunyaUlkeleri.service.impl;

import com.gunes.DunyaUlkeleri.dto.request.*;
import com.gunes.DunyaUlkeleri.dto.response.AuthResponse;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.security.JwtUtil;
import com.gunes.DunyaUlkeleri.service.AuthService;
import com.gunes.DunyaUlkeleri.service.EmailService;
import com.gunes.DunyaUlkeleri.service.UserCodeService;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

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
    private final UserCodeService userCodeService;

    @Override
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw AppException.conflict("USERNAME_TAKEN", "Bu kullanıcı adı zaten kullanılıyor.");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw AppException.conflict("EMAIL_TAKEN", "Bu e-posta adresi zaten kullanılıyor.");
        }

        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setVerified(false);
        user.setGuest(false);
        user.setAvatarId(1);

        String code = userCodeService.issueVerificationCode(user);
        

        userRepository.save(user);
        emailService.sendVerificationCode(user.getEmail(), code);

        return createResponse(null, user.getUsername(), "Kayıt Başarılı! Lütfen e-postanızı doğrulayın.");
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> AppException.unauthorized("INVALID_CREDENTIALS", "Kullanıcı adı veya şifre hatalı."));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw AppException.unauthorized("INVALID_CREDENTIALS", "Kullanıcı adı veya şifre hatalı.");
        }

        if (!user.isVerified() && !user.isGuest()) {
            throw AppException.forbidden("EMAIL_NOT_VERIFIED", "Lütfen önce e-postanızı doğrulayın.");
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
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Bu e-posta adresine ait kullanıcı bulunamadı."));

        // 🚨 GÜVENLİK: Veritabanı üzerinden süre ve kaba kuvvet kontrolü
        userCodeService.validateActiveCode(user);

        if (request.getCode().equals(user.getVerificationCode())) {
            user.setVerified(true);
            
            // Başarılı olunca kodları, saatleri ve hatalı denemeleri temizle
            userCodeService.clearVerificationCode(user);
            
            userRepository.save(user);
            return createResponse(null, user.getUsername(), "Hesabınız başarıyla doğrulandı!");
        }
        
        // Yanlış girildiyse deneme sayısını artırıp DB'ye kaydet
        userCodeService.recordFailedAttempt(user);
        userRepository.save(user);
        throw AppException.badRequest("INVALID_VERIFICATION_CODE", "Doğrulama kodu geçersiz.");
    }

    @Override
    public AuthResponse forgotPassword(ResetPasswordRequest request) {
        String input = request.getEmail(); 
        
        Optional<User> userOpt = userRepository.findByEmail(input);
        if (userOpt.isEmpty()) {
            userOpt = userRepository.findByUsername(input);
        }

        userOpt.ifPresent(user -> {
            String resetCode = userCodeService.issueResetCode(user);
            
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

        User user = userOpt.orElseThrow(() -> AppException.notFound(
                "USER_NOT_FOUND",
                "Kullanıcı bulunamadı. E-posta veya kullanıcı adını kontrol edin."
        ));

        // 🚨 GÜVENLİK: Süre ve kaba kuvvet kontrolü
        userCodeService.validateActiveCode(user);

        if (request.getResetCode() != null && request.getResetCode().equals(user.getResetCode())) {
            user.setPassword(passwordEncoder.encode(request.getNewPassword()));
            
            // Başarılı olunca temizlik
            userCodeService.clearResetCode(user);
            
            userRepository.save(user);
            return createResponse(null, user.getUsername(), "Şifreniz başarıyla değiştirildi! Yeni şifrenizle giriş yapabilirsiniz.");
        }
        
        userCodeService.recordFailedAttempt(user);
        userRepository.save(user);
        throw AppException.badRequest("INVALID_RESET_CODE", "Doğrulama kodu geçersiz veya süresi dolmuş.");
    }

    private AuthResponse createResponse(String token, String username, String message) {
        AuthResponse response = new AuthResponse();
        response.setToken(token);
        response.setUsername(username);
        response.setMessage(message);
        return response;
    }

    // 🚨 UX YAMASI: Kodu ulaşmayan veya süresi dolan kullanıcılar için yeni kod üretici
    @Override
    public AuthResponse resendVerificationCode(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));
                
        if (user.isVerified()) {
            throw AppException.conflict("ALREADY_VERIFIED", "Bu hesap zaten doğrulanmış. Giriş yapabilirsiniz.");
        }

        String newCode = userCodeService.issueVerificationCode(user);
        userRepository.save(user);

        emailService.sendVerificationCode(user.getEmail(), newCode);
        return createResponse(null, user.getUsername(), "Yeni doğrulama kodu e-posta adresinize gönderildi!");
    }
}
