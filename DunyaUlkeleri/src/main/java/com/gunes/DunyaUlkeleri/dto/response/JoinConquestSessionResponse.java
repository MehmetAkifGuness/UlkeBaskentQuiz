package com.gunes.DunyaUlkeleri.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class JoinConquestSessionResponse {
    private String sessionId;
    private String roomCode;
    private String playerId;
}
