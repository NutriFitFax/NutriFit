package com.nutrifit.backend.controller;

import java.io.IOException;
import java.util.Set;

import com.nutrifit.backend.config.AppSettings;
import com.nutrifit.backend.model.MealEstimate;
import com.nutrifit.backend.service.MealEstimator;
import com.nutrifit.backend.service.MealEstimatorException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class MealController {
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
            MediaType.IMAGE_JPEG_VALUE,
            "image/jpg",
            MediaType.IMAGE_PNG_VALUE,
            "image/webp"
    );

    private final AppSettings settings;
    private final MealEstimator mealEstimator;

    public MealController(AppSettings settings, MealEstimator mealEstimator) {
        this.settings = settings;
        this.mealEstimator = mealEstimator;
    }

    @PostMapping(path = "/estimate-meal", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public MealEstimate estimateMeal(@RequestPart("image") MultipartFile image) {
        String contentType = image.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new ResponseStatusException(HttpStatus.UNSUPPORTED_MEDIA_TYPE,
                    "unsupported content_type: " + contentType);
        }
        if (image.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "empty image upload");
        }
        if (image.getSize() > settings.maxUploadBytes()) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE,
                    "image exceeds " + settings.maxUploadBytes() + " bytes");
        }
        try {
            return mealEstimator.estimate(image.getBytes(), contentType);
        } catch (IOException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "could not read image upload", ex);
        } catch (MealEstimatorException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, ex.getMessage(), ex);
        }
    }
}
