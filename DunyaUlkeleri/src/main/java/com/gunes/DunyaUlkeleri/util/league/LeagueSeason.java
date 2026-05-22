package com.gunes.DunyaUlkeleri.util.league;

import java.time.YearMonth;
import java.time.ZoneId;

public final class LeagueSeason {

    private LeagueSeason() {}

    /**
     * Returns season identifier in YYYYMM format (e.g. 202605).
     * Season changes automatically on the 1st of each month.
     */
    public static int currentSeasonId() {
        YearMonth ym = YearMonth.now(ZoneId.systemDefault());
        return (ym.getYear() * 100) + ym.getMonthValue();
    }
}

