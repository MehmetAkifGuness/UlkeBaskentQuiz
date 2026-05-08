package com.gunes.DunyaUlkeleri.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

@Data
public class GameAnswerRequest {
    @NotNull(message = "Oyun oturumu (sessionId) boş olamaz")
    @Positive(message = "Oyun oturumu (sessionId) geçersiz")
    private Long sessionId;

    @NotBlank(message = "Cevap boş olamaz")
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
