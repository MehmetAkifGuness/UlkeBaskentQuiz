package com.gunes.DunyaUlkeleri.conquest.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class JoinConquestSessionRequest {
    private String username;
    private String colorHex;
}

