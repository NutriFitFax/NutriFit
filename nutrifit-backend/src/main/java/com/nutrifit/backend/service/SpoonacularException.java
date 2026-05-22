package com.nutrifit.backend.service;

public class SpoonacularException extends RuntimeException {
    private final boolean configurationError;

    public SpoonacularException(String message) {
        this(message, null, false);
    }

    public SpoonacularException(String message, Throwable cause) {
        this(message, cause, false);
    }

    private SpoonacularException(String message, Throwable cause, boolean configurationError) {
        super(message, cause);
        this.configurationError = configurationError;
    }

    public static SpoonacularException configuration(String message) {
        return new SpoonacularException(message, null, true);
    }

    public boolean configurationError() {
        return configurationError;
    }
}
