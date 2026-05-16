package com.nutrifit.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    private final AppSettings settings;

    public WebConfig(AppSettings settings) {
        this.settings = settings;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        var origins = settings.corsOrigins().isEmpty()
                ? new String[]{"*"}
                : settings.corsOrigins().toArray(String[]::new);
        registry.addMapping("/**")
                .allowedOrigins(origins)
                .allowedMethods("GET", "POST", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(false);
    }
}
