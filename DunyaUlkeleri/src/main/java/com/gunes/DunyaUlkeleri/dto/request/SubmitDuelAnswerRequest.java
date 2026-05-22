package com.gunes.DunyaUlkeleri.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SubmitDuelAnswerRequest {
    private String sessionId;
    private String playerId;
    private String selectedOption;
}

