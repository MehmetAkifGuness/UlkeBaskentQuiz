package com.gunes.DunyaUlkeleri.mapper;

import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;

public interface ConquestSessionStateMapper {
    ConquestSessionStateDto toStateDto(
            ConquestGameSession session,
            String lastEventMessage,
            String lastWinnerPlayerId,
            boolean roundLocked
    );
}
