package com.gunes.DunyaUlkeleri.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConquestPlayer {
    private String playerId;
    private String username;
    private String colorHex;

    // İleride: BOT / HUMAN gibi türler genişletilebilir.
    // İleride multiplayer/bot ayrımı net kalmalı.
    private ConquestPlayerType type;

    private int score;
    private int conqueredCount;
    private int remainingLives;
    private boolean connected;
    private boolean ready;
}
