package com.gunes.DunyaUlkeleri.service.impl;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gunes.DunyaUlkeleri.dto.response.LeaderboardEntryResponse;
import com.gunes.DunyaUlkeleri.dto.response.LeagueLeaderboardEntryResponse;
import com.gunes.DunyaUlkeleri.dto.response.LeagueLeaderboardResponse;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.LeaderboardService;
import com.gunes.DunyaUlkeleri.service.LeagueService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class LeaderboardServiceImpl implements LeaderboardService {

    private static final Logger log = LoggerFactory.getLogger(LeaderboardServiceImpl.class);

    private final GameSessionRepository gameSessionRepository;
    private final UserRepository userRepository;
    private final LeagueService leagueService;

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
                    LocalDate.now().withDayOfMonth(1).atStartOfDay(),
                    PageRequest.of(0, 10)
            );
        } else {
            rows = gameSessionRepository.findTop10ByCategoryOverallWithProfile(
                    category,
                    LocalDate.now().withDayOfMonth(1).atStartOfDay(),
                    PageRequest.of(0, 10)
            );
        }

        final int rowCount = (rows == null) ? 0 : rows.size();
        final Object[] top = (rows != null && !rows.isEmpty()) ? rows.get(0) : null;
        final String topUsername = (top != null && top.length > 0 && top[0] != null) ? top[0].toString() : null;
        final Integer topScore = (top != null && top.length > 1) ? toInteger(top[1]) : null;
        log.info(
                "leaderboard category={} mode={} rows={} topUser={} topScore={}",
                category,
                mode,
                rowCount,
                topUsername,
                topScore
        );

        List<LeaderboardEntryResponse> out = new ArrayList<>();
        for (Object[] row : rows) {
            if (row == null || row.length < 2) continue;
            String username = row[0] == null ? null : row[0].toString();
            Integer score = toInteger(row[1]);
            Integer avatarId = (row.length > 2) ? toInteger(row[2]) : null;
            boolean hasCustomAvatar = (row.length > 3) && Boolean.TRUE.equals(row[3]);

            LeaderboardEntryResponse dto = new LeaderboardEntryResponse();
            dto.setUsername(username);
            dto.setScore(score);
            dto.setAvatarId(avatarId);
            dto.setHasCustomAvatar(hasCustomAvatar);
            out.add(dto);
        }
        return out;
    }

    @Override
    @Transactional
    public LeagueLeaderboardResponse getLeagueLeaderboard(String username) {
        leagueService.ensureAllSeasons();

        List<User> topUsers = userRepository.findLeagueLeaderboard(PageRequest.of(0, 100));
        User current = userRepository.findByUsername(username).orElse(null);

        LeagueLeaderboardResponse response = new LeagueLeaderboardResponse();
        response.setSeason(leagueService.currentSeasonId());
        response.setTotalPlayers(userRepository.countLeaguePlayers());
        response.setTopPlayers(toLeagueEntries(topUsers, username, 1));
        if (current != null && !current.isGuest()) {
            long ahead = userRepository.countLeaguePlayersAhead(current.getTrophies(), current.getUsername());
            response.setCurrentUser(toLeagueEntry(
                    current,
                    (int) Math.min(Integer.MAX_VALUE, ahead + 1),
                    username
            ));
        }
        return response;
    }

    private List<LeagueLeaderboardEntryResponse> toLeagueEntries(
            List<User> users,
            String currentUsername,
            int firstRank) {
        List<LeagueLeaderboardEntryResponse> entries = new ArrayList<>();
        for (int i = 0; i < users.size(); i++) {
            entries.add(toLeagueEntry(users.get(i), firstRank + i, currentUsername));
        }
        return entries;
    }

    private LeagueLeaderboardEntryResponse toLeagueEntry(User user, int rank, String currentUsername) {
        LeagueLeaderboardEntryResponse entry = new LeagueLeaderboardEntryResponse();
        entry.setRank(rank);
        entry.setUsername(user.getUsername());
        entry.setTrophies(user.getTrophies());
        entry.setLeague(leagueService.leagueNameOf(user.getTrophies()));
        entry.setAvatarId(user.getAvatarId());
        entry.setHasCustomAvatar(user.getCustomAvatar() != null && user.getCustomAvatar().length > 0);
        entry.setCurrentUser(user.getUsername().equals(currentUsername));
        return entry;
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
