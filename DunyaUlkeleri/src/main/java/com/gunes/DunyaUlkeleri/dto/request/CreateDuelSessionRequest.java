package com.gunes.DunyaUlkeleri.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateDuelSessionRequest {
    private String username;
    private String category;
    private String mode;
    private Boolean vsBot;
    private String botDifficulty;
}
