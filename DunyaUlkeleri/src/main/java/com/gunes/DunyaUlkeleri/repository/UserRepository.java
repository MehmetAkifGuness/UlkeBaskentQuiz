package com.gunes.DunyaUlkeleri.repository;

import com.gunes.DunyaUlkeleri.entity.User;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    @Transactional(readOnly = true)
    Optional<User> findByUsername(String username);

    @Transactional(readOnly = true)
    Optional<User> findByEmail(String email);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);

    // 🚨 YENİ EKLENDİ: Scheduler'ın (Temizlikçinin) misafirleri bulabilmesi için
    List<User> findByIsGuestTrue();

    @Query("SELECT u.id, u.trophies, u.trophySeason FROM User u WHERE u.isGuest = false")
    List<Object[]> findLeagueStates();

    @Query("SELECT u FROM User u WHERE u.isGuest = false ORDER BY u.trophies DESC, u.username ASC")
    List<User> findLeagueLeaderboard(Pageable pageable);

    @Query("SELECT COUNT(u) FROM User u WHERE u.isGuest = false AND (u.trophies > :trophies OR (u.trophies = :trophies AND u.username < :username))")
    long countLeaguePlayersAhead(@Param("trophies") int trophies, @Param("username") String username);

    @Query("SELECT COUNT(u) FROM User u WHERE u.isGuest = false")
    long countLeaguePlayers();

    @Query("UPDATE User u SET u.trophies = :trophies, u.trophySeason = :season WHERE u.id = :id")
    @org.springframework.data.jpa.repository.Modifying(clearAutomatically = true, flushAutomatically = true)
    int updateLeagueState(@Param("id") long id, @Param("trophies") int trophies, @Param("season") int season);

    // YENİ EKLENEN: Kategoriye göre en yüksek skorlu 10 kişiyi çeken PostgreSQL uyumlu sorgu
    @Query("SELECT u.username, VALUE(s) FROM User u JOIN u.categoryBestScores s WHERE KEY(s) = :category ORDER BY VALUE(s) DESC")
    List<Object[]> findTop10ByCategory(@Param("category") String category, Pageable pageable);
}
