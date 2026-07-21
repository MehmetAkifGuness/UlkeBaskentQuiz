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

    @Query(
            "SELECT g.user.username, MAX(g.currentScore), g.user.avatarId, " +
            "CASE WHEN g.user.customAvatar IS NOT NULL THEN true ELSE false END " +
            "FROM GameSession g " +
            "WHERE g.category = :category " +
            "AND g.createdAt >= :startDate " +
            "GROUP BY g.user.username, g.user.avatarId, " +
            "CASE WHEN g.user.customAvatar IS NOT NULL THEN true ELSE false END " +
            "ORDER BY MAX(g.currentScore) DESC"
    )
    List<Object[]> findTop10DailyScoresWithProfile(
            @Param("category") String category,
            @Param("startDate") LocalDateTime startDate,
            Pageable pageable
    );

    @Query("SELECT g.user.username, MAX(g.currentScore) FROM GameSession g WHERE g.category = :category AND g.gameMode = :mode GROUP BY g.user.username ORDER BY MAX(g.currentScore) DESC")
    List<Object[]> findTop10ByCategoryAndMode(@Param("category") String category, @Param("mode") String mode, Pageable pageable);

    @Query(
            "SELECT g.user.username, MAX(g.currentScore), g.user.avatarId, " +
            "CASE WHEN g.user.customAvatar IS NOT NULL THEN true ELSE false END " +
            "FROM GameSession g " +
            "WHERE g.category = :category " +
            "AND g.gameMode = :mode " +
            "AND g.createdAt >= :startDate " +
            "GROUP BY g.user.username, g.user.avatarId, " +
            "CASE WHEN g.user.customAvatar IS NOT NULL THEN true ELSE false END " +
            "ORDER BY MAX(g.currentScore) DESC"
    )
    List<Object[]> findTop10ByCategoryAndModeWithProfile(
            @Param("category") String category,
            @Param("mode") String mode,
            @Param("startDate") LocalDateTime startDate,
            Pageable pageable
    );

    // Mod seçimi kaldırıldı: Ülke->Başkent / Başkent->Ülke / Karışık modlarının tamamında
    // kullanıcıların kategori (kıta) bazında en iyi skorunu döndür.
    // Not: ENDLESS gibi özel modlar bu sorguya dahil edilmez.
    @Query(
            "SELECT g.user.username, MAX(g.currentScore) " +
            "FROM GameSession g " +
            "WHERE g.category = :category " +
            "AND (g.gameMode IN ('COUNTRY_TO_CAPITAL', 'CAPITAL_TO_COUNTRY', 'MIXED')) " +
            "GROUP BY g.user.username " +
            "ORDER BY MAX(g.currentScore) DESC"
    )
    List<Object[]> findTop10ByCategoryOverall(@Param("category") String category, Pageable pageable);

    @Query(
            "SELECT g.user.username, MAX(g.currentScore), g.user.avatarId, " +
            "CASE WHEN g.user.customAvatar IS NOT NULL THEN true ELSE false END " +
            "FROM GameSession g " +
            "WHERE g.category = :category " +
            "AND g.createdAt >= :startDate " +
            "AND (g.gameMode IN ('COUNTRY_TO_CAPITAL', 'CAPITAL_TO_COUNTRY', 'MIXED')) " +
            "GROUP BY g.user.username, g.user.avatarId, " +
            "CASE WHEN g.user.customAvatar IS NOT NULL THEN true ELSE false END " +
            "ORDER BY MAX(g.currentScore) DESC"
    )
    List<Object[]> findTop10ByCategoryOverallWithProfile(
            @Param("category") String category,
            @Param("startDate") LocalDateTime startDate,
            Pageable pageable
    );

    void deleteByUser(User user);

    List<GameSession> findByIsFinishedTrueAndUpdateAtBefore(LocalDateTime cutoffTime);
    
    Optional<GameSession> findFirstByUserAndIsFinishedFalseOrderByUpdateAtDesc(User user);

    // 🚨 YENİ EKLENDİ: Yeni oyuna başlandığında terk edilen oyunları bulmak için
    List<GameSession> findByUserAndIsFinishedFalse(User user);

    List<GameSession> findTop10ByUserAndIsFinishedTrueOrderByUpdateAtDesc(User user);

    @Query("SELECT COALESCE(SUM(g.currentScore), 0) FROM GameSession g WHERE g.user = :user AND g.isFinished = true")
    long sumFinishedScoresByUser(@Param("user") User user);
}
