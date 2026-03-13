package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gunes.DunyaUlkeleri.service.EmailService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class EmailServiceImpl implements EmailService{

    private final JavaMailSender mailSender;

    @Override
    @Async
    public void sendVerificationCode(String toEmail , String code){
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(toEmail);
        message.setSubject("Dunya Ulkeleri Dogrulama Kodu : ");
        message.setText("Kayıt Olmak İçin Dogrulama Kodunuz : " + code);
        mailSender.send(message);
    }

    @Override
    @Async
    public void sendPasswordResetEmail(String toEmail , String resetCode){
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(toEmail);
        message.setSubject("Dunya Ulkeleri Dogrulama Kodu : ");
        message.setText("Şifre Sıfırlamak İçin Dogrulama Kodunuz : " + resetCode);
        mailSender.send(message);
    }   
}
