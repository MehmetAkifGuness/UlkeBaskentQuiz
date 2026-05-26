package com.gunes.DunyaUlkeleri.service.impl;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;
import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.QuestionRepository;

import lombok.RequiredArgsConstructor;

/**
 * SRP: Builds a {@link GameStatusResponse} from a {@link GameSession} by enriching it with
 * leaderboard ("ghost") and question counters.
 */
@Service
@RequiredArgsConstructor
public class GameStatusResponseBuilder {

    private final QuestionRepository questionRepository;
    private final GameSessionRepository gameSessionRepository;

    public GameStatusResponse build(GameSession session, String message, boolean isFinished) {
        GameStatusResponse response = new GameStatusResponse();
        response.setSessionId(session.getId());
        response.setCurrentScore(session.getCurrentScore());
        response.setRemainingLives(session.getRemainingLives());
        response.setMessage(message);
        response.setFinished(isFinished);

        enrichTotalsAndGhost(session, response);
        return response;
    }

    private void enrichTotalsAndGhost(GameSession session, GameStatusResponse response) {
        String category = session.getCategory() == null ? "Dünya" : session.getCategory();
        boolean isDaily = "DailyChallenge".equals(category);

        int totalQuestions;
        if (isDaily) {
            totalQuestions = 10;
        } else if ("Dünya".equals(category)) {
            totalQuestions = (int) questionRepository.count();
        } else {
            totalQuestions = questionRepository.findByContinent(category).size();
        }

        int remainingQuestions = totalQuestions - session.getAskedQuestionIds().size();
        response.setTotalQuestions(totalQuestions);
        response.setRemainingQuestions(remainingQuestions);

        List<Object[]> topUsers;
        if (isDaily) {
            topUsers = gameSessionRepository.findTop10DailyScores(
                    category,
                    LocalDate.now().atStartOfDay(),
                    PageRequest.of(0, 1)
            );
        } else {
            String mode = session.getGameMode() == null ? "MIXED" : session.getGameMode();
            topUsers = gameSessionRepository.findTop10ByCategoryAndMode(
                    category,
                    mode,
                    PageRequest.of(0, 1)
            );
        }

        if (topUsers != null
                && !topUsers.isEmpty()
                && topUsers.get(0)[1] != null
                && ((Integer) topUsers.get(0)[1]) > 0) {
            Object[] topPlayer = topUsers.get(0);
            response.setGhostName((String) topPlayer[0]);
            response.setGhostScore((Integer) topPlayer[1]);
        } else {
            response.setGhostName("Rekor Yok");
            response.setGhostScore(0);
        }
    }
}
