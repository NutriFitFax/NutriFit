package com.nutrifit.backend.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

import com.fasterxml.jackson.databind.JsonNode;
import com.nutrifit.backend.config.AppSettings;
import com.nutrifit.backend.model.Food;
import com.nutrifit.backend.model.Macros;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class UsdaFoodDataClient {
    private static final Pattern NON_DIGIT = Pattern.compile("\\D+");

    private static final String CALORIES = "208";
    private static final String PROTEIN = "203";
    private static final String FAT = "204";
    private static final String CARBS = "205";
    private static final String SUGARS = "269";
    private static final String FIBER = "291";
    private static final String SODIUM = "307";

    private final AppSettings settings;
    private final RestClient restClient;

    public UsdaFoodDataClient(AppSettings settings, RestClient.Builder builder) {
        this.settings = settings;
        this.restClient = builder
                .baseUrl(settings.usdaBaseUrl())
                .defaultHeader(HttpHeaders.USER_AGENT, settings.userAgent())
                .build();
    }

    public Food getByBarcode(String barcode) {
        JsonNode data = executeSearch(barcode, 1, 10, List.of("Branded"));
        if (data == null) {
            return null;
        }
        JsonNode foods = data.path("foods");
        if (!foods.isArray()) {
            return null;
        }
        for (JsonNode food : foods) {
            if (barcodeMatches(barcode, text(food, "gtinUpc"))) {
                return toFood(food);
            }
        }
        return null;
    }

    public SearchResponse search(String query, int page, int pageSize) {
        JsonNode data = executeSearch(query, page, pageSize, List.of());
        if (data == null) {
            return new SearchResponse(List.of(), 0);
        }
        JsonNode foods = data.path("foods");
        List<Food> items = new ArrayList<>();
        if (foods.isArray()) {
            for (JsonNode raw : foods) {
                Food food = toFood(raw);
                if (food != null) {
                    items.add(food);
                }
            }
        }
        int total = data.path("totalHits").asInt(items.size());
        return new SearchResponse(items, total);
    }

    private JsonNode executeSearch(String query, int page, int pageSize, List<String> dataTypes) {
        try {
            return restClient.get()
                    .uri(uriBuilder -> {
                        var builder = uriBuilder
                                .path("/foods/search")
                                .queryParam("api_key", settings.usdaApiKey())
                                .queryParam("query", query)
                                .queryParam("pageNumber", page)
                                .queryParam("pageSize", pageSize);
                        if (!dataTypes.isEmpty()) {
                            builder.queryParam("dataType", String.join(",", dataTypes));
                        }
                        return builder.build();
                    })
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientException ex) {
            throw new UsdaFoodDataException("usda error: " + ex.getMessage(), ex);
        }
    }

    private static Food toFood(JsonNode food) {
        if (food == null || food.isMissingNode() || food.isNull()) {
            return null;
        }
        String id = text(food, "fdcId");
        String name = text(food, "description");
        if (id == null || id.isBlank() || name == null || name.isBlank()) {
            return null;
        }
        return new Food(
                id,
                name.trim(),
                firstText(food, "brandName", "brandOwner"),
                null,
                servingSizeG(food),
                buildMacros(food.path("foodNutrients"))
        );
    }

    private static Macros buildMacros(JsonNode foodNutrients) {
        Double sodiumMg = nutrientAmount(foodNutrients, SODIUM);
        Double saltG = sodiumMg == null ? null : sodiumMg * 2.5 / 1000.0;
        return new Macros(
                valueOrZero(nutrientAmount(foodNutrients, CALORIES, "2047", "2048")),
                valueOrZero(nutrientAmount(foodNutrients, PROTEIN)),
                valueOrZero(nutrientAmount(foodNutrients, CARBS)),
                valueOrZero(nutrientAmount(foodNutrients, FAT)),
                nutrientAmount(foodNutrients, FIBER),
                nutrientAmount(foodNutrients, SUGARS),
                saltG
        );
    }

    private static Double nutrientAmount(JsonNode foodNutrients, String... nutrientNumbers) {
        if (!foodNutrients.isArray()) {
            return null;
        }
        for (String nutrientNumber : nutrientNumbers) {
            for (JsonNode raw : foodNutrients) {
                String number = firstText(raw, "nutrientNumber", "number");
                if (number == null) {
                    number = text(raw.path("nutrient"), "number");
                }
                if (nutrientNumber.equals(number)) {
                    Double amount = firstDouble(raw, "value", "amount");
                    return amount == null ? null : Math.max(amount, 0.0);
                }
            }
        }
        return null;
    }

    private static Double servingSizeG(JsonNode food) {
        Double amount = optionalDouble(food, "servingSize");
        if (amount == null) {
            return null;
        }
        String unit = text(food, "servingSizeUnit");
        if (unit == null || unit.isBlank()) {
            return null;
        }
        String normalized = unit.toLowerCase(Locale.ROOT).trim();
        if (List.of("g", "gram", "grams", "ml", "milliliter", "milliliters").contains(normalized)) {
            return amount;
        }
        return null;
    }

    private static boolean barcodeMatches(String requestedBarcode, String gtinUpc) {
        if (gtinUpc == null || gtinUpc.isBlank()) {
            return false;
        }
        String requested = digitsOnly(requestedBarcode);
        String actual = digitsOnly(gtinUpc);
        return requested.equals(actual) || trimLeadingZeroes(requested).equals(trimLeadingZeroes(actual));
    }

    private static String digitsOnly(String value) {
        return NON_DIGIT.matcher(value == null ? "" : value).replaceAll("");
    }

    private static String trimLeadingZeroes(String value) {
        String trimmed = value.replaceFirst("^0+", "");
        return trimmed.isEmpty() ? "0" : trimmed;
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

    private static Double firstDouble(JsonNode node, String... fields) {
        for (String field : fields) {
            Double value = optionalDouble(node, field);
            if (value != null) {
                return value;
            }
        }
        return null;
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
            return Double.parseDouble(text);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static double valueOrZero(Double value) {
        return value == null ? 0.0 : value;
    }

    public record SearchResponse(List<Food> items, int total) {
    }
}
