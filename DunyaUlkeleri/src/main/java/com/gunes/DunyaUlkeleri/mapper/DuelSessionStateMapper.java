package com.gunes.DunyaUlkeleri.mapper;

import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;

public interface DuelSessionStateMapper {
    DuelSessionStateDto toStateDto(DuelGameSession session, String lastEventMessage);
}

