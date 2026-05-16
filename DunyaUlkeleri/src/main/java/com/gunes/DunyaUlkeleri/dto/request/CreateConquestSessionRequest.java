package com.gunes.DunyaUlkeleri.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateConquestSessionRequest {
    private String username;
    private String colorHex;
    private String continentFilter;
}

