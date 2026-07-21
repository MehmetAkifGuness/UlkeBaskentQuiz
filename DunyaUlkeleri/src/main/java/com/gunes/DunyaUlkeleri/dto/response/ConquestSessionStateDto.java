package com.gunes.DunyaUlkeleri.dto.response;

import java.util.List;
import java.util.Map;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConquestSessionStateDto {
    private String sessionId;
    private String roomCode;
    private String status;
    private String selectedContinentFilter;
    private String hostPlayerId;
    private boolean quickMatch;
    private boolean pauseUsed;

    private List<ConquestPlayerDto> players;
    private Map<String, String> conqueredCountryColors;
    private ConquestRoundDto currentRound;
    private List<String> playableIsoCodes;

    private String lastEventMessage;
    private String lastWinnerPlayerId;
    private boolean roundLocked;
}
