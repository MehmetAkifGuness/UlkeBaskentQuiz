package com.gunes.DunyaUlkeleri.repository;

import com.gunes.DunyaUlkeleri.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);

    @Modifying
    @Query("DELETE FROM User u WHERE u.isVerified = false AND u.creationDate < :cutoff")
    void deleteUnverifiedUsersOlderThan(@Param("cutoff") LocalDateTime cutoff);
}