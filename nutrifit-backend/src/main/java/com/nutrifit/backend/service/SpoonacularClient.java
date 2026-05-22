package com.nutrifit.backend.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import com.fasterxml.jackson.databind.JsonNode;
import com.nutrifit.backend.config.AppSettings;
import com.nutrifit.backend.model.MealPlanResponse;
import com.nutrifit.backend.model.PlannedMeal;
import com.nutrifit.backend.model.RecipeDetails;
import com.nutrifit.backend.model.RecipeNutrients;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

@Service
public class SpoonacularClient {
    private static final String SOURCE = "spoonacular";

    private final AppSettings settings;
    private final RestClient restClient;

    public SpoonacularClient(AppSettings settings, RestClient.Builder builder) {
        this.settings = settings;
        this.restClient = builder
                .baseUrl(settings.spoonacularBaseUrl())
                .defaultHeader(HttpHeaders.USER_AGENT, settings.userAgent())
                .build();
    }

    public MealPlanResponse generateMealPlan(String timeFrame, Integer targetCalories, String diet) {
        requireApiKey();
        String normalizedTimeFrame = normalizeTimeFrame(timeFrame);
        String normalizedDiet = blankToNull(diet);
        JsonNode data;
        try {
            data = restClient.get()
                    .uri(uriBuilder -> {
                        var builder = uriBuilder
                                .path("/mealplanner/generate")
                                .queryParam("apiKey", settings.spoonacularApiKey())
                                .queryParam("timeFrame", normalizedTimeFrame);
                        if (targetCalories != null) {
                            builder.queryParam("targetCalories", targetCalories);
                        }
                        if (normalizedDiet != null) {
                            builder.queryParam("diet", normalizedDiet);
                        }
                        return builder.build();
                    })
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientResponseException ex) {
            throw new SpoonacularException("spoonacular error: HTTP " + ex.getStatusCode().value(), ex);
        } catch (RestClientException ex) {
            throw new SpoonacularException("spoonacular error: request failed", ex);
        }

        List<PlannedMeal> meals = new ArrayList<>();
        JsonNode rawMeals = data == null ? null : data.path("meals");
        if (rawMeals != null && rawMeals.isArray()) {
            for (JsonNode raw : rawMeals) {
                PlannedMeal meal = toPlannedMeal(raw);
                if (meal != null) {
                    meals.add(meal);
                }
            }
        }
        RecipeNutrients nutrients = nutrientsFromMealPlan(data == null ? null : data.path("nutrients"));
        return new MealPlanResponse(normalizedTimeFrame, targetCalories, normalizedDiet, meals, nutrients, SOURCE);
    }

    public RecipeDetails getRecipeDetails(String id) {
        requireApiKey();
        JsonNode data;
        try {
            data = restClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/recipes/{id}/information")
                            .queryParam("apiKey", settings.spoonacularApiKey())
                            .queryParam("includeNutrition", true)
                            .build(id))
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientResponseException ex) {
            throw new SpoonacularException("spoonacular error: HTTP " + ex.getStatusCode().value(), ex);
        } catch (RestClientException ex) {
            throw new SpoonacularException("spoonacular error: request failed", ex);
        }

        if (data == null || data.isMissingNode() || data.isNull()) {
            throw new SpoonacularException("spoonacular error: empty response");
        }
        return new RecipeDetails(
                text(data, "id"),
                text(data, "title"),
                firstText(data, "image"),
                optionalInt(data, "readyInMinutes"),
                optionalInt(data, "servings"),
                firstText(data, "sourceUrl", "spoonacularSourceUrl"),
                ingredients(data.path("extendedIngredients")),
                nutrientsFromRecipe(data.path("nutrition").path("nutrients"))
        );
    }

    private void requireApiKey() {
        if (settings.spoonacularApiKey() == null) {
            throw SpoonacularException.configuration("SPOONACULAR_API_KEY is not configured");
        }
    }

    private static String normalizeTimeFrame(String timeFrame) {
        if (timeFrame == null || timeFrame.isBlank()) {
            return "day";
        }
        return timeFrame.toLowerCase(Locale.ROOT).trim();
    }

    private static PlannedMeal toPlannedMeal(JsonNode meal) {
        String id = text(meal, "id");
        String title = text(meal, "title");
        if (id == null || id.isBlank() || title == null || title.isBlank()) {
            return null;
        }
        return new PlannedMeal(
                id,
                title.trim(),
                imageUrl(id, meal),
                optionalInt(meal, "readyInMinutes"),
                optionalInt(meal, "servings"),
                firstText(meal, "sourceUrl", "spoonacularSourceUrl")
        );
    }

    private static String imageUrl(String id, JsonNode node) {
        String explicit = firstText(node, "image", "imageUrl");
        if (explicit != null) {
            return explicit;
        }
        String imageType = text(node, "imageType");
        if (imageType == null || imageType.isBlank()) {
            return null;
        }
        return "https://img.spoonacular.com/recipes/" + id + "-312x231." + imageType;
    }

    private static RecipeNutrients nutrientsFromMealPlan(JsonNode nutrients) {
        return new RecipeNutrients(
                valueOrZero(optionalDouble(nutrients, "calories")),
                valueOrZero(optionalDouble(nutrients, "protein")),
                valueOrZero(optionalDouble(nutrients, "carbohydrates")),
                valueOrZero(optionalDouble(nutrients, "fat"))
        );
    }

    private static RecipeNutrients nutrientsFromRecipe(JsonNode nutrients) {
        return new RecipeNutrients(
                valueOrZero(nutrientAmount(nutrients, "Calories")),
                valueOrZero(nutrientAmount(nutrients, "Protein")),
                valueOrZero(nutrientAmount(nutrients, "Carbohydrates")),
                valueOrZero(nutrientAmount(nutrients, "Fat"))
        );
    }

    private static Double nutrientAmount(JsonNode nutrients, String name) {
        if (nutrients == null || !nutrients.isArray()) {
            return null;
        }
        for (JsonNode nutrient : nutrients) {
            String nutrientName = text(nutrient, "name");
            if (nutrientName != null && nutrientName.equalsIgnoreCase(name)) {
                return optionalDouble(nutrient, "amount");
            }
        }
        return null;
    }

    private static List<String> ingredients(JsonNode rawIngredients) {
        if (!rawIngredients.isArray()) {
            return List.of();
        }
        List<String> ingredients = new ArrayList<>();
        for (JsonNode raw : rawIngredients) {
            String ingredient = firstText(raw, "original", "name");
            if (ingredient != null && !ingredient.isBlank()) {
                ingredients.add(ingredient.trim());
            }
        }
        return ingredients;
    }

    private static String firstText(JsonNode node, String... fields) {
        for (String field : fields) {
            String value = text(node, field);
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }

    private static String text(JsonNode node, String field) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode value = node.path(field);
        if (value.isMissingNode() || value.isNull()) {
            return null;
        }
        return value.asText();
    }

    private static Integer optionalInt(JsonNode node, String field) {
        Double value = optionalDouble(node, field);
        return value == null ? null : value.intValue();
    }

    private static Double optionalDouble(JsonNode node, String field) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode value = node.path(field);
        if (value.isMissingNode() || value.isNull()) {
            return null;
        }
        try {
            String text = value.asText();
            if (text == null || text.isBlank()) {
                return null;
            }
            return Math.max(Double.parseDouble(text), 0.0);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static double valueOrZero(Double value) {
        return value == null ? 0.0 : value;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
