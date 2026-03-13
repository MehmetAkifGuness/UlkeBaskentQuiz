package com.gunes.DunyaUlkeleri.dto.request;

import lombok.Data;
//kullanıcı giriş yapmak istediğinde bize göndereceği paket
@Data
public class LoginRequest {
    private String username;
    private String password;
}
