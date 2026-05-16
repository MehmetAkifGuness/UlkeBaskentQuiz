package com.gunes.DunyaUlkeleri.serviceimp;

import java.util.Base64;
import java.time.LocalDate;
import java.util.Optional;
import org.springframework.stereotype.Service;
import com.gunes.DunyaUlkeleri.dto.response.UserProfileResponse;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.UserService;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    
    private final UserRepository userRepository;

    @Override
    public UserProfileResponse getUserProfile(String username) {
        // Aramayı artık email ile değil, %100 emin olduğumuz username ile yapıyoruz
        Optional<User> userOptional = userRepository.findByUsername(username);
        
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            
            // Bilgileri DTO (veri transfer objesi) içine paketliyoruz
            UserProfileResponse response = new UserProfileResponse();
            response.setUsername(user.getUsername());
            response.setDisplayName(user.getDisplayName() == null || user.getDisplayName().isBlank()
                    ? user.getUsername()
                    : user.getDisplayName());
            response.setEmail(user.getEmail());
            response.setAvatarId(user.getAvatarId());
            response.setCreationDate(user.getCreationDate());
            response.setMaxWinStreak(user.getMaxWinStreak());
            response.setTotalGamesPlayed(user.getTotalGamesPlayed());

            if (user.getCustomAvatar() != null && user.getCustomAvatar().length > 0) {
                response.setCustomAvatarBase64(Base64.getEncoder().encodeToString(user.getCustomAvatar()));
                response.setCustomAvatarContentType(user.getCustomAvatarContentType());
            }

            boolean playedToday = user.getLastDailyDate() != null && user.getLastDailyDate().equals(LocalDate.now());
            response.setHasPlayedDaily(playedToday);
            response.setDailyStreak(user.getDailyStreak() == null ? 0 : user.getDailyStreak());
            return response;
        }
        
        return null;
    }

    @Override
    public void updateAvatar(String username, Integer avatarId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));
        
        user.setAvatarId(avatarId);
        user.setCustomAvatar(null);
        user.setCustomAvatarContentType(null);
        userRepository.save(user);
    }

    @Override
    public UserProfileResponse updateDisplayName(String username, String displayName) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        String normalized = displayName == null ? null : displayName.trim();
        if (normalized == null || normalized.isBlank()) {
            throw AppException.badRequest("DISPLAY_NAME_REQUIRED", "İsim (displayName) boş olamaz.");
        }
        if (normalized.length() > 40) {
            throw AppException.badRequest("DISPLAY_NAME_TOO_LONG", "İsim (displayName) en fazla 40 karakter olabilir.");
        }

        user.setDisplayName(normalized);
        userRepository.save(user);
        return getUserProfile(username);
    }

    @Override
    public UserProfileResponse uploadCustomAvatar(String username, byte[] imageBytes, String contentType) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        if (imageBytes == null || imageBytes.length == 0) {
            throw AppException.badRequest("AVATAR_IMAGE_REQUIRED", "Profil fotoğrafı boş olamaz.");
        }

        final int maxBytes = 2 * 1024 * 1024;
        if (imageBytes.length > maxBytes) {
            throw AppException.badRequest("AVATAR_IMAGE_TOO_LARGE", "Profil fotoğrafı en fazla 2MB olabilir.");
        }

        String normalizedContentType = contentType == null ? "" : contentType.trim().toLowerCase();
        if (!(normalizedContentType.equals("image/jpeg")
                || normalizedContentType.equals("image/png")
                || normalizedContentType.equals("image/webp"))) {
            throw AppException.badRequest("AVATAR_IMAGE_TYPE_INVALID", "Sadece JPEG, PNG veya WEBP yükleyebilirsiniz.");
        }

        user.setCustomAvatar(imageBytes);
        user.setCustomAvatarContentType(normalizedContentType);
        userRepository.save(user);

        return getUserProfile(username);
    }

    @Override
    public void clearCustomAvatar(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        user.setCustomAvatar(null);
        user.setCustomAvatarContentType(null);
        userRepository.save(user);
    }
}
