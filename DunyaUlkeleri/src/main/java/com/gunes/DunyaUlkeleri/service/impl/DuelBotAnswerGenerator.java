package com.gunes.DunyaUlkeleri.service.impl;

import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.concurrent.ThreadLocalRandom;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.entity.DuelRound;

@Service
public class DuelBotAnswerGenerator {

    public record BotAnswer(String selectedOption, long timeTakenMs) {}

    private record BotProfile(double correctProbability, long minTimeMs, long maxTimeMs) {}

    public BotAnswer generate(DuelRound round, String difficulty) {
        BotProfile profile = profileOf(difficulty);
        if (round == null) return new BotAnswer("", profile.minTimeMs);

        final String correct = safeTrim(round.getCorrectAnswer());
        final List<String> options = (round.getOptions() == null ? List.<String>of() : round.getOptions())
                .stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();

        final long timeTakenMs = randomBetween(profile.minTimeMs, profile.maxTimeMs);

        final boolean chooseCorrect = correct != null && !correct.isBlank()
                && ThreadLocalRandom.current().nextDouble() < profile.correctProbability;
        if (chooseCorrect) {
            return new BotAnswer(correct, timeTakenMs);
        }

        final List<String> wrong = options.stream()
                .filter(o -> correct == null || !o.equalsIgnoreCase(correct))
                .toList();
        if (!wrong.isEmpty()) {
            return new BotAnswer(wrong.get(ThreadLocalRandom.current().nextInt(wrong.size())), timeTakenMs);
        }

        if (!options.isEmpty()) {
            return new BotAnswer(options.get(ThreadLocalRandom.current().nextInt(options.size())), timeTakenMs);
        }

        return new BotAnswer(correct == null ? "" : correct, timeTakenMs);
    }

    private static BotProfile profileOf(String difficulty) {
        final String d = safeTrim(difficulty);
        final String key = d == null ? "" : d.toUpperCase(Locale.ROOT);
        if ("EASY".equals(key) || "KOLAY".equals(key)) return new BotProfile(0.45, 2400, 8200);
        if ("HARD".equals(key) || "ZOR".equals(key)) return new BotProfile(0.90, 650, 2200);
        return new BotProfile(0.65, 1200, 5500);
    }

    private static long randomBetween(long minInclusive, long maxInclusive) {
        long min = Math.min(minInclusive, maxInclusive);
        long max = Math.max(minInclusive, maxInclusive);
        if (min == max) return min;
        return ThreadLocalRandom.current().nextLong(min, max + 1);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}
