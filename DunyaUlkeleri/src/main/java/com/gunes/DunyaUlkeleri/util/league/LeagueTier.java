package com.gunes.DunyaUlkeleri.util.league;

import java.util.Arrays;
import java.util.Comparator;

public enum LeagueTier {
    BRONZE(0, "Bronz"),
    SILVER(1000, "Gümüş"),
    GOLD(2000, "Altın"),
    PLATINUM(3000, "Platin"),
    DIAMOND(4000, "Elmas"),
    MASTER(5000, "Usta");

    private final int minTrophies;
    private final String displayName;

    LeagueTier(int minTrophies, String displayName) {
        this.minTrophies = minTrophies;
        this.displayName = displayName;
    }

    public int minTrophies() {
        return minTrophies;
    }

    public String displayName() {
        return displayName;
    }

    public static LeagueTier fromTrophies(int trophies) {
        return Arrays.stream(values())
                .filter(t -> trophies >= t.minTrophies)
                .max(Comparator.comparingInt(LeagueTier::minTrophies))
                .orElse(BRONZE);
    }
}

