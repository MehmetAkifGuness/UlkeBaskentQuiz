package com.gunes.DunyaUlkeleri.util.league;

import java.time.YearMonth;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;

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

    public static int monthsBetween(int fromSeasonId, int toSeasonId) {
        if (fromSeasonId <= 0 || fromSeasonId >= toSeasonId) return 0;
        YearMonth from = YearMonth.of(fromSeasonId / 100, fromSeasonId % 100);
        YearMonth to = YearMonth.of(toSeasonId / 100, toSeasonId % 100);
        return Math.max(0, (int) ChronoUnit.MONTHS.between(from, to));
    }

    public static int daysRemainingInCurrentSeason() {
        YearMonth current = YearMonth.now(ZoneId.systemDefault());
        return (int) ChronoUnit.DAYS.between(
                java.time.LocalDate.now(ZoneId.systemDefault()),
                current.plusMonths(1).atDay(1)
        );
    }
}
