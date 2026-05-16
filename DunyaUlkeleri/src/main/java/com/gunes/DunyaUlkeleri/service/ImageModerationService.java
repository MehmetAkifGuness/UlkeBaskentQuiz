package com.gunes.DunyaUlkeleri.service;

public interface ImageModerationService {

    ImageModerationResult moderateProfileImage(byte[] imageBytes, String contentType);
}

