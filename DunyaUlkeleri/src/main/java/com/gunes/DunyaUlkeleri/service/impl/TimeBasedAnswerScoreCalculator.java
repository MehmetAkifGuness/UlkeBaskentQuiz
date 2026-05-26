package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.service.AnswerScoreCalculator;

@Service
public class TimeBasedAnswerScoreCalculator implements AnswerScoreCalculator {

    private static final int MAX_SCORE = 2000;
    private static final int MIN_SCORE = 200;
    private static final double MIN_TIME_SECONDS = 0.1;

    @Override
    public int calculateEarnedScore(double timeInSeconds) {
        double safeTime = timeInSeconds;
        if (safeTime < MIN_TIME_SECONDS) {
            safeTime = MIN_TIME_SECONDS;
        }

        int earnedScore = (int) Math.round(MAX_SCORE / safeTime);
        if (earnedScore > MAX_SCORE) {
            return MAX_SCORE;
        }
        if (earnedScore < MIN_SCORE) {
            return MIN_SCORE;
        }
        return earnedScore;
    }
}
