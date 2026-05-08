package com.gunes.DunyaUlkeleri.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

//bir kullanıcı şifresini unutunca şifremi unuttum butonuna basar ve bu paket bize gönderilir
@Data
public class ResetPasswordRequest{
    @NotBlank(message = "E-posta veya kullanıcı adı boş olamaz")
    private String email;
}
