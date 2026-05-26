package com.gunes.DunyaUlkeleri.service.impl;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import com.gunes.DunyaUlkeleri.dto.response.LeaderboardEntryResponse;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.service.LeaderboardService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class LeaderboardServiceImpl implements LeaderboardService {

    private final GameSessionRepository gameSessionRepository;

    @Override
    public List<LeaderboardEntryResponse> getCategoryLeaderboard(String category, String mode) {
        List<Object[]> rows;
        if ("DailyChallenge".equals(category)) {
            LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
            rows = gameSessionRepository.findTop10DailyScoresWithProfile(
                    category,
                    startOfDay,
                    PageRequest.of(0, 10)
            );
        } else if ("ENDLESS".equalsIgnoreCase(mode)) {
            rows = gameSessionRepository.findTop10ByCategoryAndModeWithProfile(
                    category,
                    "ENDLESS",
                    PageRequest.of(0, 10)
            );
        } else {
            rows = gameSessionRepository.findTop10ByCategoryOverallWithProfile(
                    category,
                    PageRequest.of(0, 10)
            );
        }

        List<LeaderboardEntryResponse> out = new ArrayList<>();
        for (Object[] row : rows) {
            if (row == null || row.length < 2) continue;
            String username = row[0] == null ? null : row[0].toString();
            Integer score = toInteger(row[1]);
            Integer avatarId = (row.length > 2) ? toInteger(row[2]) : null;
            String displayName = (row.length > 3 && row[3] != null) ? row[3].toString() : null;
            boolean hasCustomAvatar = (row.length > 4) && Boolean.TRUE.equals(row[4]);

            LeaderboardEntryResponse dto = new LeaderboardEntryResponse();
            dto.setUsername(username);
            dto.setScore(score);
            dto.setAvatarId(avatarId);
            dto.setDisplayName(displayName);
            dto.setHasCustomAvatar(hasCustomAvatar);
            out.add(dto);
        }
        return out;
    }

    private static Integer toInteger(Object value) {
        if (value == null) return null;
        if (value instanceof Number number) return number.intValue();
        try {
            return Integer.parseInt(value.toString());
        } catch (Exception ignored) {
            return null;
        }
    }
}
