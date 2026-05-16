package com.gunes.DunyaUlkeleri.entity;

import java.util.Locale;

public record PlayableCountryMeta(String isoCode, String name, String continent) {
    public PlayableCountryMeta {
        isoCode = normalizeUpper(isoCode);
        name = safeTrim(name);
        continent = safeTrim(continent);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static String normalizeUpper(String isoCode) {
        final String trimmed = safeTrim(isoCode);
        return trimmed == null ? null : trimmed.toUpperCase(Locale.ROOT);
    }
}
