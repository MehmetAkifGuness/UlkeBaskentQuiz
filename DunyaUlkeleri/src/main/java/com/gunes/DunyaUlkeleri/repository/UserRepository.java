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

    // YENİ EKLENEN: Kategoriye göre en yüksek skorlu 10 kişiyi çeken PostgreSQL uyumlu sorgu
    @Query("SELECT u.username, VALUE(s) FROM User u JOIN u.categoryBestScores s WHERE KEY(s) = :category ORDER BY VALUE(s) DESC")
    List<Object[]> findTop10ByCategory(@Param("category") String category, Pageable pageable);
}
