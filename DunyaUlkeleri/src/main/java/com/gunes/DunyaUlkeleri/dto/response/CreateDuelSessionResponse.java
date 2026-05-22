package com.gunes.DunyaUlkeleri.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CreateDuelSessionResponse {
    private String sessionId;
    private String roomCode;
    private String playerId;
}

