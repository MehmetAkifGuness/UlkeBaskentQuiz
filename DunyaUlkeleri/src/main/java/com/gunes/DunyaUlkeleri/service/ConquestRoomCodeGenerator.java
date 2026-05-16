package com.gunes.DunyaUlkeleri.service;

public interface ConquestRoomCodeGenerator {
    String generate();

    default String fallback() {
        return java.util.UUID.randomUUID()
                .toString()
                .replace("-", "")
                .substring(0, 6)
                .toUpperCase(java.util.Locale.ROOT);
    }
}
