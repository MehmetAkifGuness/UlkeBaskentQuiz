package com.gunes.DunyaUlkeleri.entity;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "game_session", indexes = {
    @Index(name = "idx_category_mode_score", columnList = "category, game_mode, currentScore DESC")
})
@Data
public class GameSession {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne // her oyun birr kullanıcıya ait
    @JoinColumn(name = "user_id" , nullable = false)
    private User user;
    
    @Column(nullable = false)
    private int currentScore;

    @Column(nullable = false)
    private int remainingLives;

    @Column(nullable = false)
    private boolean isFinished;

    @Column(name = "current_correct_answer")
    private String currentCorrectAnswer;

    @Column(nullable = false , updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updateAt;

    // 🚨 YENİ EKLENDİ: Oyun modu veritabanında tutulacak
    @Column(name = "game_mode")
    private String gameMode;

    // 🚨 GÜVENLİK YAMASI: Hile (Exploit) kontrolü için sorunun sorulduğu anı tutuyoruz
    @Column(name = "last_question_time")
    private LocalDateTime lastQuestionTime;

    @PrePersist
    protected void onCreate(){
        this.createdAt = LocalDateTime.now();
        this.updateAt = LocalDateTime.now();
        this.currentScore = 0;
        this.remainingLives = 3;
        this.isFinished = false;
        this.lastQuestionTime = LocalDateTime.now(); // İlk soru zamanı
    }

    @PreUpdate
    protected void onUpdate(){
        this.updateAt = LocalDateTime.now();
    }

    @Column(name = "category")
    private String category;
    
    @ElementCollection
    @CollectionTable(name = "session_asked_questions", joinColumns = @JoinColumn(name = "session_id"))
    @Column(name = "question_id")
    private Set<Long>askedQuestionIds = new HashSet<>();

    @Column(name = "current_question_id")
    private Long currentQuestionId;
}