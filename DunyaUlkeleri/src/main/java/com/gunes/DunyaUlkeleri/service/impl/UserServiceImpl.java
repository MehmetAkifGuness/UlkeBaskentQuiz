package com.gunes.DunyaUlkeleri.service.impl;

import java.util.Optional;
import org.springframework.stereotype.Service;
import com.gunes.DunyaUlkeleri.dto.response.UserProfileResponse;
import com.gunes.DunyaUlkeleri.entity.User;
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
            response.setEmail(user.getEmail());
            response.setCreationDate(user.getCreationDate());
            response.setMaxWinStreak(user.getMaxWinStreak());
            response.setTotalGamesPlayed(user.getTotalGamesPlayed());
            return response;
        }
        
        return null;
    }
}