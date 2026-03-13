package com.gunes.DunyaUlkeleri.scheduler;

import com.gunes.DunyaUlkeleri.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Component
@RequiredArgsConstructor
public class UserCleanupScheduler {

    private final UserRepository userRepository;

    // cron = "0 0 3 * * ?" demek -> "Her gün gece saat 03:00'te çalış" demektir.
    // (Test etmek istersen cron = "0 * * * * ?" yazabilirsin, her dakika başı çalışır)
    @Scheduled(cron = "0 0 3 * * ?")
    @Transactional
    public void cleanUpGhostAccounts() {
        // Şu anki zamandan tam 24 saat öncesinin tarihini alıyoruz
        LocalDateTime cutoffTime = LocalDateTime.now().minusHours(24);
        
        // Veritabanına gidip "24 saatten eski ve isVerified=false olan herkesi SİL" diyoruz
        userRepository.deleteUnverifiedUsersOlderThan(cutoffTime);
        
        System.out.println("Zamanlanmış Görev Çalıştı: 24 saatten eski doğrulanmamış hayalet hesaplar temizlendi.");
    }
}