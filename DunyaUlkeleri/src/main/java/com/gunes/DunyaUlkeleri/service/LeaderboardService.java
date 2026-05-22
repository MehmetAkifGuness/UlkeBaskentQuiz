package com.gunes.DunyaUlkeleri.service;

import java.util.List;

import com.gunes.DunyaUlkeleri.dto.response.LeaderboardEntryResponse;

public interface LeaderboardService {
    List<LeaderboardEntryResponse> getCategoryLeaderboard(String category, String mode);
}

