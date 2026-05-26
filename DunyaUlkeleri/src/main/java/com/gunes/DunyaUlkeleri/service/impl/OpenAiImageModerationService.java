package com.gunes.DunyaUlkeleri.service.impl;

import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.gunes.DunyaUlkeleri.service.ImageModerationResult;
import com.gunes.DunyaUlkeleri.service.ImageModerationService;
import com.gunes.DunyaUlkeleri.util.exception.AppException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class OpenAiImageModerationService implements ImageModerationService {

    private static final String DEFAULT_MODEL = "omni-moderation-latest";

    private final RestClient.Builder restClientBuilder;

    @Value("${OPENAI_API_KEY:}")
    private String apiKey;

    @Value("${app.openai.moderation.model:" + DEFAULT_MODEL + "}")
    private String model;

    @Override
    public ImageModerationResult moderateProfileImage(byte[] imageBytes, String contentType) {
        if (imageBytes == null || imageBytes.length == 0) {
            throw AppException.badRequest("AVATAR_IMAGE_REQUIRED", "Profil fotoğrafı boş olamaz.");
        }

        if (apiKey == null || apiKey.isBlank()) {
            return ImageModerationResult.allowAll();
        }

        String mimeType = (contentType == null || contentType.isBlank()) ? "image/jpeg" : contentType;
        String dataUrl = buildDataUrl(mimeType, imageBytes);

        Map<String, Object> requestBody = Map.of(
                "model", safeModel(),
                "input", List.of(
                        Map.of(
                                "type", "image_url",
                                "image_url", Map.of("url", dataUrl)
                        )
                )
        );

        try {
            RestClient restClient = restClientBuilder.build();
            OpenAiModerationResponse response = restClient.post()
                    .uri("https://api.openai.com/v1/moderations")
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey)
                    .body(requestBody)
                    .retrieve()
                    .body(OpenAiModerationResponse.class);

            boolean flagged = response != null
                    && response.results != null
                    && !response.results.isEmpty()
                    && Boolean.TRUE.equals(response.results.get(0).flagged);
            Map<String, Boolean> categories = response != null
                    && response.results != null
                    && !response.results.isEmpty()
                    && response.results.get(0).categories != null
                    ? response.results.get(0).categories
                    : Map.of();

            return new ImageModerationResult(!flagged, flagged, categories);
        } catch (Exception e) {
            throw new AppException(
                    org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR,
                    "MODERATION_UNAVAILABLE",
                    "Profil fotoğrafı moderasyon servisine ulaşılamadı. Lütfen daha sonra tekrar deneyin."
            );
        }
    }

    private String safeModel() {
        String m = (model == null || model.isBlank()) ? DEFAULT_MODEL : model.trim();
        return m;
    }

    private static String buildDataUrl(String mimeType, byte[] bytes) {
        String base64 = Base64.getEncoder().encodeToString(bytes);
        return "data:" + mimeType + ";base64," + base64;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static final class OpenAiModerationResponse {
        public List<OpenAiModerationResult> results;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static final class OpenAiModerationResult {
        public Boolean flagged;
        public Map<String, Boolean> categories;
    }
}
