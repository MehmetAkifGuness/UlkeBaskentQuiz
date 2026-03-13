package com.gunes.DunyaUlkeleri.service;

//email ile ilgili bilgiler doğrulama kodu vs
public interface EmailService {
    void sendVerificationCode(String toEmail , String code);

    void sendPasswordResetEmail(String toEmail , String resetCode);
}
