package com.gunes.DunyaUlkeleri.serviceimp;

import java.util.Locale;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.SubmitConquestAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.entity.ConquestPlayer;
import com.gunes.DunyaUlkeleri.entity.ConquestRound;
import com.gunes.DunyaUlkeleri.mapper.ConquestSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.service.ConquestRoundService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestAnswerService {

    private static final Logger log = LoggerFactory.getLogger(ConquestAnswerService.class);

    private final ConquestSessionStore sessionStore;
    private final ConquestRoundService roundService;
    private final ConquestSessionStateMapper stateMapper;

    public ConquestSessionStateDto submitAnswer(SubmitConquestAnswerRequest request) {
        final String sessionId = safeTrim(request == null ? null : request.getSessionId());
        final String playerId = safeTrim(request == null ? null : request.getPlayerId());
        final String selectedIsoCode = safeTrim(request == null ? null : request.getSelectedIsoCode());

        final ConquestGameSession session = sessionStore.requireById(sessionId);

        synchronized (session) {
            if (session.getStatus() == ConquestGameStatus.FINISHED) {
                final String winnerId = session.getCurrentRound() == null
                        ? null
                        : session.getCurrentRound().getWinnerPlayerId();
                return toStateDto(session, "Oyun bitti.", winnerId, true);
            }
            if (session.getStatus() != ConquestGameStatus.STARTED) {
                throw AppException.conflict("GAME_NOT_STARTED", "Oyun baÅŸlamadÄ±.");
            }

            if (playerId == null || playerId.isBlank()) {
                throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boÅŸ olamaz.");
            }

            final ConquestRound round = session.getCurrentRound();
            if (round == null) {
                roundService.pickNextTargetCountry(session, null);
                return toStateDto(session, "Yeni tur baÅŸlatÄ±ldÄ±.", null, false);
            }

            if (round.isLocked()) {
                return toStateDto(session, null, round.getWinnerPlayerId(), true);
            }

            final ConquestPlayer player = session.getPlayer(playerId);
            if (player == null) {
                throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadÄ±.");
            }

            if (player.getRemainingLives() <= 0) {
                if (roundService.areAllPlayersOutOfLives(session)) {
                    roundService.pickNextTargetCountry(session, null);
                    return toStateDto(session, "Ä°ki tarafÄ±n da canÄ± bitti. Ãœlke atlandÄ±.", null, false);
                }
                return toStateDto(session, "Bu tur iÃ§in canÄ±n bitti.", null, false);
            }

            if (selectedIsoCode == null || selectedIsoCode.isBlank()) {
                throw AppException.badRequest("ISO_REQUIRED", "Ãœlke kodu (ISO) boÅŸ olamaz.");
            }

            final String normalizedSelectedIso = selectedIsoCode.trim().toUpperCase(Locale.ROOT);
            final String normalizedTargetIso = safeTrim(round.getTargetIsoCode());

            if (normalizedTargetIso != null && normalizedTargetIso.equalsIgnoreCase(normalizedSelectedIso)) {
                roundService.finishRound(session, player, round);
                session.touch();

                if (session.isFinished()) {
                    session.setStatus(ConquestGameStatus.FINISHED);
                    log.info("Game finished: sessionId={}, roomCode={}", session.getSessionId(), session.getRoomCode());
                    return toStateDto(session, "Tebrikler! TÃ¼m Ã¼lkeler fethedildi.", player.getPlayerId(), true);
                }

                roundService.pickNextTargetCountry(session, player.getPlayerId());
                return toStateDto(session, "Round kazanÄ±ldÄ±.", player.getPlayerId(), false);
            }

            player.setRemainingLives(Math.max(0, player.getRemainingLives() - 1));
            session.touch();

            log.info(
                    "Wrong answer: sessionId={}, playerId={}, selectedIso={}, remainingLives={}",
                    session.getSessionId(),
                    playerId,
                    normalizedSelectedIso,
                    player.getRemainingLives()
            );

            if (roundService.areAllPlayersOutOfLives(session)) {
                roundService.pickNextTargetCountry(session, null);
                return toStateDto(session, "Ä°ki tarafÄ±n da canÄ± bitti. Ãœlke atlandÄ±.", null, false);
            }

            return toStateDto(session, "YanlÄ±ÅŸ cevap (-1 can).", null, false);
        }
    }

    private ConquestSessionStateDto toStateDto(
            ConquestGameSession session,
            String lastEventMessage,
            String lastWinnerPlayerId,
            boolean roundLocked
    ) {
        return stateMapper.toStateDto(session, lastEventMessage, lastWinnerPlayerId, roundLocked);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}
