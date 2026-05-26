package com.gunes.DunyaUlkeleri.service.impl;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
import com.gunes.DunyaUlkeleri.repository.QuestionRepository;

import lombok.RequiredArgsConstructor;

/**
 * SRP: Daily challenge business rules (eligibility, streak tracking, deterministic question list).
 */
@Service
@RequiredArgsConstructor
public class DailyChallengeService {

    public static final String DAILY_CATEGORY = "DailyChallenge";
    private static final int DAILY_QUESTION_COUNT = 10;

    private final QuestionRepository questionRepository;

    public boolean isDailyCategory(String category) {
        return DAILY_CATEGORY.equals(category);
    }

    public void validateAndConsumeDailyAttempt(User user) {
        LocalDate today = LocalDate.now();
        LocalDate lastDaily = user.getLastDailyDate();

        if (lastDaily != null && lastDaily.equals(today)) {
            throw AppException.conflict(
                    "DAILY_ALREADY_PLAYED",
                    "Bugün zaten Günün Görevi'ni başlattın veya tamamladın. Yarın tekrar deneyebilirsin."
            );
        }

        Integer streak = user.getDailyStreak();
        int nextStreak;
        if (lastDaily == null) {
            nextStreak = 1;
        } else if (lastDaily.equals(today.minusDays(1))) {
            nextStreak = (streak == null || streak <= 0) ? 2 : streak + 1;
        } else {
            nextStreak = 1;
        }

        user.setDailyStreak(nextStreak);
        user.setLastDailyDate(today);
    }

    public List<Question> getTodayQuestions() {
        List<Question> allQuestions = questionRepository.findAllByOrderByCountryNameAsc();
        long seed = LocalDate.now().toEpochDay();
        Collections.shuffle(allQuestions, new Random(seed));
        return allQuestions.stream()
                .limit(DAILY_QUESTION_COUNT)
                .collect(Collectors.toList());
    }
}
