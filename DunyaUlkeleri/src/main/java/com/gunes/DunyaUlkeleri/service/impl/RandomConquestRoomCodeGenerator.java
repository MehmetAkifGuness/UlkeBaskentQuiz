package com.gunes.DunyaUlkeleri.service.impl;

import java.security.SecureRandom;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.service.ConquestRoomCodeGenerator;

@Service
public class RandomConquestRoomCodeGenerator implements ConquestRoomCodeGenerator {

    private static final String ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    private final SecureRandom random = new SecureRandom();

    @Override
    public String generate() {
        // 6 karakterli büyük harf/rakam
        final StringBuilder sb = new StringBuilder(6);
        for (int i = 0; i < 6; i++) {
            sb.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}
