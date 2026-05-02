package com.gunes.DunyaUlkeleri.dto.response;

import java.time.LocalDateTime;

import lombok.Data;

@Data
public class RecentSessionResponse {
    private Long id;
    private String category;
    private String gameMode;
    private int currentScore;
    private int remainingLives;
    private boolean finished;
    private LocalDateTime createdAt;
    private LocalDateTime updateAt;
}

