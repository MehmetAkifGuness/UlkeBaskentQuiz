package com.gunes.DunyaUlkeleri.repository;

import java.util.List;
import java.util.Locale;
import java.util.Objects;

import org.springframework.stereotype.Repository;

import com.gunes.DunyaUlkeleri.entity.PlayableCountryMeta;

@Repository
public class FallbackConquestPlayableCountryRepository
        implements ConquestPlayableCountryRepository {

    private static final List<PlayableCountryMeta> FALLBACK = List.of(
            new PlayableCountryMeta("TR", "Türkiye", "Europe"),
            new PlayableCountryMeta("DE", "Almanya", "Europe"),
            new PlayableCountryMeta("FR", "Fransa", "Europe"),
            new PlayableCountryMeta("US", "Amerika Birleşik Devletleri", "North America"),
            new PlayableCountryMeta("BR", "Brezilya", "South America"),
            new PlayableCountryMeta("JP", "Japonya", "Asia"),
            new PlayableCountryMeta("CN", "Çin", "Asia"),
            new PlayableCountryMeta("EG", "Mısır", "Africa"),
            new PlayableCountryMeta("ZA", "Güney Afrika", "Africa"),
            new PlayableCountryMeta("AU", "Avustralya", "Oceania")
    );

    @Override
    public List<PlayableCountryMeta> findPlayableCountries(String continentFilter) {
        final String filter = normalizeContinentFilter(continentFilter);
        if ("ALL".equals(filter)) {
            return FALLBACK;
        }

        return FALLBACK.stream()
                .filter(c -> filter.equalsIgnoreCase(c.continent()))
                .toList();
    }

    @Override
    public PlayableCountryMeta getMetaOrDefault(String isoCode, String defaultContinent) {
        final String normalizedIso = normalizeUpper(isoCode);
        if (normalizedIso == null || normalizedIso.isBlank()) {
            return new PlayableCountryMeta(null, null, defaultContinent);
        }

        return FALLBACK.stream()
                .filter(c -> Objects.equals(c.isoCode(), normalizedIso))
                .findFirst()
                .orElse(new PlayableCountryMeta(normalizedIso, normalizedIso, defaultContinent));
    }

    private static String normalizeUpper(String value) {
        final String v = safeTrim(value);
        return v == null ? null : v.toUpperCase(Locale.ROOT);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static String normalizeContinentFilter(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "ALL";
        return v;
    }
}
