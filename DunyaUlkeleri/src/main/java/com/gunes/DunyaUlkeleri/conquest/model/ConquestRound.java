package com.gunes.DunyaUlkeleri.conquest.model;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConquestRound {
    private int roundNumber;
    private String targetIsoCode;
    private String targetCountryName;

    private boolean locked;
    private String winnerPlayerId;

    private Instant startedAt;
    private Instant finishedAt;
}
