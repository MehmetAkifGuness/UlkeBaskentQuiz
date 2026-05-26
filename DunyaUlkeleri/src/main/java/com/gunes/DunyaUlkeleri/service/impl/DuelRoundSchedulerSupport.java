package com.gunes.DunyaUlkeleri.service.impl;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ScheduledFuture;

import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.entity.DuelRound;

final class DuelRoundSchedulerSupport {

    private DuelRoundSchedulerSupport() {}

    static void cancel(ScheduledFuture<?> future) {
        if (future == null) return;
        try {
            future.cancel(false);
        } catch (Exception ignored) {
            // ignore
        }
    }

    static void markMissingAnswers(DuelRound round, List<DuelPlayer> players) {
        if (round == null) return;
        List<DuelPlayer> safePlayers = Optional.ofNullable(players).orElseGet(List::of);
        for (DuelPlayer p : safePlayers) {
            if (p == null || safeTrim(p.getPlayerId()) == null) continue;
            if (round.getSelectedByPlayerId().containsKey(p.getPlayerId())) continue;
            round.getSelectedByPlayerId().put(p.getPlayerId(), "");
            round.getTimeTakenMsByPlayerId().put(p.getPlayerId(), computeTimeTakenMs(round));
        }
    }

    static boolean recordAnswer(DuelRound round, String playerId, String selectedOption) {
        final String pid = safeTrim(playerId);
        if (round == null || pid == null || pid.isBlank()) return false;
        final String selected = safeTrim(selectedOption);
        round.getSelectedByPlayerId().put(pid, selected == null ? "" : selected);
        round.getTimeTakenMsByPlayerId().put(pid, computeTimeTakenMs(round));
        return selected != null
                && safeTrim(round.getCorrectAnswer()) != null
                && selected.equalsIgnoreCase(round.getCorrectAnswer().trim());
    }

    static String keyOf(DuelRound round) {
        if (round == null) return "";
        return (round.getQuestionId() == null ? "-" : round.getQuestionId().toString()) + ":" + round.getRoundNumber();
    }

    static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static long computeTimeTakenMs(DuelRound round) {
        if (round == null || round.getStartedAt() == null) return 0;
        long ms = Duration.between(round.getStartedAt(), Instant.now()).toMillis();
        if (ms < 0) ms = 0;
        return ms;
    }
}

