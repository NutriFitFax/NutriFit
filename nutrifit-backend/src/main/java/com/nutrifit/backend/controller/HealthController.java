package com.nutrifit.backend.controller;

import com.nutrifit.backend.config.AppSettings;
import com.nutrifit.backend.model.HealthResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    private final AppSettings settings;

    public HealthController(AppSettings settings) {
        this.settings = settings;
    }

    @GetMapping({"/", "/health"})
    public HealthResponse health() {
        return new HealthResponse("ok", settings.environment(), AppSettings.VERSION);
    }
}
