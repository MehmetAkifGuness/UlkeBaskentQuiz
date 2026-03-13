package com.gunes.DunyaUlkeleri.security;

import java.security.SecureRandom;

public class CodeGenerator {
    public static String generateVerificationCode(){
        SecureRandom random = new SecureRandom();
        int number = random.nextInt(999999);
        return String.format("%06d" , number); // sayı 6 haneden azsa başına sıfır ekler
    }
}
