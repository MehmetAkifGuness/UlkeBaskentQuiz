package com.gunes.DunyaUlkeleri.mapper;

import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.springframework.stereotype.Component;

import com.gunes.DunyaUlkeleri.dto.response.DuelPlayerDto;
import com.gunes.DunyaUlkeleri.dto.response.DuelRoundDto;
import com.gunes.DunyaUlkeleri.dto.response.DuelSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.DuelGameSession;
import com.gunes.DunyaUlkeleri.entity.DuelGameStatus;
import com.gunes.DunyaUlkeleri.entity.DuelPlayer;
import com.gunes.DunyaUlkeleri.entity.DuelRound;

@Component
public class DuelSessionStateMapperImpl implements DuelSessionStateMapper {

    @Override
    public DuelSessionStateDto toStateDto(DuelGameSession session, String lastEventMessage) {
        if (session == null) return null;

        List<DuelPlayerDto> players = Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .map(p -> new DuelPlayerDto(
                        p.getPlayerId(),
                        p.getUsername(),
                        p.getScore(),
                        p.isConnected()
                ))
                .toList();

        DuelRoundDto roundDto = toRoundDto(session);

        final boolean finished = session.getStatus() == DuelGameStatus.FINISHED;
        final String winnerUsername = finished ? computeWinnerUsername(session) : null;

        return new DuelSessionStateDto(
                session.getSessionId(),
                session.getRoomCode(),
                session.getStatus() == null ? null : session.getStatus().name(),
                session.getCategory(),
                session.getMode(),
                session.isQuickMatch(),
                lastEventMessage,
                winnerUsername,
                finished,
                players,
                roundDto
        );
    }

    private DuelRoundDto toRoundDto(DuelGameSession session) {
        final DuelRound round = session.getCurrentRound();
        if (round == null) return null;

        final boolean finished = session.getStatus() == DuelGameStatus.FINISHED;
        final String correctAnswer = (round.isLocked() || finished) ? round.getCorrectAnswer() : null;

        return new DuelRoundDto(
                round.getRoundNumber(),
                round.getQuestionText(),
                round.getOptions(),
                round.isLocked(),
                round.getWinnerPlayerId(),
                round.getStartedAt(),
                round.getDeadlineAt(),
                correctAnswer
        );
    }

    private String computeWinnerUsername(DuelGameSession session) {
        List<DuelPlayer> players = Optional.ofNullable(session.getPlayers())
                .orElseGet(List::of)
                .stream()
                .filter(Objects::nonNull)
                .toList();
        if (players.size() != 2) return null;

        DuelPlayer p1 = players.get(0);
        DuelPlayer p2 = players.get(1);
        if (p1.getScore() == p2.getScore()) return null;

        DuelPlayer winner = players.stream()
                .max(Comparator.comparingInt(DuelPlayer::getScore))
                .orElse(null);
        return winner == null ? null : winner.getUsername();
    }
}

