package com.gunes.DunyaUlkeleri.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "question")
@Data
public class Question {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false , unique = true)
    private String countryName;

    @Column(nullable = false)
    private String capitalName;

    // KITA BİLGİSİ EKLENDİ (HATANIN ÇÖZÜMÜ)
    @Column(name = "continent")
    private String continent; 
}