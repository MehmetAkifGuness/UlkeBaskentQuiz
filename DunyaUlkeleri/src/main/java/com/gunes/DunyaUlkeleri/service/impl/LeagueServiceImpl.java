package com.gunes.DunyaUlkeleri.service.impl;

import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gunes.DunyaUlkeleri.config.LeagueProperties;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.util.league.LeagueSeason;
import com.gunes.DunyaUlkeleri.util.league.LeagueTier;
import com.gunes.DunyaUlkeleri.util.league.TrophyDeltaCalculator;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class LeagueServiceImpl implements LeagueService {

    private static final Logger log = LoggerFactory.getLogger(LeagueServiceImpl.class);
    private static final TrophyDeltaCalculator TROPHY_DELTA = new TrophyDeltaCalculator();

    private final UserRepository userRepository;
    private final LeagueProperties leagueProperties;

    @Override
    public int currentSeasonId() {
        return LeagueSeason.currentSeasonId();
    }

    @Override
    public void ensureSeason(User user) {
        if (user == null) return;
        final int current = currentSeasonId();
        if (user.getTrophySeason() != current) {
            user.setTrophySeason(current);
            user.setTrophies(leagueProperties.getResetTrophies());
        }
    }

    @Override
    public LeagueTier tierOf(int trophies) {
        return LeagueTier.fromTrophies(Math.max(0, trophies));
    }

    @Override
    public String leagueNameOf(int trophies) {
        return tierOf(trophies).displayName();
    }

    @Override
    @Transactional
    public void applyMatchResult(String winnerUsername, String loserUsername) {
        final String w = safeTrim(winnerUsername);
        final String l = safeTrim(loserUsername);
        if (w == null || l == null || w.isBlank() || l.isBlank()) return;
        if (w.equalsIgnoreCase(l)) return;

        Optional<User> winnerOpt = userRepository.findByUsername(w);
        Optional<User> loserOpt = userRepository.findByUsername(l);
        if (winnerOpt.isEmpty() || loserOpt.isEmpty()) return;

        User winner = winnerOpt.get();
        User loser = loserOpt.get();

        if (winner.isGuest() || loser.isGuest()) {
            log.info("Skipping trophies update (guest): winner={}, loser={}", w, l);
            return;
        }

        ensureSeason(winner);
        ensureSeason(loser);

        TrophyDeltaCalculator.TrophyDelta delta = TROPHY_DELTA.calculate(
                winner.getTrophies(),
                loser.getTrophies(),
                leagueProperties.getWinTrophies(),
                leagueProperties.getLossTrophies()
        );

        int winnerNext = winner.getTrophies() + delta.winnerGain();
        int loserNext = loser.getTrophies() - delta.loserLoss();

        winnerNext = Math.max(leagueProperties.getMinTrophies(), winnerNext);
        loserNext = Math.max(leagueProperties.getMinTrophies(), loserNext);

        winner.setTrophies(winnerNext);
        loser.setTrophies(loserNext);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}

