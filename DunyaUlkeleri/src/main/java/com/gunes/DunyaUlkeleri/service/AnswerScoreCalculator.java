package com.gunes.DunyaUlkeleri.service;

/**
 * Verilen cevap süresine göre kazanılacak puanı hesaplar.
 *
 * <p>Not: Hesaplama tamamen server-side olmalı ve client input'u sadece sinyal
 * olarak kullanılmalıdır.</p>
 */
public interface AnswerScoreCalculator {
    int calculateEarnedScore(double timeInSeconds);
}

