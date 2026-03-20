package com.gunes.DunyaUlkeleri.dto.response;

import lombok.Data;
import java.util.List;

@Data
public class GameStatusResponse {
    private Long sessionId;
    private Boolean lastAnswerCorrect;
    private String lastCorrectAnswer;
    private int currentScore;
    private int remainingLives;
    private String countryName;
    private List<String> options;
    private String message;
    private boolean finished;
    
    // 🚨 İŞTE BU SATIR EKSİK OLDUĞU İÇİN O HATAYI ALIYORSUN 🚨
    private String questionText;

    private String ghostName;
    private Integer ghostScore;
    private Integer totalQuestions;
    private Integer remainingQuestions;
}