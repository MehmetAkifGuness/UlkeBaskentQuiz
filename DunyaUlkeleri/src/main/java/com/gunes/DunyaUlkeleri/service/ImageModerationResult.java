package com.gunes.DunyaUlkeleri.service;

import java.util.Map;

public record ImageModerationResult(
        boolean allowed,
        boolean flagged,
        Map<String, Boolean> categories
) {
    public static ImageModerationResult allowAll() {
        return new ImageModerationResult(true, false, Map.of());
    }
}
