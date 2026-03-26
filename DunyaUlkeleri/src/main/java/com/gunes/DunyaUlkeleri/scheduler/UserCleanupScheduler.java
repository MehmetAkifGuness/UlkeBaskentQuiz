package com.gunes.DunyaUlkeleri.scheduler;

import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class UserCleanupScheduler {

    private final UserRepository userRepository;
    private final GameSessionRepository gameSessionRepository;

    // --- 1. MİSAFİR HESAP VE OYUN ÇÖPLÜĞÜ TEMİZLİĞİ ---
    @Scheduled(cron = "0 0 3 * * ?") // Her gece saat 03:00'te çalışır
    @Transactional
    public void cleanUpGuestUsers() {
        log.info("Misafir kullanıcı temizliği başlatıldı...");

        List<User> guestUsers = userRepository.findByIsGuestTrue();

        if (guestUsers.isEmpty()) {
            log.info("Temizlenecek misafir kullanıcı bulunamadı.");
            return;
        }

        int deletedCount = 0;
        for (User guest : guestUsers) {
            gameSessionRepository.deleteByUser(guest);
            userRepository.delete(guest);
            deletedCount++;
        }

        log.info("Misafir kullanıcı temizliği tamamlandı. Silinen hesap sayısı: " + deletedCount);
    }

    // --- 2. ONAYLANMAMIŞ (SAHTE) HESAP TEMİZLİĞİ ---
    @Scheduled(cron = "0 30 3 * * ?") // Her gece saat 03:30'da çalışır
    @Transactional
    public void cleanUpUnverifiedUsers() {
        log.info("Doğrulanmamış (E-posta onayı yapılmamış) eski hesapların temizliği başlatıldı...");
        
        try {
            LocalDateTime cutoffTime = LocalDateTime.now().minusHours(24);
            userRepository.deleteUnverifiedUsersOlderThan(cutoffTime);
            log.info("24 saatten eski olan ve e-posta onayı yapılmamış sahte hesaplar veritabanından başarıyla silindi.");
        } catch (Exception e) {
            log.error("Doğrulanmamış hesaplar temizlenirken kritik bir hata oluştu: {}", e.getMessage());
        }
    }

    // --- 3. BİTMİŞ VE ESKİ OYUN OTURUMLARINI (GAMESESSION) TEMİZLEME ---
    // 🚨 YENİ EKLENDİ: Veritabanının şişmesini (Saatli Bombayı) engelleyen mekanizma!
    @Scheduled(cron = "0 0 4 * * ?") // Her gece saat 04:00'te çalışır
    @Transactional
    public void cleanUpOldGameSessions() {
        log.info("Eski ve bitmiş oyun oturumlarının (GameSession) temizliği başlatıldı...");
        
        try {
            // Tam 24 saat (1 gün) öncesini sınır kabul ediyoruz
            LocalDateTime cutoffTime = LocalDateTime.now().minusHours(24);
            
            // 24 saatten eski ve 'isFinished = true' olan oyunları bul
            List<GameSession> oldSessions = gameSessionRepository.findByIsFinishedTrueAndUpdateAtBefore(cutoffTime);
            
            if (oldSessions.isEmpty()) {
                log.info("Silinecek eski oyun oturumu bulunamadı.");
                return;
            }

            // JPA'nın güvenli silme işlemiyle (Alt tabloları da temizleyerek) oturumları sil
            gameSessionRepository.deleteAll(oldSessions);
            
            log.info("Veritabanı optimize edildi: {} adet eski oyun oturumu başarıyla silindi.", oldSessions.size());
        } catch (Exception e) {
            log.error("Eski oyun oturumları temizlenirken kritik bir hata oluştu: {}", e.getMessage());
        }
    }
}