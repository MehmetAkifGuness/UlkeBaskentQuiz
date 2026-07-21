package com.gunes.DunyaUlkeleri.service;

import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.league.LeagueTier;

public interface LeagueService {

    int currentSeasonId();

    void ensureSeason(User user);

    void ensureAllSeasons();

    LeagueTier tierOf(int trophies);

    String leagueNameOf(int trophies);

    int leagueMinTrophiesOf(int trophies);

    String nextLeagueNameOf(int trophies);

    int nextLeagueMinTrophiesOf(int trophies);

    int trophiesToNextLeagueOf(int trophies);

    int daysRemainingInSeason();

    void applyMatchResult(String winnerUsername, String loserUsername);
}
