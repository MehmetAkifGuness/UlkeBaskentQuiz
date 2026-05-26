package com.gunes.DunyaUlkeleri.service.impl;

import java.time.Duration;
import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gunes.DunyaUlkeleri.dto.request.GameAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;
import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.QuestionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.AnswerScoreCalculator;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class GameAnswerService {

    private static final double MAX_ALLOWED_CLIENT_SERVER_TIME_DRIFT_SECONDS = 3.0;

    private final GameSessionRepository gameSessionRepository;
    private final QuestionRepository questionRepository;
    private final UserRepository userRepository;
    private final AnswerScoreCalculator answerScoreCalculator;
    private final GameSessionFinalizer sessionFinalizer;
    private final GameStatusResponseBuilder responseBuilder;
    private final GameQuestionService gameQuestionService;

    public GameStatusResponse submitAnswer(GameAnswerRequest request, String username) {
        GameSession session = gameSessionRepository.findById(request.getSessionId())
                .orElseThrow(() -> AppException.notFound("SESSION_NOT_FOUND", "Oyun oturumu bulunamadı."));

        if (!session.getUser().getUsername().equals(username)) {
            throw AppException.forbidden("SESSION_FORBIDDEN", "Bu oyun oturumu size ait değil.");
        }

        if (session.isFinished()) {
            return responseBuilder.build(session, "Bu oyun zaten bitmiş!", true);
        }

        // Güvenlik: Anti-Spam / Anti-Bot Kontrolü (0.1 saniye)
        if (session.getLastQuestionTime() != null) {
            long timeElapsedMillis = Duration.between(session.getLastQuestionTime(), LocalDateTime.now()).toMillis();
            if (timeElapsedMillis < 100) {
                throw AppException.forbidden(
                        "SUSPICIOUS_ACTIVITY",
                        "Çok hızlı cevap gönderildi. Lütfen biraz daha yavaş deneyin."
                );
            }
        }

        String previousCorrectAnswer = session.getCurrentCorrectAnswer();
        Long previousQuestionId = session.getCurrentQuestionId();

        boolean isCorrect = request.getCapitalGuess().trim().equalsIgnoreCase(previousCorrectAnswer);
        boolean isDaily = DailyChallengeService.DAILY_CATEGORY.equals(session.getCategory());

        if (isCorrect) {
            applyCorrectAnswer(session, request, previousQuestionId);
        } else {
            applyWrongAnswer(session, isDaily, previousQuestionId);
        }

        if (isGameFinished(session, isDaily)) {
            session.setFinished(true);
            sessionFinalizer.finalizeFinishedSession(session);

            GameStatusResponse response = responseBuilder.build(
                    session,
                    "Oyun Bitti! Toplam Skor: " + session.getCurrentScore(),
                    true
            );
            response.setLastCorrectAnswer(previousCorrectAnswer);
            response.setLastAnswerCorrect(isCorrect);
            return response;
        }

        gameSessionRepository.save(session);

        GameStatusResponse response = gameQuestionService.generateNextQuestion(session);
        response.setLastCorrectAnswer(previousCorrectAnswer);
        response.setLastAnswerCorrect(isCorrect);
        return response;
    }

    private void applyCorrectAnswer(
            GameSession session,
            GameAnswerRequest request,
            Long previousQuestionId
    ) {
        double clientTime = request.getTimeTaken();

        // Sunucunun kendi kronometresiyle geçen süreyi hesapla
        long actualElapsedMillis = Duration.between(session.getLastQuestionTime(), LocalDateTime.now()).toMillis();
        double serverTimeInSeconds = Math.max(0.1, (actualElapsedMillis - 500) / 1000.0);

        // Zaman bükme hilesi önlemi
        double finalTimeInSeconds = clientTime;
        if (serverTimeInSeconds - clientTime > MAX_ALLOWED_CLIENT_SERVER_TIME_DRIFT_SECONDS) {
            finalTimeInSeconds = serverTimeInSeconds;
        }

        int earnedScore = answerScoreCalculator.calculateEarnedScore(finalTimeInSeconds);

        log.debug(
                "Gelen Süre: {} sn | Gerçek Süre: {} sn | Kazanılan Puan: {}",
                clientTime,
                serverTimeInSeconds,
                earnedScore
        );

        session.setCurrentScore(session.getCurrentScore() + earnedScore);

        if (previousQuestionId != null) {
            session.getAskedQuestionIds().add(previousQuestionId);
        }
    }

    private void applyWrongAnswer(
            GameSession session,
            boolean isDaily,
            Long previousQuestionId
    ) {
        Question currentQuestion = questionRepository.findById(session.getCurrentQuestionId()).orElse(null);
        if (currentQuestion != null && session.getUser() != null) {
            session.getUser().getFailedQuestions().add(currentQuestion);
            userRepository.save(session.getUser());
        }

        if (isDaily) {
            if (previousQuestionId != null) {
                session.getAskedQuestionIds().add(previousQuestionId);
            }
            return;
        }

        if ("ENDLESS".equals(session.getGameMode())) {
            session.setRemainingLives(0);
        } else {
            session.setRemainingLives(session.getRemainingLives() - 1);
        }
    }

    private boolean isGameFinished(GameSession session, boolean isDaily) {
        if (isDaily) {
            return session.getAskedQuestionIds().size() >= 10;
        }
        return session.getRemainingLives() <= 0;
    }
}
