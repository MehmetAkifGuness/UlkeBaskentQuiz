package com.gunes.DunyaUlkeleri.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DuelPlayerDto {
    private String playerId;
    private String username;
    private int score;
    private boolean connected;
}

