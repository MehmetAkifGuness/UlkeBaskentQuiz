package com.gunes.DunyaUlkeleri.service;

import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.league.LeagueTier;

public interface LeagueService {

    int currentSeasonId();

    void ensureSeason(User user);

    LeagueTier tierOf(int trophies);

    String leagueNameOf(int trophies);

    void applyMatchResult(String winnerUsername, String loserUsername);
}

