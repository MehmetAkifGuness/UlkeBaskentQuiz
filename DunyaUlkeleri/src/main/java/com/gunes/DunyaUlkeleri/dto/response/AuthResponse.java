package com.gunes.DunyaUlkeleri.dto.response;

import lombok.Data;

// kullanıcı giriş yaptığında ya da kayıt olduğunda işlem başarılı ise sisteme giriş izni vermek için kullanılan sınıf
@Data
public class AuthResponse {
    private String token;
    private String username;
    private String message;
}
