package com.gunes.DunyaUlkeleri.entity;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DuelPlayer {
    private String playerId;
    private String username;
    private int score;
    private boolean connected;
}

