package com.gunes.DunyaUlkeleri;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration; // GÜVENLİK İÇİN EKLENDİ
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

// DİKKAT: exclude parametresi ile Spring'in kendi kendine şifre üretmesini YASAKLIYORUZ!
@SpringBootApplication(exclude = {UserDetailsServiceAutoConfiguration.class})
@EnableScheduling
@EnableAsync
public class DunyaUlkeleriApplication {
    public static void main(String[] args) {
        SpringApplication.run(DunyaUlkeleriApplication.class, args);
    }
}