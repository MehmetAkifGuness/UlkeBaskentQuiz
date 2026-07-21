package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.request.StartConquestGameRequest;
import com.gunes.DunyaUlkeleri.dto.response.ConquestSessionStateDto;
import com.gunes.DunyaUlkeleri.entity.ConquestGameSession;
import com.gunes.DunyaUlkeleri.entity.ConquestGameStatus;
import com.gunes.DunyaUlkeleri.mapper.ConquestSessionStateMapper;
import com.gunes.DunyaUlkeleri.repository.ConquestSessionStore;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConquestPauseService {

    private final ConquestSessionStore sessionStore;
    private final ConquestRoundScheduler roundScheduler;
    private final ConquestSessionStateMapper stateMapper;

    public ConquestSessionStateDto pauseGame(StartConquestGameRequest request) {
        final ConquestGameSession session = session(request);
        synchronized (session) {
            final String playerId = playerId(request);
            requirePlayer(session, playerId);
            if (session.getStatus() != ConquestGameStatus.STARTED) {
                throw AppException.conflict("GAME_NOT_PAUSABLE", "Oyun şu anda duraklatılamaz.");
            }
            if (session.isPauseUsed()) {
                throw AppException.conflict(
                        "PAUSE_ALREADY_USED",
                        "Bu oyunda duraklatma hakkı zaten kullanıldı."
                );
            }

            session.setPauseUsed(true);
            session.setStatus(ConquestGameStatus.PAUSED);
            session.touch();
            sessionStore.save(session);
            roundScheduler.clear(session.getSessionId());
            return stateMapper.toStateDto(session, "Oyun duraklatıldı. Tek duraklatma hakkı kullanıldı.", null, true);
        }
    }

    public ConquestSessionStateDto resumeGame(StartConquestGameRequest request) {
        final ConquestGameSession session = session(request);
        synchronized (session) {
            requirePlayer(session, playerId(request));
            if (session.getStatus() != ConquestGameStatus.PAUSED) {
                throw AppException.conflict("GAME_NOT_PAUSED", "Oyun duraklatılmış değil.");
            }

            session.setStatus(ConquestGameStatus.STARTED);
            session.touch();
            sessionStore.save(session);
            roundScheduler.reschedule(session);
            return stateMapper.toStateDto(session, "Oyun devam ediyor.", null, session.getCurrentRound() != null && session.getCurrentRound().isLocked());
        }
    }

    private ConquestGameSession session(StartConquestGameRequest request) {
        final String sessionId = request == null ? null : request.getSessionId();
        return sessionStore.requireById(sessionId == null ? null : sessionId.trim());
    }

    private static String playerId(StartConquestGameRequest request) {
        final String playerId = request == null ? null : request.getPlayerId();
        if (playerId == null || playerId.trim().isBlank()) {
            throw AppException.badRequest("PLAYER_ID_REQUIRED", "playerId boş olamaz.");
        }
        return playerId.trim();
    }

    private static void requirePlayer(ConquestGameSession session, String playerId) {
        if (session.getPlayer(playerId) == null) {
            throw AppException.notFound("PLAYER_NOT_FOUND", "Oyuncu bulunamadı.");
        }
    }
}
