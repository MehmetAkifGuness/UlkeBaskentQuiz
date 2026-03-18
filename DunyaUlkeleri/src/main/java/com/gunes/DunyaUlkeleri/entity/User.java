package com.gunes.DunyaUlkeleri.entity;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.MapKeyColumn;
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

    private LocalDate lastDailyDate;

    @Column(updatable = false)
    private LocalDateTime creationDate;

    @PrePersist
    protected void onCreate(){
        this.creationDate = LocalDateTime.now();
    }

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "user_category_scores", joinColumns = @JoinColumn(name = "user_id"))
    @MapKeyColumn(name = "category")
    @Column(name = "best_score")
    private Map<String, Integer> categoryBestScores = new HashMap<>();

    // Getter ve Setter
    public Map<String, Integer> getCategoryBestScores() {
        return categoryBestScores;
    }

    public void setCategoryBestScores(Map<String, Integer> categoryBestScores) {
        this.categoryBestScores = categoryBestScores;
    }

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "user_mistakes",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "question_id")
    )
    private Set<Question> failedQuestions = new HashSet<>();
}
