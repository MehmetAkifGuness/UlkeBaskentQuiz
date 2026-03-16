package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.beans.factory.annotation.Value; // YENİ EKLENDİ
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
public class EmailServiceImpl implements EmailService {

    private final JavaMailSender mailSender;

    // application.properties veya launch.json'dan mail adresimizi buraya otomatik çekiyoruz
    @Value("${spring.mail.username}")
    private String senderEmail;

    @Override
    @Async
    public void sendVerificationCode(String toEmail, String code) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(senderEmail); // GMAIL İÇİN ZORUNLU VE EKSİK OLAN SATIR!
            message.setTo(toEmail);
            message.setSubject("Dünya Ülkeleri - Doğrulama Kodu");
            message.setText("Kayıt Olmak İçin Doğrulama Kodunuz: " + code);
            
            mailSender.send(message);
            System.out.println("E-posta BAŞARIYLA gönderildi: " + toEmail); // Konsolda görebilmen için
        } catch (Exception e) {
            // Eğer mail atılamazsa sessizce kaybolmasın diye terminale kırmızıyla yazdırıyoruz
            System.err.println("E-POSTA GÖNDERİLEMEDİ! Hata Detayı: " + e.getMessage());
        }
    }

    @Override
    @Async
    public void sendPasswordResetEmail(String toEmail, String resetCode) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(senderEmail); // GMAIL İÇİN ZORUNLU SATIR!
            message.setTo(toEmail);
            message.setSubject("Dünya Ülkeleri - Şifre Sıfırlama Kodu");
            message.setText("Şifrenizi Sıfırlamak İçin Doğrulama Kodunuz: " + resetCode);
            
            mailSender.send(message);
            System.out.println("Şifre sıfırlama maili BAŞARIYLA gönderildi: " + toEmail);
        } catch (Exception e) {
            System.err.println("E-POSTA GÖNDERİLEMEDİ! Hata Detayı: " + e.getMessage());
        }
    }   
}