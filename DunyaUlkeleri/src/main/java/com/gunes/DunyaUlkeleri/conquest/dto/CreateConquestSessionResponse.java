package com.gunes.DunyaUlkeleri.conquest.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateConquestSessionResponse {
    private String sessionId;
    private String roomCode;
    private String playerId;
}

