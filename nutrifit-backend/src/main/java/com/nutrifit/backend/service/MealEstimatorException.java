package com.nutrifit.backend.service;

public class MealEstimatorException extends RuntimeException {
    public MealEstimatorException(String message) {
        super(message);
    }

    public MealEstimatorException(String message, Throwable cause) {
        super(message, cause);
    }
}
