package com.gunes.DunyaUlkeleri.service;

import java.util.List;
import java.util.Map;
import java.util.Set;

import com.gunes.DunyaUlkeleri.dto.response.RecentSessionResponse;
import com.gunes.DunyaUlkeleri.dto.response.UserAvatarImageResponse;
import com.gunes.DunyaUlkeleri.entity.Question;

public interface UserProfileQueryService {

    Map<String, Integer> getMyCategoryScores(String username);

    List<RecentSessionResponse> getRecentSessions(String username, int limit);

    Set<Question> getUserMistakes(String username);

    void removeMistake(String username, Long questionId);

    UserAvatarImageResponse getCustomAvatarImage(String username);
}

