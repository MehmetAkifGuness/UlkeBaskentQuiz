package com.gunes.DunyaUlkeleri.dto.request;

import lombok.Data;

@Data
public class GameAnswerRequest {
    private Long sessionId;
    private String capitalGuess; // 'answer' olan yeri 'capitalGuess' yaptık
}