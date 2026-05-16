package com.gunes.DunyaUlkeleri.util.exception;

import org.springframework.http.HttpStatus;

import java.util.Map;

public class AppException extends RuntimeException {

    private final HttpStatus status;
    private final String code;
    private final Map<String, Object> details;

    public AppException(HttpStatus status, String code, String message) {
        this(status, code, message, null);
    }

    public AppException(HttpStatus status, String code, String message, Map<String, Object> details) {
        super(message);
        this.status = status;
        this.code = code;
        this.details = details;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getCode() {
        return code;
    }

    public Map<String, Object> getDetails() {
        return details;
    }

    public static AppException badRequest(String code, String message) {
        return new AppException(HttpStatus.BAD_REQUEST, code, message);
    }

    public static AppException unauthorized(String code, String message) {
        return new AppException(HttpStatus.UNAUTHORIZED, code, message);
    }

    public static AppException forbidden(String code, String message) {
        return new AppException(HttpStatus.FORBIDDEN, code, message);
    }

    public static AppException notFound(String code, String message) {
        return new AppException(HttpStatus.NOT_FOUND, code, message);
    }

    public static AppException conflict(String code, String message) {
        return new AppException(HttpStatus.CONFLICT, code, message);
    }

    public static AppException tooManyRequests(String code, String message) {
        return new AppException(HttpStatus.TOO_MANY_REQUESTS, code, message);
    }
}
