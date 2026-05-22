package com.gunes.DunyaUlkeleri.serviceimp;

import java.time.LocalDate;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.unit.DataSize;
import org.springframework.dao.DataIntegrityViolationException;

import com.gunes.DunyaUlkeleri.config.UserAvatarProperties;
import com.gunes.DunyaUlkeleri.dto.response.AuthResponse;
import com.gunes.DunyaUlkeleri.dto.response.UserProfileResponse;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.security.JwtUtil;
import com.gunes.DunyaUlkeleri.service.LeagueService;
import com.gunes.DunyaUlkeleri.service.UserService;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {
    
    private final UserRepository userRepository;
    private final GameSessionRepository gameSessionRepository;
    private final UserAvatarProperties userAvatarProperties;
    private final JwtUtil jwtUtil;
    private final LeagueService leagueService;

    @Override
    @Transactional
    public UserProfileResponse getUserProfile(String username) {
        Optional<User> userOptional = userRepository.findByUsername(username);
        if (userOptional.isEmpty()) return null;

        User user = userOptional.get();

        // Geriye dönük uyumluluk: eski kullanıcılarda bu alan 0 olabilir. İlk profilde backfill yap.
        if (user.getTotalMasteryPoints() == 0L && user.getTotalGamesPlayed() > 0) {
            long sum = gameSessionRepository.sumFinishedScoresByUser(user);
            user.setTotalMasteryPoints(sum);
        }

        leagueService.ensureSeason(user);

        return toUserProfileResponse(user);
    }

    @Override
    @Transactional
    public void updateAvatar(String username, Integer avatarId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));
        
        user.setAvatarId(avatarId);
        user.setCustomAvatar(null);
        user.setCustomAvatarContentType(null);
    }

    @Override
    @Transactional
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
        return toUserProfileResponse(user);
    }

    @Override
    @Transactional
    public AuthResponse updateUsername(String username, String newUsername) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        String normalized = newUsername == null ? null : newUsername.trim();
        if (normalized == null || normalized.isBlank()) {
            throw AppException.badRequest("USERNAME_REQUIRED", "Kullanıcı adı boş olamaz.");
        }
        if (normalized.length() < 3) {
            throw AppException.badRequest("USERNAME_TOO_SHORT", "Kullanıcı adı en az 3 karakter olmalıdır.");
        }
        if (normalized.length() > 20) {
            throw AppException.badRequest("USERNAME_TOO_LONG", "Kullanıcı adı en fazla 20 karakter olabilir.");
        }
        if (normalized.chars().anyMatch(Character::isWhitespace)) {
            throw AppException.badRequest("USERNAME_INVALID", "Kullanıcı adı boşluk içeremez.");
        }
        if (normalized.equals(username)) {
            throw AppException.badRequest("USERNAME_UNCHANGED", "Yeni kullanıcı adı mevcut kullanıcı adı ile aynı olamaz.");
        }

        if (userRepository.existsByUsername(normalized)) {
            throw AppException.conflict("USERNAME_TAKEN", "Bu kullanıcı adı zaten kullanılıyor.");
        }

        user.setUsername(normalized);

        try {
            userRepository.flush();
        } catch (DataIntegrityViolationException e) {
            throw AppException.conflict("USERNAME_TAKEN", "Bu kullanıcı adı zaten kullanılıyor.");
        }

        String token = jwtUtil.generateToken(normalized);
        AuthResponse response = new AuthResponse();
        response.setToken(token);
        response.setUsername(normalized);
        response.setMessage("Kullanıcı adı başarıyla güncellendi.");
        return response;
    }

    @Override
    @Transactional
    public UserProfileResponse uploadCustomAvatar(String username, byte[] imageBytes, String contentType) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        if (imageBytes == null || imageBytes.length == 0) {
            throw AppException.badRequest("AVATAR_IMAGE_REQUIRED", "Profil fotoğrafı boş olamaz.");
        }

        DataSize maxSize = userAvatarProperties.getMaxSize();
        if (imageBytes.length > maxSize.toBytes()) {
            throw AppException.badRequest(
                    "AVATAR_IMAGE_TOO_LARGE",
                    "Profil fotoğrafı en fazla " + maxSize.toMegabytes() + "MB olabilir.");
        }

        String normalizedContentType = contentType == null ? "" : contentType.trim().toLowerCase();
        if (!(normalizedContentType.equals("image/jpeg")
                || normalizedContentType.equals("image/png")
                || normalizedContentType.equals("image/webp"))) {
            throw AppException.badRequest("AVATAR_IMAGE_TYPE_INVALID", "Sadece JPEG, PNG veya WEBP yükleyebilirsiniz.");
        }

        user.setCustomAvatar(imageBytes);
        user.setCustomAvatarContentType(normalizedContentType);
        return toUserProfileResponse(user);
    }

    @Override
    @Transactional
    public void clearCustomAvatar(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        user.setCustomAvatar(null);
        user.setCustomAvatarContentType(null);
    }

    @Override
    @Transactional
    public void deleteAccount(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        // FK constraint hatası almamak için önce bağımlı verileri temizle.
        user.getFailedQuestions().clear();
        user.getCategoryBestScores().clear();
        gameSessionRepository.deleteByUser(user);

        userRepository.delete(user);

        try {
            userRepository.flush();
        } catch (DataIntegrityViolationException e) {
            throw AppException.conflict(
                    "USER_DELETE_CONSTRAINT",
                    "Hesap silinemedi. Lütfen daha sonra tekrar deneyin.");
        }
    }

    private UserProfileResponse toUserProfileResponse(User user) {
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
        response.setTotalMasteryPoints(user.getTotalMasteryPoints());
        response.setTrophies(user.getTrophies());
        response.setLeague(leagueService.leagueNameOf(user.getTrophies()));
        response.setTrophySeason(user.getTrophySeason());
        response.setHasCustomAvatar(user.getCustomAvatar() != null && user.getCustomAvatar().length > 0);

        boolean playedToday = user.getLastDailyDate() != null && user.getLastDailyDate().equals(LocalDate.now());
        response.setHasPlayedDaily(playedToday);
        response.setDailyStreak(user.getDailyStreak() == null ? 0 : user.getDailyStreak());
        return response;
    }
}
