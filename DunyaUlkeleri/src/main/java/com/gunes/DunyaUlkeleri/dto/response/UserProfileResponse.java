package com.gunes.DunyaUlkeleri.dto.response;

import java.time.LocalDateTime;

import lombok.Data;

// kullanıcı profiline tıkladığında açılacak sınıf ve istatistikleri
@Data
public class UserProfileResponse {
    private String username;
    private LocalDateTime creationDate;
    private int maxWinStreak;
    private int totalGamesPlayed;
}
