package com.nutrifit.backend.model;

public record DatabaseHealthResponse(boolean configured, boolean ok, String error) {
    public static DatabaseHealthResponse notConfigured() {
        return new DatabaseHealthResponse(false, false, null);
    }

    public static DatabaseHealthResponse healthy() {
        return new DatabaseHealthResponse(true, true, null);
    }

    public static DatabaseHealthResponse unhealthy(String error) {
        return new DatabaseHealthResponse(true, false, error);
    }
}
