package com.gunes.DunyaUlkeleri.dto.response;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DuelSessionStateDto {
    private String sessionId;
    private String roomCode;
    private String status;
    private String category;
    private String mode;
    private boolean quickMatch;
    private String lastEventMessage;
    private String lastAnsweredPlayerId;
    private Boolean lastAnswerCorrect;
    private Integer lastAnsweredRoundNumber;
    private String winnerUsername;
    private boolean finished;
    private List<DuelPlayerDto> players;
    private DuelRoundDto currentRound;
}
