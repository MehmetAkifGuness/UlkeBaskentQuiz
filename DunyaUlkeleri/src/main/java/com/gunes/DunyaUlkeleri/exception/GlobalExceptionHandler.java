package com.gunes.DunyaUlkeleri.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

// @RestControllerAdvice: Bu sınıf bütün projeyi bir "şemsiye" gibi korur.
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleAllExceptions(Exception ex) {
        Map<String, String> errorResponse = new HashMap<>();
        errorResponse.put("message", ex.getMessage());
        errorResponse.put("status", "error");
        
        // Flutter artık bu JSON'ı okuyup kullanıcıya mesaj gösterebilir
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }
}