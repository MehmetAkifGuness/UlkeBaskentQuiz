package com.gunes.DunyaUlkeleri.service.impl;

import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gunes.DunyaUlkeleri.dto.response.RecentSessionResponse;
import com.gunes.DunyaUlkeleri.dto.response.UserAvatarImageResponse;
import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.UserProfileQueryService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserProfileQueryServiceImpl implements UserProfileQueryService {

    private final UserRepository userRepository;
    private final GameSessionRepository gameSessionRepository;

    @Override
    public Map<String, Integer> getMyCategoryScores(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));
        return Map.copyOf(user.getCategoryBestScores());
    }

    @Override
    public List<RecentSessionResponse> getRecentSessions(String username, int limit) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        int safeLimit = Math.max(1, Math.min(limit, 10));
        List<GameSession> sessions = gameSessionRepository.findTop10ByUserAndIsFinishedTrueOrderByUpdateAtDesc(user);

        return sessions.stream()
                .limit(safeLimit)
                .map(this::toRecentSessionResponse)
                .toList();
    }

    @Override
    public Set<Question> getUserMistakes(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));
        return Set.copyOf(user.getFailedQuestions());
    }

    @Override
    @Transactional
    public void removeMistake(String username, Long questionId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        user.getFailedQuestions().removeIf(q -> q.getId().equals(questionId));
    }

    @Override
    public UserAvatarImageResponse getCustomAvatarImage(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        byte[] image = user.getCustomAvatar();
        if (image == null || image.length == 0) {
            throw AppException.notFound("AVATAR_NOT_FOUND", "Bu kullanıcı için profil fotoğrafı bulunamadı.");
        }

        String contentType = user.getCustomAvatarContentType();
        return new UserAvatarImageResponse(contentType, image);
    }

    private RecentSessionResponse toRecentSessionResponse(GameSession session) {
        RecentSessionResponse dto = new RecentSessionResponse();
        dto.setId(session.getId());
        dto.setCategory(session.getCategory() == null ? "Dünya" : session.getCategory());
        dto.setGameMode(session.getGameMode() == null ? "MIXED" : session.getGameMode());
        dto.setCurrentScore(session.getCurrentScore());
        dto.setRemainingLives(session.getRemainingLives());
        dto.setFinished(session.isFinished());
        dto.setCreatedAt(session.getCreatedAt());
        dto.setUpdateAt(session.getUpdateAt());
        return dto;
    }
}

