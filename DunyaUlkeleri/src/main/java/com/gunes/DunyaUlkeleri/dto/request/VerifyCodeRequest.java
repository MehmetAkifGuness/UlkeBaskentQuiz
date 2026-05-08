package com.gunes.DunyaUlkeleri.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

//emaile gelen kodu girip doğrula diyince bize gelen paket
//hangi kullanıcı hangi kodu gönderdi bunlar gerekli
@Data
public class VerifyCodeRequest {
    @Email(message = "Geçerli bir e-posta adresi giriniz")
    @NotBlank(message = "E-posta boş olamaz")
    private String email;

    @NotBlank(message = "Doğrulama kodu boş olamaz")
    @Size(min = 6, max = 6, message = "Doğrulama kodu 6 haneli olmalıdır")
    private String code;
}
