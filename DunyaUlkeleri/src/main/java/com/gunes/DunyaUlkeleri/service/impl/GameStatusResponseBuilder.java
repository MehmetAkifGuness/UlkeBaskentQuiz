package com.gunes.DunyaUlkeleri.service.impl;

import java.time.LocalDate;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

    private static final Logger log = LoggerFactory.getLogger(GameStatusResponseBuilder.class);

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

        final String mode = session.getGameMode() == null ? "MIXED" : session.getGameMode();

        List<Object[]> topUsers;
        if (isDaily) {
            topUsers = gameSessionRepository.findTop10DailyScores(
                    category,
                    LocalDate.now().atStartOfDay(),
                    PageRequest.of(0, 1)
            );
        } else {
            topUsers = gameSessionRepository.findTop10ByCategoryAndMode(
                    category,
                    mode,
                    PageRequest.of(0, 1)
            );
        }

        final int rowCount = (topUsers == null) ? 0 : topUsers.size();
        final Object[] top = (topUsers != null && !topUsers.isEmpty()) ? topUsers.get(0) : null;
        final String topUsername = (top != null && top.length > 0 && top[0] != null) ? top[0].toString() : null;
        final Integer topScore = (top != null && top.length > 1 && top[1] instanceof Number)
                ? ((Number) top[1]).intValue()
                : null;
        log.info(
                "ghost category={} mode={} daily={} rows={} topUser={} topScore={}",
                category,
                mode,
                isDaily,
                rowCount,
                topUsername,
                topScore
        );

        if (topUsers != null && !topUsers.isEmpty() && topScore != null && topScore > 0) {
            Object[] topPlayer = topUsers.get(0);
            response.setGhostName(topPlayer[0] == null ? null : topPlayer[0].toString());
            response.setGhostScore(topScore);
        } else {
            response.setGhostName("Rekor Yok");
            response.setGhostScore(0);
        }
    }
}
