package com.gunes.DunyaUlkeleri.dto.request;

import lombok.Data;

//emaile gelen kodu girip doğrula diyince bize gelen paket
//hangi kullanıcı hangi kodu gönderdi bunlar gerekli
@Data
public class VerifyCodeRequest {
    private String email;
    private String code;
}
