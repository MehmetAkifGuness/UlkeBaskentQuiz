package com.gunes.DunyaUlkeleri.entity;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import lombok.Data;

@Data
public class DuelRound {
    private int roundNumber;
    private Long questionId;
    private String questionText;
    private List<String> options;
    private String correctAnswer;
    private boolean locked;
    private String winnerPlayerId;
    private Instant startedAt;
    private Instant deadlineAt;

    /**
     * key = playerId, value = selected option (raw).
     */
    private Map<String, String> selectedByPlayerId = new HashMap<>();

    /**
     * key = playerId, value = answer time in millis since round started.
     */
    private Map<String, Long> timeTakenMsByPlayerId = new HashMap<>();

    /**
     * key = playerId, value = earned score for this round (0 if wrong/timeout).
     */
    private Map<String, Integer> earnedScoreByPlayerId = new HashMap<>();
}

