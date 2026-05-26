package com.gunes.DunyaUlkeleri.service.impl;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.entity.ConquestRound;
import com.gunes.DunyaUlkeleri.entity.PlayableCountryMeta;
import com.gunes.DunyaUlkeleri.repository.ConquestPlayableCountryRepository;
import com.gunes.DunyaUlkeleri.service.ConquestRoundService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestRoundServiceImpl implements ConquestRoundService {

    private static final Logger log = LoggerFactory.getLogger(ConquestRoundServiceImpl.class);
    private static final int INITIAL_LIVES = 3;

    private final SecureRandom random = new SecureRandom();
    private final ConquestPlayableCountryRepository playableCountryRepository;

    @Override
    public boolean areAllPlayersOutOfLives(ConquestGameSession session) {
        if (session == null) return false;

        final List<ConquestPlayer> players = Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .toList();
        if (players.isEmpty()) return false;
        return players.stream().allMatch(p -> p.getRemainingLives() <= 0);
    }

    @Override
    public void pickNextTargetCountry(ConquestGameSession session, String lastWinnerPlayerId) {
        if (session == null) return;

        final List<String> remaining = session.getPlayableIsoCodes().stream()
                .filter(Objects::nonNull)
                .map(v -> v.trim().toUpperCase(Locale.ROOT))
                .filter(v -> !session.isCountryConquered(v))
                .distinct()
                .sorted(Comparator.naturalOrder())
                .collect(Collectors.toCollection(ArrayList::new));

        if (remaining.isEmpty()) {
            session.setStatus(ConquestGameStatus.FINISHED);
            session.setCurrentRound(null);
            session.touch();
            return;
        }

        Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .forEach(p -> p.setRemainingLives(INITIAL_LIVES));

        final String nextIso = remaining.get(random.nextInt(remaining.size()));
        final PlayableCountryMeta meta = playableCountryRepository.getMetaOrDefault(
                nextIso,
                session.getSelectedContinentFilter()
        );

        final int nextRoundNumber = Optional.ofNullable(session.getCurrentRound())
                .map(ConquestRound::getRoundNumber)
                .orElse(0) + 1;

        final ConquestRound round = new ConquestRound();
        round.setRoundNumber(nextRoundNumber);
        round.setTargetIsoCode(meta.isoCode());
        round.setTargetCountryName(meta.name());
        round.setLocked(false);
        round.setWinnerPlayerId(null);
        round.setStartedAt(Instant.now());
        round.setFinishedAt(null);

        session.setCurrentRound(round);
        session.setUpdatedAt(Instant.now());

        log.info(
                "Next round picked: sessionId={}, round={}, target={}",
                session.getSessionId(),
                nextRoundNumber,
                meta.isoCode()
        );
    }

    @Override
    public void finishRound(ConquestGameSession session, ConquestPlayer winner, ConquestRound round) {
        if (round == null || winner == null || session == null) return;
        round.setLocked(true);
        round.setWinnerPlayerId(winner.getPlayerId());
        round.setFinishedAt(Instant.now());

        winner.setScore(winner.getScore() + 1);
        winner.setConqueredCount(winner.getConqueredCount() + 1);

        session.markCountryConquered(round.getTargetIsoCode(), winner);

        log.info(
                "Round won: sessionId={}, round={}, winnerPlayerId={}, iso={}",
                session.getSessionId(),
                round.getRoundNumber(),
                winner.getPlayerId(),
                round.getTargetIsoCode()
        );
    }
}
