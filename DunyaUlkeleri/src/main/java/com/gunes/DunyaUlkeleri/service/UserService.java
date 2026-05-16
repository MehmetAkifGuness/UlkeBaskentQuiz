package com.gunes.DunyaUlkeleri.service;

import com.gunes.DunyaUlkeleri.dto.response.UserProfileResponse;

public interface UserService {
    
    // updateWinStreak metodunu tamamen sildik, sadece profil getirme kaldı.
    // Parametre olarak artık 'email' değil 'username' alıyor.
    UserProfileResponse getUserProfile(String username);
    void updateAvatar(String username, Integer avatarId);

    UserProfileResponse updateDisplayName(String username, String displayName);

    UserProfileResponse uploadCustomAvatar(String username, byte[] imageBytes, String contentType);

    void clearCustomAvatar(String username);
}
