package com.gunes.DunyaUlkeleri.dto.response;

import java.util.List;

import lombok.Data;

@Data
public class LeagueLeaderboardResponse {
    private int season;
    private long totalPlayers;
    private List<LeagueLeaderboardEntryResponse> topPlayers;
    private LeagueLeaderboardEntryResponse currentUser;
}
