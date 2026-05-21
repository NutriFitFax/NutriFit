package com.nutrifit.backend.service;

public class UsdaFoodDataException extends RuntimeException {
    public UsdaFoodDataException(String message) {
        super(message);
    }

    public UsdaFoodDataException(String message, Throwable cause) {
        super(message, cause);
    }
}
