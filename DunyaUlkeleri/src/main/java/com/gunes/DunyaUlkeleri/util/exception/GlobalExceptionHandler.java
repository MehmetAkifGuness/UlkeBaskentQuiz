package com.gunes.DunyaUlkeleri.util.exception;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.LinkedHashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(AppException.class)
    public ResponseEntity<ApiErrorResponse> handleAppException(AppException e, HttpServletRequest request) {
        ApiErrorResponse response = ApiErrorResponse.of(
                e.getStatus(),
                e.getCode(),
                e.getMessage(),
                request.getRequestURI(),
                e.getDetails()
        );
        return ResponseEntity.status(e.getStatus()).body(response);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiErrorResponse> handleMethodArgumentNotValid(
            MethodArgumentNotValidException e,
            HttpServletRequest request
    ) {
        Map<String, Object> details = new LinkedHashMap<>();
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError fieldError : e.getBindingResult().getFieldErrors()) {
            fields.putIfAbsent(fieldError.getField(), fieldError.getDefaultMessage());
        }
        details.put("fields", fields);

        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.BAD_REQUEST,
                "VALIDATION_ERROR",
                "Gönderilen bilgiler geçersiz. Lütfen alanları kontrol edin.",
                request.getRequestURI(),
                details
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiErrorResponse> handleConstraintViolation(
            ConstraintViolationException e,
            HttpServletRequest request
    ) {
        Map<String, Object> details = new LinkedHashMap<>();
        Map<String, String> violations = new LinkedHashMap<>();
        e.getConstraintViolations().forEach(v -> violations.put(v.getPropertyPath().toString(), v.getMessage()));
        details.put("violations", violations);

        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.BAD_REQUEST,
                "VALIDATION_ERROR",
                "Gönderilen bilgiler geçersiz.",
                request.getRequestURI(),
                details
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiErrorResponse> handleHttpMessageNotReadable(
            HttpMessageNotReadableException e,
            HttpServletRequest request
    ) {
        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.BAD_REQUEST,
                "BAD_REQUEST",
                "İstek gövdesi okunamadı. Lütfen gönderdiğiniz JSON formatını kontrol edin.",
                request.getRequestURI(),
                null
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiErrorResponse> handleMissingServletRequestParameter(
            MissingServletRequestParameterException e,
            HttpServletRequest request
    ) {
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("parameter", e.getParameterName());

        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.BAD_REQUEST,
                "BAD_REQUEST",
                "Eksik parametre: " + e.getParameterName(),
                request.getRequestURI(),
                details
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiErrorResponse> handleMethodArgumentTypeMismatch(
            MethodArgumentTypeMismatchException e,
            HttpServletRequest request
    ) {
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("parameter", e.getName());
        details.put("value", e.getValue());

        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.BAD_REQUEST,
                "BAD_REQUEST",
                "Parametre tipi hatalı: " + e.getName(),
                request.getRequestURI(),
                details
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiErrorResponse> handleMethodNotSupported(
            HttpRequestMethodNotSupportedException e,
            HttpServletRequest request
    ) {
        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.METHOD_NOT_ALLOWED,
                "METHOD_NOT_ALLOWED",
                "Bu endpoint bu HTTP metodunu desteklemiyor.",
                request.getRequestURI(),
                null
        );
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(response);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiErrorResponse> handleAccessDenied(AccessDeniedException e, HttpServletRequest request) {
        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.FORBIDDEN,
                "FORBIDDEN",
                "Bu işlem için yetkiniz yok.",
                request.getRequestURI(),
                null
        );
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
    }

    @ExceptionHandler({IllegalArgumentException.class, IllegalStateException.class})
    public ResponseEntity<ApiErrorResponse> handleKnownBadRequest(RuntimeException e, HttpServletRequest request) {
        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.BAD_REQUEST,
                "BAD_REQUEST",
                e.getMessage(),
                request.getRequestURI(),
                null
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGlobalException(Exception e, HttpServletRequest request) {
        log.error("Beklenmeyen hata: {}", e.getMessage(), e);

        ApiErrorResponse response = ApiErrorResponse.of(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR",
                "Sunucu tarafında beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.",
                request.getRequestURI(),
                null
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}

