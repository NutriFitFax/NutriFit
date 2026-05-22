package com.nutrifit.backend.service;

import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nutrifit.backend.config.AppSettings;
import com.nutrifit.backend.model.EstimatedFood;
import com.nutrifit.backend.model.Macros;
import com.nutrifit.backend.model.MealEstimate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class MealEstimator {
    private static final String NO_OPENAI_KEY_NOTE =
            "OPENAI_API_KEY not set - returning deterministic stub estimate.";
    private static final String OPENAI_FAILURE_NOTE =
            "OpenAI estimation failed - returning deterministic stub estimate.";

    private static final String PROMPT = """
            You are a nutrition assistant. Identify the foods in this meal photo.
            Reply with ONLY valid JSON of this shape:
            {"items":[{"name":str,"estimated_grams":number,"confidence":number 0..1,"macros_per_100g":{"calories_kcal":number,"protein_g":number,"carbs_g":number,"fat_g":number}}]}
            If unsure, still return a best guess; never include prose outside JSON.
            """;

    private static final List<EstimatedFood> STUB_ITEMS = List.of(
            new EstimatedFood("Grilled chicken breast", 150.0, 0.6,
                    new Macros(165, 31, 0, 3.6, null, null, null)),
            new EstimatedFood("Steamed rice", 180.0, 0.55,
                    new Macros(130, 2.7, 28, 0.3, null, null, null)),
            new EstimatedFood("Mixed vegetables", 90.0, 0.5,
                    new Macros(65, 2.5, 13, 0.5, null, null, null))
    );

    private final AppSettings settings;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;

    public MealEstimator(AppSettings settings, ObjectMapper objectMapper, RestClient.Builder builder) {
        this.settings = settings;
        this.objectMapper = objectMapper;
        this.restClient = builder.build();
    }

    public MealEstimate estimate(byte[] imageBytes, String contentType) {
        if (settings.openAiApiKey() == null) {
            return stub(NO_OPENAI_KEY_NOTE);
        }
        try {
            List<EstimatedFood> items = callOpenAi(imageBytes, contentType == null ? "image/jpeg" : contentType);
            Totals totals = totals(items);
            return new MealEstimate(items, totals.calories(), totals.protein(), totals.carbs(), totals.fat(), "ai", null);
        } catch (MealEstimatorException ex) {
            return stub(OPENAI_FAILURE_NOTE);
        }
    }

    private MealEstimate stub(String notes) {
        Totals totals = totals(STUB_ITEMS);
        return new MealEstimate(
                STUB_ITEMS,
                totals.calories(),
                totals.protein(),
                totals.carbs(),
                totals.fat(),
                "stub",
                notes
        );
    }

    private List<EstimatedFood> callOpenAi(byte[] imageBytes, String contentType) {
        String base64 = Base64.getEncoder().encodeToString(imageBytes);
        Map<String, Object> payload = Map.of(
                "model", settings.openAiModel(),
                "messages", List.of(Map.of(
                        "role", "user",
                        "content", List.of(
                                Map.of("type", "text", "text", PROMPT),
                                Map.of("type", "image_url", "image_url",
                                        Map.of("url", "data:%s;base64,%s".formatted(contentType, base64)))
                        )
                )),
                "response_format", Map.of("type", "json_object"),
                "temperature", 0.2
        );

        JsonNode body;
        try {
            body = restClient.post()
                    .uri("https://api.openai.com/v1/chat/completions")
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + settings.openAiApiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(payload)
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientException ex) {
            throw new MealEstimatorException("openai error: " + ex.getMessage(), ex);
        }
        String content = body == null ? null : body.path("choices").path(0).path("message").path("content").asText(null);
        if (content == null || content.isBlank()) {
            throw new MealEstimatorException("bad openai response: missing content");
        }
        try {
            JsonNode parsed = objectMapper.readTree(content);
            JsonNode rawItems = parsed.path("items");
            if (!rawItems.isArray()) {
                throw new MealEstimatorException("bad openai response: missing items");
            }
            List<EstimatedFood> items = new ArrayList<>();
            for (JsonNode raw : rawItems) {
                try {
                    EstimatedFood item = objectMapper.treeToValue(raw, EstimatedFood.class);
                    if (isUsable(item)) {
                        items.add(item);
                    }
                } catch (JsonProcessingException ignored) {
                    // Skip malformed items and keep any parseable results.
                }
            }
            if (items.isEmpty()) {
                throw new MealEstimatorException("no parseable items in openai response");
            }
            return items;
        } catch (JsonProcessingException ex) {
            throw new MealEstimatorException("bad openai response: " + ex.getMessage(), ex);
        }
    }

    private static boolean isUsable(EstimatedFood item) {
        if (item == null || item.name() == null || item.name().isBlank() || item.macrosPer100g() == null) {
            return false;
        }
        Macros macros = item.macrosPer100g();
        return Double.isFinite(item.estimatedGrams())
                && item.estimatedGrams() > 0
                && Double.isFinite(item.confidence())
                && Double.isFinite(macros.caloriesKcal())
                && Double.isFinite(macros.proteinG())
                && Double.isFinite(macros.carbsG())
                && Double.isFinite(macros.fatG());
    }

    private static Totals totals(List<EstimatedFood> items) {
        double calories = 0;
        double protein = 0;
        double carbs = 0;
        double fat = 0;
        for (EstimatedFood item : items) {
            double factor = item.estimatedGrams() / 100.0;
            calories += item.macrosPer100g().caloriesKcal() * factor;
            protein += item.macrosPer100g().proteinG() * factor;
            carbs += item.macrosPer100g().carbsG() * factor;
            fat += item.macrosPer100g().fatG() * factor;
        }
        return new Totals(round1(calories), round1(protein), round1(carbs), round1(fat));
    }

    private static double round1(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private record Totals(double calories, double protein, double carbs, double fat) {
    }
}
