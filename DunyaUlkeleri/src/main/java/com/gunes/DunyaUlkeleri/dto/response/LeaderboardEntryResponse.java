package com.gunes.DunyaUlkeleri.dto.response;

import lombok.Data;

@Data
public class LeaderboardEntryResponse {
    private String username;
    private Integer score;
    private Integer avatarId;
    private String displayName;
    private boolean hasCustomAvatar;
}
