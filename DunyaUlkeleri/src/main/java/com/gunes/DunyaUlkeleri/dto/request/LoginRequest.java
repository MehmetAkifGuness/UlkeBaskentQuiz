package com.gunes.DunyaUlkeleri.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
//kullanıcı giriş yapmak istediğinde bize göndereceği paket
@Data
public class LoginRequest {
    @NotBlank(message = "Kullanıcı adı boş olamaz")
    private String username;

    @NotBlank(message = "Şifre boş olamaz")
    private String password;
}
