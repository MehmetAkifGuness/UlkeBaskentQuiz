package com.gunes.DunyaUlkeleri.service;
import java.util.List;

import com.gunes.DunyaUlkeleri.dto.request.GameAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.DictionaryResponse;
import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;

//oyuna başla butonuna basınca burası tetiklenir ve oyun bitene kadar çalışır
public interface GameService {

    // 🚨 YENİ: mode parametresi eklendi
    GameStatusResponse startGame(String username , String category, String mode);

    GameStatusResponse submitAnswer(GameAnswerRequest request, String username);

    List<DictionaryResponse> getDictionary();
}