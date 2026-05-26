package com.gunes.DunyaUlkeleri.service.impl;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;

/**
 * Calculates winner/loser for a duel session and ensures trophies are applied at most once.
 * This class never touches the database; callers may apply the returned result after releasing locks.
 */
@Service
public class DuelLeagueAwarder {

    public record MatchResult(String winnerUsername, String loserUsername) {}

    public Optional<MatchResult> tryMarkFinished(DuelGameSession session) {
        if (session == null) return Optional.empty();
        synchronized (session) {
            if (session.isTrophiesApplied()) return Optional.empty();

            List<DuelPlayer> players = Optional.ofNullable(session.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .filter(Objects::nonNull)
                    .toList();

            if (players.size() != 2) {
                session.setTrophiesApplied(true);
                return Optional.empty();
            }

            DuelPlayer p1 = players.get(0);
            DuelPlayer p2 = players.get(1);
            String u1 = safeTrim(p1.getUsername());
            String u2 = safeTrim(p2.getUsername());
            if (u1 == null || u2 == null || u1.isBlank() || u2.isBlank() || u1.equalsIgnoreCase(u2)) {
                session.setTrophiesApplied(true);
                return Optional.empty();
            }

            int s1 = p1.getScore();
            int s2 = p2.getScore();
            if (s1 == s2) {
                session.setTrophiesApplied(true);
                return Optional.empty();
            }

            String winner = s1 > s2 ? u1 : u2;
            String loser = s1 > s2 ? u2 : u1;
            session.setTrophiesApplied(true);
            return Optional.of(new MatchResult(winner, loser));
        }
    }

    public Optional<MatchResult> tryMarkLeave(DuelGameSession session, String leavingPlayerId) {
        if (session == null) return Optional.empty();
        final String leavingId = safeTrim(leavingPlayerId);
        if (leavingId == null || leavingId.isBlank()) return Optional.empty();

        synchronized (session) {
            if (session.isTrophiesApplied()) return Optional.empty();

            List<DuelPlayer> players = Optional.ofNullable(session.getPlayers())
                    .orElseGet(List::of)
                    .stream()
                    .filter(Objects::nonNull)
                    .toList();

            if (players.size() != 2) {
                session.setTrophiesApplied(true);
                return Optional.empty();
            }

            DuelPlayer leaving = players.stream()
                    .filter(p -> leavingId.equals(safeTrim(p.getPlayerId())))
                    .findFirst()
                    .orElse(null);
            DuelPlayer remaining = players.stream()
                    .filter(p -> !leavingId.equals(safeTrim(p.getPlayerId())))
                    .findFirst()
                    .orElse(null);

            if (leaving == null || remaining == null) {
                session.setTrophiesApplied(true);
                return Optional.empty();
            }

            String loser = safeTrim(leaving.getUsername());
            String winner = safeTrim(remaining.getUsername());
            if (winner == null || loser == null || winner.isBlank() || loser.isBlank() || winner.equalsIgnoreCase(loser)) {
                session.setTrophiesApplied(true);
                return Optional.empty();
            }

            session.setTrophiesApplied(true);
            return Optional.of(new MatchResult(winner, loser));
        }
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}

