package com.gunes.DunyaUlkeleri.conquest.dto;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConquestRoundDto {
    private int roundNumber;
    private String targetIsoCode;
    private String targetCountryName;
    private boolean locked;
    private String winnerPlayerId;
    private Instant startedAt;
    private Instant finishedAt;
}
