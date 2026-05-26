package com.gunes.DunyaUlkeleri.mapper.impl;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.response.ConquestPlayerDto;
import com.gunes.DunyaUlkeleri.dto.response.ConquestRoundDto;
import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.mapper.ConquestSessionStateMapper;

@Service
public class ConquestSessionStateMapperImpl
        implements ConquestSessionStateMapper {

    @Override
    public ConquestSessionStateDto toStateDto(
            ConquestGameSession session,
            String lastEventMessage,
            String lastWinnerPlayerId,
            boolean roundLocked
    ) {
        final List<ConquestPlayerDto> players = Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .map(p -> new ConquestPlayerDto(
                        p.getPlayerId(),
                        p.getUsername(),
                        p.getColorHex(),
                        p.getType() == null ? null : p.getType().name(),
                        p.getScore(),
                        p.getConqueredCount(),
                        p.getRemainingLives(),
                        p.isConnected(),
                        p.isReady()
                ))
                .toList();

        final ConquestRoundDto roundDto = session.getCurrentRound() == null
                ? null
                : new ConquestRoundDto(
                        session.getCurrentRound().getRoundNumber(),
                        session.getCurrentRound().getTargetIsoCode(),
                        session.getCurrentRound().getTargetCountryName(),
                        session.getCurrentRound().isLocked(),
                        session.getCurrentRound().getWinnerPlayerId(),
                        session.getCurrentRound().getStartedAt(),
                        session.getCurrentRound().getFinishedAt()
                );

        return new ConquestSessionStateDto(
                session.getSessionId(),
                session.getRoomCode(),
                session.getStatus() == null ? null : session.getStatus().name(),
                session.getSelectedContinentFilter(),
                session.getHostPlayerId(),
                session.isQuickMatch(),
                players,
                session.getConqueredCountryColors(),
                roundDto,
                session.getPlayableIsoCodes(),
                lastEventMessage,
                lastWinnerPlayerId,
                roundLocked
        );
    }
}
