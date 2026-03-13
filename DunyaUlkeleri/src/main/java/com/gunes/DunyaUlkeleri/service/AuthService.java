package com.gunes.DunyaUlkeleri.service;

import com.gunes.DunyaUlkeleri.dto.request.LoginRequest;
import com.gunes.DunyaUlkeleri.dto.request.RegisterRequest;
import com.gunes.DunyaUlkeleri.dto.request.ResetPasswordRequest;
import com.gunes.DunyaUlkeleri.dto.request.VerifyCodeRequest;
import com.gunes.DunyaUlkeleri.dto.response.AuthResponse;

//kullanıcı giriş ve kayıt fonksiyonları burada olacak 
public interface AuthService {

    //sürekli authresponse kullanmamızın sebebi authresponse sınıfının giriş başarılı olunca sisteme yönlendiriyor ya

    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse guestLogin();

    AuthResponse verifyEmail(VerifyCodeRequest request);

    AuthResponse forgotPassword(ResetPasswordRequest request);
}
