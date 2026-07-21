package com.gunes.DunyaUlkeleri.service;

import java.util.List;

import com.gunes.DunyaUlkeleri.dto.response.LeaderboardEntryResponse;
import com.gunes.DunyaUlkeleri.dto.response.LeagueLeaderboardResponse;

public interface LeaderboardService {
    List<LeaderboardEntryResponse> getCategoryLeaderboard(String category, String mode);

    LeagueLeaderboardResponse getLeagueLeaderboard(String username);
}
