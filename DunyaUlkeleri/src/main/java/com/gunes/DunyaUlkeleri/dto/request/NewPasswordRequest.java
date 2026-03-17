package com.gunes.DunyaUlkeleri.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class NewPasswordRequest {
    @NotBlank(message = "E-posta boş olamaz!")
    private String email;

    @NotBlank(message = "Doğrulama kodu boş olamaz!")
    private String resetCode;

    @NotBlank(message = "Yeni şifre boş olamaz!")
    @Size(min = 6, message = "Yeni şifre en az 6 karakter olmalıdır!")
    private String newPassword;
}