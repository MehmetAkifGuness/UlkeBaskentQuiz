package com.gunes.DunyaUlkeleri.serviceimp;

import java.security.SecureRandom;
import java.time.LocalDateTime;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
import com.gunes.DunyaUlkeleri.service.UserCodeService;

/**
 * SRP: Handles verification/reset code generation + validation policies.
 *
 * <p>Persistence is intentionally left to the caller so that this class stays focused on
 * code lifecycle rules and can be reused in different use-cases.</p>
 */
@Service
public class UserCodeServiceImpl implements UserCodeService {

    private static final int MAX_ATTEMPTS = 5;
    private static final int EXPIRY_MINUTES = 10;
    private static final SecureRandom secureRandom = new SecureRandom();

    @Override
    public String issueVerificationCode(User user) {
        final String code = generateCode();
        user.setVerificationCode(code);
        user.setCodeGenerationTime(LocalDateTime.now());
        user.setFailedAttemptCount(0);
        return code;
    }

    @Override
    public String issueResetCode(User user) {
        final String code = generateCode();
        user.setResetCode(code);
        user.setCodeGenerationTime(LocalDateTime.now());
        user.setFailedAttemptCount(0);
        return code;
    }

    @Override
    public void validateActiveCode(User user) {
        if (user == null) {
            throw AppException.badRequest(
                    "USER_REQUIRED",
                    "Kullanıcı bilgisi zorunludur."
            );
        }

        final LocalDateTime generatedAt = user.getCodeGenerationTime();
        if (generatedAt != null
                && generatedAt.plusMinutes(EXPIRY_MINUTES).isBefore(LocalDateTime.now())) {
            throw AppException.badRequest(
                    "CODE_EXPIRED",
                    "Doğrulama kodunun süresi dolmuş (10 dakika). Lütfen yeni bir kod isteyin."
            );
        }

        if (user.getFailedAttemptCount() >= MAX_ATTEMPTS) {
            throw AppException.tooManyRequests(
                    "TOO_MANY_ATTEMPTS",
                    "Çok fazla yanlış deneme yapıldı. Lütfen yeni bir kod isteyin."
            );
        }
    }

    @Override
    public void recordFailedAttempt(User user) {
        if (user == null) return;
        user.setFailedAttemptCount(user.getFailedAttemptCount() + 1);
    }

    @Override
    public void clearVerificationCode(User user) {
        if (user == null) return;
        user.setVerificationCode(null);
        user.setCodeGenerationTime(null);
        user.setFailedAttemptCount(0);
    }

    @Override
    public void clearResetCode(User user) {
        if (user == null) return;
        user.setResetCode(null);
        user.setCodeGenerationTime(null);
        user.setFailedAttemptCount(0);
    }

    private static String generateCode() {
        return String.format("%06d", secureRandom.nextInt(1_000_000));
    }
}
