package com.gunes.DunyaUlkeleri.repository;

import java.util.List;

import com.gunes.DunyaUlkeleri.entity.PlayableCountryMeta;

public interface ConquestPlayableCountryRepository {
    List<PlayableCountryMeta> findPlayableCountries(String continentFilter);

    PlayableCountryMeta getMetaOrDefault(String isoCode, String defaultContinent);

    default List<String> resolvePlayableIsoCodes(String continentFilter) {
        return findPlayableCountries(continentFilter).stream()
                .map(PlayableCountryMeta::isoCode)
                .filter(v -> v != null && !v.isBlank())
                .distinct()
                .toList();
    }
}
