package com.gunes.DunyaUlkeleri.dto.response;

import java.time.LocalDateTime;

import lombok.Data;

// kullanıcı profiline tıkladığında açılacak sınıf ve istatistikleri
@Data
public class UserProfileResponse {
    private String username;
    private String displayName;
    private String email;
    private LocalDateTime creationDate;
    private int maxWinStreak;
    private int totalGamesPlayed;
    private long totalMasteryPoints;
    private int trophies;
    private String league;
    private int trophySeason;
    private Integer avatarId;
    private boolean hasCustomAvatar;

    private boolean hasPlayedDaily;

    private Integer dailyStreak;
}
