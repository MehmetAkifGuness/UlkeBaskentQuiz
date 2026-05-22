package com.gunes.DunyaUlkeleri.dto.response;

import java.time.Instant;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DuelRoundDto {
    private int roundNumber;
    private String questionText;
    private List<String> options;
    private boolean locked;
    private String winnerPlayerId;
    private Instant startedAt;
    private Instant deadlineAt;
    private String correctAnswer;
}

