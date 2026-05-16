package com.gunes.DunyaUlkeleri.service;

import java.util.List;

import com.gunes.DunyaUlkeleri.dto.response.DictionaryResponse;

public interface DictionaryQueryService {
    List<DictionaryResponse> getDictionary();
}

