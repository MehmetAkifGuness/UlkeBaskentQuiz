package com.gunes.DunyaUlkeleri.dto.request;

import lombok.Data;

@Data
public class GameAnswerRequest {
    private Long sessionId;
    private String capitalGuess; // 'answer' olan yeri 'capitalGuess' yaptık

    private String countryName;
    private String capitalName;

    private double timeTaken;
    
    public double getTimeTaken() {
        return timeTaken;
    }
    
    public void setTimeTaken(double timeTaken) {
        this.timeTaken = timeTaken;
    }
}