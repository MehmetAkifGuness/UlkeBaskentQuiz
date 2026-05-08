package com.gunes.DunyaUlkeleri.conquest.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConquestPlayerDto {
    private String playerId;
    private String username;
    private String colorHex;
    private String type;
    private int score;
    private int conqueredCount;
    private boolean connected;
}

