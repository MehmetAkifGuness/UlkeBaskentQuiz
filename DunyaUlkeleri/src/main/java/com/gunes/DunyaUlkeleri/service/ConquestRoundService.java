package com.gunes.DunyaUlkeleri.service;

import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.entity.ConquestRound;

public interface ConquestRoundService {
    boolean areAllPlayersOutOfLives(ConquestGameSession session);

    void pickNextTargetCountry(ConquestGameSession session, String lastWinnerPlayerId);

    void finishRound(ConquestGameSession session, ConquestPlayer winner, ConquestRound round);
}
