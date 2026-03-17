package com.gunes.DunyaUlkeleri.repository;

import com.gunes.DunyaUlkeleri.entity.GameSession;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface GameSessionRepository extends JpaRepository<GameSession, Long> {
    
    List<GameSession> findByUserIdOrderByCreatedAtDesc(Long userId);

    // 🚨 GÜNLÜK GÖREV SORGUSU: Bugün oynanmış ve bitmiş olan "DailyChallenge" oyunlarını skora göre dizer
    @Query("SELECT s.user.username, s.currentScore FROM GameSession s WHERE s.category = :category AND s.isFinished = true AND s.createdAt >= :startOfDay ORDER BY s.currentScore DESC")
    List<Object[]> findTop10DailyScores(@Param("category") String category, @Param("startOfDay") LocalDateTime startOfDay, Pageable pageable);
}