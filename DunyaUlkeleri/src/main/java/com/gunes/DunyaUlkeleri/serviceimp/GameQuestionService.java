package com.gunes.DunyaUlkeleri.serviceimp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Random;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;
import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.QuestionRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class GameQuestionService {

    private final QuestionRepository questionRepository;
    private final GameSessionRepository gameSessionRepository;
    private final DailyChallengeService dailyChallengeService;
    private final GameSessionFinalizer sessionFinalizer;
    private final GameStatusResponseBuilder responseBuilder;

    public GameStatusResponse buildResumeResponse(GameSession session, Question question) {
        boolean askForCapital = Objects.equals(session.getCurrentCorrectAnswer(), question.getCapitalName());

        List<String> options = new ArrayList<>();
        String questionText;

        if (askForCapital) {
            options.add(question.getCapitalName());
            options.addAll(questionRepository.findRandomWrongAnswers(question.getCapitalName()));
            questionText = question.getCountryName() + " ülkesinin başkenti neresidir?";
        } else {
            options.add(question.getCountryName());
            options.addAll(questionRepository.findRandomWrongCountries(question.getCountryName()));
            questionText = question.getCapitalName() + " şehri hangi ülkenin başkentidir?";
        }
        Collections.shuffle(options);

        // BUG ÇÖZÜMÜ: Oyuna devam edildiği anı "yeni soru sorulmuş" gibi kaydet ki zaman hesaplaması sapıtmasın!
        session.setLastQuestionTime(LocalDateTime.now());
        gameSessionRepository.save(session);

        GameStatusResponse response =
                responseBuilder.build(session, "Oyun Kaldığı Yerden Devam Ediyor...", false);
        response.setCountryName(question.getCountryName());
        response.setQuestionText(questionText);
        response.setOptions(options);

        if (DailyChallengeService.DAILY_CATEGORY.equals(session.getCategory())) {
            response.setMessage("Günün Görevi: Soru " + (session.getAskedQuestionIds().size() + 1) + "/10");
        }

        return response;
    }

    public GameStatusResponse generateNextQuestion(GameSession session) {
        boolean isDaily = DailyChallengeService.DAILY_CATEGORY.equals(session.getCategory());
        Question question = null;

        if (isDaily) {
            List<Question> dailyQuestions = dailyChallengeService.getTodayQuestions();
            for (Question q : dailyQuestions) {
                if (!session.getAskedQuestionIds().contains(q.getId())) {
                    question = q;
                    break;
                }
            }
        } else {
            Set<Long> askedIds = session.getAskedQuestionIds().isEmpty() ? Set.of(-1L) : session.getAskedQuestionIds();
            String category = (session.getCategory() == null || session.getCategory().isEmpty()) ? "Dünya" : session.getCategory();
            question = questionRepository.findRandomQuestionByCategory(category, askedIds).orElse(null);

            if (question == null && "ENDLESS".equals(session.getGameMode())) {
                session.getAskedQuestionIds().clear();
                askedIds = Set.of(-1L);
                question = questionRepository.findRandomQuestionByCategory(category, askedIds).orElse(null);
            }
        }

        if (question == null) {
            session.setFinished(true);

            if (!isDaily) {
                session.setCurrentScore(session.getCurrentScore() + 5000);
            }

            sessionFinalizer.finalizeFinishedSession(session);

            String msg = isDaily
                    ? "Günün Görevi Tamamlandı! Harika iş çıkardın."
                    : "TEBRİKLER! Bu kategorideki tüm ülkeleri bildiniz! (+5000 Bonus)";
            return responseBuilder.build(session, msg, true);
        }

        boolean askForCapital = true;
        if (isDaily) {
            long seed = LocalDate.now().toEpochDay() + question.getId();
            askForCapital = new Random(seed).nextBoolean();
        } else {
            String mode = session.getGameMode() == null ? "MIXED" : session.getGameMode();
            if ("COUNTRY_TO_CAPITAL".equals(mode)) {
                askForCapital = true;
            } else if ("CAPITAL_TO_COUNTRY".equals(mode)) {
                askForCapital = false;
            } else {
                askForCapital = Math.random() < 0.5;
            }
        }

        List<String> options = new ArrayList<>();
        String correctAnswer;
        String questionText;

        if (askForCapital) {
            correctAnswer = question.getCapitalName();
            options.add(correctAnswer);
            options.addAll(questionRepository.findRandomWrongAnswers(correctAnswer));
            questionText = question.getCountryName() + " ülkesinin başkenti neresidir?";
        } else {
            correctAnswer = question.getCountryName();
            options.add(correctAnswer);
            options.addAll(questionRepository.findRandomWrongCountries(correctAnswer));
            questionText = question.getCapitalName() + " şehri hangi ülkenin başkentidir?";
        }
        Collections.shuffle(options);

        session.setCurrentCorrectAnswer(correctAnswer);
        session.setCurrentQuestionId(question.getId());

        // GÜVENLİK YAMASI: Yeni sorunun sorulma zamanını kaydediyoruz (Hile önlemi)
        session.setLastQuestionTime(LocalDateTime.now());

        gameSessionRepository.save(session);

        GameStatusResponse response = responseBuilder.build(session, "Yeni Soru!", false);
        response.setCountryName(question.getCountryName());
        response.setQuestionText(questionText);
        response.setOptions(options);

        if (isDaily) {
            response.setMessage("Günün Görevi: Soru " + (session.getAskedQuestionIds().size() + 1) + "/10");
        }

        return response;
    }
}
