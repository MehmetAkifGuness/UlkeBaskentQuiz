package com.gunes.DunyaUlkeleri.service.impl;

import java.util.List;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;

import lombok.RequiredArgsConstructor;

/**
 * SRP: Handles cleanup/maintenance operations for {@link GameSession}.
 */
@Service
@RequiredArgsConstructor
public class GameSessionCleanupService {

    private final GameSessionRepository gameSessionRepository;

    public void abandonUnfinishedSessions(User user) {
        List<GameSession> abandonedSessions =
                gameSessionRepository.findByUserAndIsFinishedFalse(user);
        if (abandonedSessions.isEmpty()) return;

        for (GameSession abandoned : abandonedSessions) {
            abandoned.setFinished(true);
        }
        gameSessionRepository.saveAll(abandonedSessions);
    }
}
