package com.gunes.DunyaUlkeleri.entity;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import lombok.Data;

@Data
public class DuelGameSession {
    private String sessionId;
    private String roomCode;
    private DuelGameStatus status;
    private String category;
    private String mode;
    private String hostPlayerId;
    private boolean quickMatch;
    private String matchmakingKey;
    private boolean trophiesApplied;

    private int maxRounds = 5;
    private Set<Long> askedQuestionIds = new HashSet<>();

    private List<DuelPlayer> players = new ArrayList<>();
    private DuelRound currentRound;

    private Instant createdAt;
    private Instant updatedAt;

    public void touch() {
        this.updatedAt = Instant.now();
    }

    public DuelPlayer getPlayer(String playerId) {
        if (playerId == null) return null;
        return players.stream()
                .filter(p -> playerId.equals(p.getPlayerId()))
                .findFirst()
                .orElse(null);
    }

    public void addPlayer(DuelPlayer player) {
        if (player == null || player.getPlayerId() == null) return;
        if (players.stream().anyMatch(p -> player.getPlayerId().equals(p.getPlayerId()))) return;
        players.add(player);
        touch();
    }

    public void removePlayer(String playerId) {
        if (playerId == null) return;
        players.removeIf(p -> playerId.equals(p.getPlayerId()));
        touch();
    }
}

