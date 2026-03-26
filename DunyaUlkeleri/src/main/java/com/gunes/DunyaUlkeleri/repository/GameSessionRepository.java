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
    
    @Query("SELECT g.user.username, g.currentScore FROM GameSession g WHERE g.category = :category AND g.createdAt >= :startDate ORDER BY g.currentScore DESC")
    List<Object[]> findTop10DailyScores(@Param("category") String category, @Param("startDate") LocalDateTime startDate, Pageable pageable);

    @Query("SELECT g.user.username, g.currentScore FROM GameSession g WHERE g.category = :category AND g.gameMode = :mode ORDER BY g.currentScore DESC")
    List<Object[]> findTop10ByCategoryAndMode(@Param("category") String category, @Param("mode") String mode, Pageable pageable);

    void deleteByUser(User user);

    // 🚨 YENİ EKLENDİ: Çöpçü için 24 saatten eski ve "Bitmiş" oyunları bulma metodu
    List<GameSession> findByIsFinishedTrueAndUpdateAtBefore(LocalDateTime cutoffTime);
    // 🚨 YENİ EKLENDİ: Kullanıcının en son oynadığı, bitmemiş oyunu getirir
    Optional<GameSession> findFirstByUserAndIsFinishedFalseOrderByUpdateAtDesc(User user);
}