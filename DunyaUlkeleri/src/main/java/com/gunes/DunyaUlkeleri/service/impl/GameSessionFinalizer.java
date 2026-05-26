package com.gunes.DunyaUlkeleri.service.impl;

import java.time.LocalDate;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;

import lombok.RequiredArgsConstructor;

/**
 * SRP: Finalizes a finished {@link GameSession} by updating {@link User} aggregate statistics and
 * persisting both.
 */
@Service
@RequiredArgsConstructor
public class GameSessionFinalizer {

    private final UserRepository userRepository;
    private final GameSessionRepository gameSessionRepository;

    public void finalizeFinishedSession(GameSession session) {
        if (session == null) return;

        User user = session.getUser();
        if (user == null) {
            gameSessionRepository.save(session);
            return;
        }

        boolean isDaily = DailyChallengeService.DAILY_CATEGORY.equals(session.getCategory());

        updateUserStatistics(user, session, isDaily);

        userRepository.save(user);
        gameSessionRepository.save(session);
    }

    private void updateUserStatistics(User user, GameSession session, boolean isDaily) {
        String currentCategory = session.getCategory() == null ? "Dünya" : session.getCategory();
        String currentMode = session.getGameMode() == null ? "MIXED" : session.getGameMode();
        String mapKey = currentCategory + "_" + currentMode;

        int currentScore = session.getCurrentScore();
        int bestScore = user.getCategoryBestScores().getOrDefault(mapKey, 0);
        if (currentScore > bestScore) {
            user.getCategoryBestScores().put(mapKey, currentScore);
        }

        if (currentScore > user.getMaxWinStreak()) {
            user.setMaxWinStreak(currentScore);
        }
        user.setTotalGamesPlayed(user.getTotalGamesPlayed() + 1);
        user.setTotalMasteryPoints(user.getTotalMasteryPoints() + currentScore);

        if (isDaily) {
            user.setLastDailyDate(LocalDate.now());
        }
    }
}
