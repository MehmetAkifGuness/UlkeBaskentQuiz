package com.gunes.DunyaUlkeleri.util.exception;

import com.fasterxml.jackson.annotation.JsonInclude;
import org.springframework.http.HttpStatus;

import java.time.Instant;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiErrorResponse(
        Instant timestamp,
        int status,
        String error,
        String code,
        String message,
        String path,
        Map<String, Object> details
) {
    public static ApiErrorResponse of(
            HttpStatus httpStatus,
            String code,
            String message,
            String path,
            Map<String, Object> details
    ) {
        return new ApiErrorResponse(
                Instant.now(),
                httpStatus.value(),
                httpStatus.getReasonPhrase(),
                code,
                message,
                path,
                details
        );
    }
}

