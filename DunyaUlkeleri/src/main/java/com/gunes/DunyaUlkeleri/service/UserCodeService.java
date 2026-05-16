package com.gunes.DunyaUlkeleri.service;

import com.gunes.DunyaUlkeleri.entity.User;

/**
 * User verification/reset code lifecycle policies.
 *
 * <p>SRP: Only concerns code generation and validation rules (expiry / brute force counters),
 * and mutating the {@link User} fields related to these codes.</p>
 */
public interface UserCodeService {

    String issueVerificationCode(User user);

    String issueResetCode(User user);

    void validateActiveCode(User user);

    void recordFailedAttempt(User user);

    void clearVerificationCode(User user);

    void clearResetCode(User user);
}

