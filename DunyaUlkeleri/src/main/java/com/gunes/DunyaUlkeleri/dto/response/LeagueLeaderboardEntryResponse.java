package com.gunes.DunyaUlkeleri.dto.response;

import lombok.Data;

@Data
public class LeagueLeaderboardEntryResponse {
    private int rank;
    private String username;
    private int trophies;
    private String league;
    private Integer avatarId;
    private boolean hasCustomAvatar;
    private boolean currentUser;
}
