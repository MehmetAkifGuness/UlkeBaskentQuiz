package com.gunes.DunyaUlkeleri.dto.request;

import lombok.Data;

//bir kullanıcı şifresini unutunca şifremi unuttum butonuna basar ve bu paket bize gönderilir
@Data
public class ResetPasswordRequest{
    private String email;
}
