package com.gunes.DunyaUlkeleri.service.impl;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelRound;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.repository.QuestionRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelRoundService {

    private static final Duration ROUND_TIMEOUT = Duration.ofSeconds(20);

    private final QuestionRepository questionRepository;

    public void startFirstRound(DuelGameSession session) {
        startNextRound(session);
    }

    public void startNextRound(DuelGameSession session) {
        if (session == null) return;

        session.setLastAnsweredPlayerId(null);
        session.setLastAnswerCorrect(null);
        session.setLastAnsweredRoundNumber(null);

        final int nextRoundNumber = session.getCurrentRound() == null
                ? 1
                : (session.getCurrentRound().getRoundNumber() + 1);
        if (nextRoundNumber > session.getMaxRounds()) {
            session.setStatus(DuelGameStatus.FINISHED);
            session.setCurrentRound(null);
            session.touch();
            return;
        }

        final Question question = pickQuestion(session);
        if (question == null) {
            session.setStatus(DuelGameStatus.FINISHED);
            session.setCurrentRound(null);
            session.touch();
            return;
        }
        session.getAskedQuestionIds().add(question.getId());

        final boolean askForCapital = shouldAskForCapital(session.getMode());

        final String correctAnswer;
        final String questionText;
        final List<String> options = new ArrayList<>();

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

        final DuelRound round = new DuelRound();
        round.setRoundNumber(nextRoundNumber);
        round.setQuestionId(question.getId());
        round.setQuestionText(questionText);
        round.setOptions(options);
        round.setCorrectAnswer(correctAnswer);
        round.setLocked(false);
        round.setWinnerPlayerId(null);
        round.setStartedAt(Instant.now());
        round.setDeadlineAt(round.getStartedAt().plus(ROUND_TIMEOUT));

        session.setCurrentRound(round);
        session.setStatus(DuelGameStatus.STARTED);
        session.touch();
    }

    public boolean isRoundExpired(DuelRound round) {
        if (round == null) return false;
        if (round.isLocked()) return false;
        if (round.getDeadlineAt() == null) return false;
        return Instant.now().isAfter(round.getDeadlineAt());
    }

    private Question pickQuestion(DuelGameSession session) {
        final String category = normalizeCategory(session == null ? null : session.getCategory());
        final Set<Long> askedIds = (session == null || session.getAskedQuestionIds().isEmpty())
                ? Set.of(-1L)
                : session.getAskedQuestionIds();

        return questionRepository.findRandomQuestionByCategory(category, askedIds).orElse(null);
    }

    private static boolean shouldAskForCapital(String mode) {
        final String m = mode == null ? "MIXED" : mode.trim().toUpperCase(Locale.ROOT);
        if ("COUNTRY_TO_CAPITAL".equals(m)) return true;
        if ("CAPITAL_TO_COUNTRY".equals(m)) return false;
        return Math.random() < 0.5;
    }

    private static String normalizeCategory(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "Dünya";
        return v;
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}

