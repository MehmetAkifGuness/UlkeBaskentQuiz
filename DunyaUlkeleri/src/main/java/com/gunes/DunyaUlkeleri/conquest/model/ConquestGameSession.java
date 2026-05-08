package com.gunes.DunyaUlkeleri.conquest.model;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import lombok.Data;

@Data
public class ConquestGameSession {
    private String sessionId;
    private String roomCode;
    private ConquestGameStatus status;
    private String selectedContinentFilter;

    private List<ConquestPlayer> players = new ArrayList<>();

    // key = isoCode, value = playerId
    private Map<String, String> conqueredCountries = new ConcurrentHashMap<>();

    // key = isoCode, value = colorHex
    private Map<String, String> conqueredCountryColors = new ConcurrentHashMap<>();

    private ConquestRound currentRound;
    private List<String> playableIsoCodes = new ArrayList<>();

    private Instant createdAt;
    private Instant updatedAt;

    public void touch() {
        this.updatedAt = Instant.now();
    }

    public void addPlayer(ConquestPlayer player) {
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

    public ConquestPlayer getPlayer(String playerId) {
        if (playerId == null) return null;
        return players.stream()
                .filter(p -> playerId.equals(p.getPlayerId()))
                .findFirst()
                .orElse(null);
    }

    public boolean isCountryConquered(String isoCode) {
        if (isoCode == null) return false;
        return conqueredCountries.containsKey(isoCode.trim().toUpperCase());
    }

    public void markCountryConquered(String isoCode, ConquestPlayer player) {
        if (isoCode == null || player == null) return;
        final String key = isoCode.trim().toUpperCase();
        conqueredCountries.putIfAbsent(key, player.getPlayerId());
        conqueredCountryColors.putIfAbsent(key, player.getColorHex());
        touch();
    }

    public boolean canStart() {
        return status == ConquestGameStatus.WAITING && players.size() >= 1;
    }

    public boolean isFinished() {
        if (playableIsoCodes == null || playableIsoCodes.isEmpty()) {
            return status == ConquestGameStatus.FINISHED;
        }
        return playableIsoCodes.stream().allMatch(this::isCountryConquered);
    }
}
