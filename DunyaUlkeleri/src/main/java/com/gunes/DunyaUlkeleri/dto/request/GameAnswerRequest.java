package com.gunes.DunyaUlkeleri.dto.request;

import lombok.Data;

@Data
public class GameAnswerRequest {
    private Long sessionId;
    private String capitalGuess; // 'answer' olan yeri 'capitalGuess' yaptık

    private String countryName;
    private String capitalName;

    private int timeTaken;
    
    public int getTimeTaken() {
        return timeTaken;
    }
    
    public void setTimeTaken(int timeTaken) {
        this.timeTaken = timeTaken;
    }
}