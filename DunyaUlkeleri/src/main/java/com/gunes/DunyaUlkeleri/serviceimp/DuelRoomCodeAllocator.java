package com.gunes.DunyaUlkeleri.serviceimp;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.repository.DuelSessionStore;
import com.gunes.DunyaUlkeleri.service.ConquestRoomCodeGenerator;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DuelRoomCodeAllocator {

    private final ConquestRoomCodeGenerator roomCodeGenerator;
    private final DuelSessionStore sessionStore;

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

