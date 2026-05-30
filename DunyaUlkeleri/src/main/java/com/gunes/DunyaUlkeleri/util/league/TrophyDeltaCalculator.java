package com.gunes.DunyaUlkeleri.util.league;

public final class TrophyDeltaCalculator {

    public record TrophyDelta(int winnerGain, int loserLoss) {}

    private static final int MIN_DELTA = 1;
    private static final int MAX_SWING = 10;
    private static final int DIFF_STEP = 250;

    public TrophyDelta calculate(int winnerTrophies, int loserTrophies, int baseWin, int baseLoss) {
        int safeBaseWin = Math.max(MIN_DELTA, baseWin);
        int safeBaseLoss = Math.max(MIN_DELTA, baseLoss);

        int w = Math.max(0, winnerTrophies);
        int l = Math.max(0, loserTrophies);

        int swing = clamp((l - w) / DIFF_STEP, -MAX_SWING, MAX_SWING);

        int win = Math.round((float) (safeBaseWin * winFactor(w))) + swing;
        int loss = safeBaseLoss + swing;

        win = clamp(win, MIN_DELTA, safeBaseWin + MAX_SWING);
        loss = clamp(loss, MIN_DELTA, safeBaseLoss + MAX_SWING);

        return new TrophyDelta(win, loss);
    }

    private static double winFactor(int trophies) {
        LeagueTier tier = LeagueTier.fromTrophies(Math.max(0, trophies));
        return switch (tier) {
            case BRONZE -> 1.00;
            case SILVER -> 0.97;
            case GOLD -> 0.94;
            case PLATINUM -> 0.91;
            case DIAMOND -> 0.88;
            case MASTER -> 0.85;
        };
    }

    private static int clamp(int v, int min, int max) {
        if (v < min) return min;
        if (v > max) return max;
        return v;
    }
}
