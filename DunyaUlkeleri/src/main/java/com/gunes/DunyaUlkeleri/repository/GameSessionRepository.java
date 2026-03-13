package com.gunes.DunyaUlkeleri.repository;

import com.gunes.DunyaUlkeleri.entity.GameSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GameSessionRepository extends JpaRepository<GameSession, Long> {
    
    // İleride kullanıcının geçmiş oyunlarını (skorlarını) listelemek istersen kullanabileceğin metot:
    // Spring Boot bu isme bakarak arka planda SQL sorgusunu kendisi yazar.
    List<GameSession> findByUserIdOrderByCreatedAtDesc(Long userId);
}