package com.gunes.DunyaUlkeleri.scheduler;

import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class UserCleanupScheduler {

    private final UserRepository userRepository;
    private final GameSessionRepository gameSessionRepository;

    @Scheduled(cron = "0 0 3 * * ?") // Her gece saat 03:00'te çalışır
    @Transactional
    public void cleanUpGuestUsers() {
        log.info("Misafir kullanıcı temizliği başlatıldı...");

        // 1. Tüm misafir kullanıcıları bul
        List<User> guestUsers = userRepository.findByIsGuestTrue(); // 🚨 NOT: Bu metodun UserRepository'de olması lazım: List<User> findByIsGuestTrue();

        if (guestUsers.isEmpty()) {
            log.info("Temizlenecek misafir kullanıcı bulunamadı.");
            return;
        }

        int deletedCount = 0;
        for (User guest : guestUsers) {
            // 🚨 ÖNEMLİ: SQL Foreign Key Hatasını (Çökmeyi) önlemek için önce kullanıcının oyun oturumlarını siliyoruz
            gameSessionRepository.deleteByUser(guest); // 🚨 NOT: GameSessionRepository'de void deleteByUser(User user); metodu olmalı
            
            // Sonra kullanıcıyı siliyoruz
            userRepository.delete(guest);
            deletedCount++;
        }

        log.info("Misafir kullanıcı temizliği tamamlandı. Silinen hesap sayısı: " + deletedCount);
    }
}