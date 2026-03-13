package com.gunes.DunyaUlkeleri.entity;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table (name = "users")
@Data
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    @Column(nullable = false , unique = true)
    private String username;

    @Column(unique = true)
    private String email;
    @Column(columnDefinition = "integer default 0")
    private int totalGamesPlayed = 0;

    private String password;

    private boolean isGuest;

    private int maxWinStreak;

    private String verificationCode;

    private boolean isVerified = false;

    private String resetCode;

    @Column(updatable = false)
    private LocalDateTime creationDate;

    @PrePersist
    protected void onCreate(){
        this.creationDate = LocalDateTime.now();
    }
}
