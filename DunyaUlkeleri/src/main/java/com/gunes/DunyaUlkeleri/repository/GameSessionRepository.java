package com.gunes.DunyaUlkeleri.repository;

import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface GameSessionRepository extends JpaRepository<GameSession, Long> {
    
    @Query("SELECT g.user.username, MAX(g.currentScore) FROM GameSession g WHERE g.category = :category AND g.createdAt >= :startDate GROUP BY g.user.username ORDER BY MAX(g.currentScore) DESC")
    List<Object[]> findTop10DailyScores(@Param("category") String category, @Param("startDate") LocalDateTime startDate, Pageable pageable);

    @Query("SELECT g.user.username, MAX(g.currentScore) FROM GameSession g WHERE g.category = :category AND g.gameMode = :mode GROUP BY g.user.username ORDER BY MAX(g.currentScore) DESC")
    List<Object[]> findTop10ByCategoryAndMode(@Param("category") String category, @Param("mode") String mode, Pageable pageable);

    void deleteByUser(User user);

    List<GameSession> findByIsFinishedTrueAndUpdateAtBefore(LocalDateTime cutoffTime);
    
    Optional<GameSession> findFirstByUserAndIsFinishedFalseOrderByUpdateAtDesc(User user);

    // 🚨 YENİ EKLENDİ: Yeni oyuna başlandığında terk edilen oyunları bulmak için
    List<GameSession> findByUserAndIsFinishedFalse(User user);
}