package com.nutrifit.backend.config;

import java.util.Arrays;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class AppSettings {
    public static final String VERSION = "0.1.0";

    private final String environment;
    private final List<String> corsOrigins;
    private final String usdaBaseUrl;
    private final String usdaApiKey;
    private final String openFoodFactsBaseUrl;
    private final String spoonacularBaseUrl;
    private final String spoonacularApiKey;
    private final double httpTimeoutSeconds;
    private final String openAiApiKey;
    private final String openAiModel;
    private final long maxUploadBytes;
    private final String userAgent;

    public AppSettings(
            @Value("${ENVIRONMENT:development}") String environment,
            @Value("${CORS_ORIGINS:*}") String corsOrigins,
            @Value("${USDA_BASE_URL:https://api.nal.usda.gov/fdc/v1}") String usdaBaseUrl,
            @Value("${USDA_API_KEY:DEMO_KEY}") String usdaApiKey,
            @Value("${OPENFOODFACTS_BASE_URL:https://world.openfoodfacts.org}") String openFoodFactsBaseUrl,
            @Value("${SPOONACULAR_BASE_URL:https://api.spoonacular.com}") String spoonacularBaseUrl,
            @Value("${SPOONACULAR_API_KEY:}") String spoonacularApiKey,
            @Value("${HTTP_TIMEOUT:8.0}") double httpTimeoutSeconds,
            @Value("${OPENAI_API_KEY:}") String openAiApiKey,
            @Value("${OPENAI_MODEL:gpt-4o}") String openAiModel,
            @Value("${MAX_UPLOAD_BYTES:8388608}") long maxUploadBytes,
            @Value("${HTTP_USER_AGENT:NutriFit/0.1 (student project; contact: teamwork@loveiq.org)}") String userAgent
    ) {
        this.environment = environment;
        this.corsOrigins = parseCsv(corsOrigins);
        this.usdaBaseUrl = usdaBaseUrl;
        this.usdaApiKey = usdaApiKey == null || usdaApiKey.isBlank() ? "DEMO_KEY" : usdaApiKey;
        this.openFoodFactsBaseUrl = openFoodFactsBaseUrl;
        this.spoonacularBaseUrl = spoonacularBaseUrl;
        this.spoonacularApiKey = spoonacularApiKey == null || spoonacularApiKey.isBlank() ? null : spoonacularApiKey;
        this.httpTimeoutSeconds = httpTimeoutSeconds;
        this.openAiApiKey = openAiApiKey == null || openAiApiKey.isBlank() ? null : openAiApiKey;
        this.openAiModel = openAiModel;
        this.maxUploadBytes = maxUploadBytes;
        this.userAgent = userAgent;
    }

    private static List<String> parseCsv(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        return Arrays.stream(value.split(","))
                .map(String::trim)
                .filter(part -> !part.isEmpty())
                .toList();
    }

    public String environment() {
        return environment;
    }

    public List<String> corsOrigins() {
        return corsOrigins;
    }

    public String usdaBaseUrl() {
        return usdaBaseUrl;
    }

    public String usdaApiKey() {
        return usdaApiKey;
    }

    public String openFoodFactsBaseUrl() {
        return openFoodFactsBaseUrl;
    }

    public String spoonacularBaseUrl() {
        return spoonacularBaseUrl;
    }

    public String spoonacularApiKey() {
        return spoonacularApiKey;
    }

    public double httpTimeoutSeconds() {
        return httpTimeoutSeconds;
    }

    public String openAiApiKey() {
        return openAiApiKey;
    }

    public String openAiModel() {
        return openAiModel;
    }

    public long maxUploadBytes() {
        return maxUploadBytes;
    }

    public String userAgent() {
        return userAgent;
    }
}
