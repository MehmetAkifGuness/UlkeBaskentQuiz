package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.service.ConquestRoomCodeGenerator;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

/**
 * SRP: Allocates a unique room code by combining a code generator with the current session store.
 */
@Service
@RequiredArgsConstructor
public class ConquestRoomCodeAllocator {

    private final ConquestRoomCodeGenerator roomCodeGenerator;
    private final ConquestSessionStore sessionStore;

    public String allocateUniqueRoomCode() {
        String roomCode = null;
        for (int attempt = 0; attempt < 20; attempt++) {
            final String candidate = roomCodeGenerator.generate();
            if (!sessionStore.isRoomCodeTaken(candidate)) {
                roomCode = candidate;
                break;
            }
        }

        if (roomCode == null) {
            final String candidate = roomCodeGenerator.fallback();
            if (!sessionStore.isRoomCodeTaken(candidate)) {
                roomCode = candidate;
            }
        }

        if (roomCode == null) {
            throw new AppException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "ROOM_CODE_GENERATION_FAILED",
                    "Oda kodu üretilemedi. Lütfen tekrar deneyin."
            );
        }

        return roomCode;
    }
}
