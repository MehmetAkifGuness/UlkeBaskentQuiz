package com.gunes.DunyaUlkeleri.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class JoinDuelSessionResponse {
    private String sessionId;
    private String roomCode;
    private String playerId;
}

