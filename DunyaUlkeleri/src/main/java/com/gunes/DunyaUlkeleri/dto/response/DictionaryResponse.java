package com.gunes.DunyaUlkeleri.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class DictionaryResponse {
    private String countryName;
    private String capitalName;
    private String continent;
}