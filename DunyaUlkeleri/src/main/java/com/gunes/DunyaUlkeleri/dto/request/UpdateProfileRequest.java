package com.gunes.DunyaUlkeleri.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileRequest {

    @NotBlank(message = "İsim (displayName) boş olamaz.")
    @Size(max = 40, message = "İsim (displayName) en fazla 40 karakter olabilir.")
    private String displayName;
}

