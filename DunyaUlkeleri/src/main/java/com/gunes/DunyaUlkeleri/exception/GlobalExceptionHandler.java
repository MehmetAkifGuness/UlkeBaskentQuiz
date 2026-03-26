package com.gunes.DunyaUlkeleri.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    // --- 1. BİZİM KONTROLÜMÜZDEKİ (GÜVENLİ) HATALAR ---
    // Uygulama içinde bizim kasıtlı olarak fırlattığımız mesajlar 
    // (Örn: "Bu e-posta kullanımda", "Doğrulama kodu geçersiz", "Çok fazla yanlış deneme")
    @ExceptionHandler({RuntimeException.class, IllegalArgumentException.class})
    public ResponseEntity<Map<String, String>> handleBusinessExceptions(Exception e) {
        Map<String, String> response = new HashMap<>();
        response.put("message", e.getMessage()); // Kullanıcıya sadece bizim yazdığımız temiz mesaj gider
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    // --- 2. 🚨 BİLİNMEYEN VE KRİTİK HATALAR (GİZLENMELİ) ---
    // Veritabanı çökmesi, NullPointer, SQL Syntax hataları, sunucu kopmaları vb.
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGlobalException(Exception e) {
        
        // 1. Gerçek ve kritik hatayı sunucu loglarına yazdırıyoruz (Backend'i izlerken sadece sen göreceksin)
        log.error("💥 BEKLENMEYEN KRİTİK HATA MEYDANA GELDİ: ", e);

        // 2. Kullanıcıya veya araya giren kötü niyetli kişilere SADECE kapalı kutu, güvenli bir mesaj dönüyoruz
        Map<String, String> response = new HashMap<>();
        response.put("message", "Sunucu tarafında beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.");
        
        // 500 Internal Server Error statü koduyla dönüyoruz
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}