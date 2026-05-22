package com.nutrifit.backend.service;

import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
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
public class OpenFoodFactsClient {
    private static final Pattern AMOUNT_WITH_UNIT =
            Pattern.compile("([0-9]+(?:[.,][0-9]+)?)\\s*(g|gram|grams|ml|milliliter|milliliters)\\b",
                    Pattern.CASE_INSENSITIVE);
    private static final String PRODUCT_FIELDS = String.join(",",
            List.of(
                    "code",
                    "product_name",
                    "product_name_en",
                    "generic_name",
                    "brands",
                    "image_front_url",
                    "image_url",
                    "serving_quantity",
                    "serving_quantity_unit",
                    "serving_size",
                    "nutriments"
            ));

    private final RestClient restClient;

    public OpenFoodFactsClient(AppSettings settings, RestClient.Builder builder) {
        this.restClient = builder
                .baseUrl(settings.openFoodFactsBaseUrl())
                .defaultHeader(HttpHeaders.USER_AGENT, settings.userAgent())
                .build();
    }

    public Food getByBarcode(String barcode) {
        JsonNode data;
        try {
            data = restClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/api/v2/product/{barcode}")
                            .queryParam("fields", PRODUCT_FIELDS)
                            .build(barcode))
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientException ex) {
            throw new OpenFoodFactsException("openfoodfacts error: " + ex.getMessage(), ex);
        }
        if (data == null || data.path("status").asInt(0) != 1) {
            return null;
        }
        return toFood(data.path("product"), text(data, "code"));
    }

    private static Food toFood(JsonNode product, String code) {
        String name = firstText(product, "product_name", "product_name_en", "generic_name");
        if (code == null || code.isBlank() || name == null || name.isBlank()) {
            return null;
        }
        return new Food(
                code,
                name.trim(),
                firstText(product, "brands"),
                firstText(product, "image_front_url", "image_url"),
                servingSizeG(product),
                macros(product.path("nutriments"))
        );
    }

    private static Macros macros(JsonNode nutriments) {
        Double calories = firstDouble(nutriments, "energy-kcal_100g", "energy-kcal");
        if (calories == null) {
            Double energyKj = firstDouble(nutriments, "energy_100g", "energy");
            calories = energyKj == null ? null : energyKj / 4.184;
        }
        return new Macros(
                valueOrZero(calories),
                valueOrZero(firstDouble(nutriments, "proteins_100g", "proteins")),
                valueOrZero(firstDouble(nutriments, "carbohydrates_100g", "carbohydrates")),
                valueOrZero(firstDouble(nutriments, "fat_100g", "fat")),
                firstDouble(nutriments, "fiber_100g", "fiber"),
                firstDouble(nutriments, "sugars_100g", "sugars"),
                firstDouble(nutriments, "salt_100g", "salt")
        );
    }

    private static Double servingSizeG(JsonNode product) {
        Double quantity = optionalDouble(product, "serving_quantity");
        String quantityUnit = text(product, "serving_quantity_unit");
        if (quantity != null && isGramOrMilliliter(quantityUnit)) {
            return quantity;
        }

        String servingSize = text(product, "serving_size");
        if (servingSize == null) {
            return null;
        }
        Matcher matcher = AMOUNT_WITH_UNIT.matcher(servingSize);
        if (!matcher.find()) {
            return null;
        }
        try {
            return Double.parseDouble(matcher.group(1).replace(',', '.'));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static boolean isGramOrMilliliter(String unit) {
        if (unit == null || unit.isBlank()) {
            return true;
        }
        String normalized = unit.toLowerCase(Locale.ROOT).trim();
        return List.of("g", "gram", "grams", "ml", "milliliter", "milliliters").contains(normalized);
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
                return Math.max(value, 0.0);
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
            return Double.parseDouble(text.replace(',', '.'));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static double valueOrZero(Double value) {
        return value == null ? 0.0 : value;
    }
}
