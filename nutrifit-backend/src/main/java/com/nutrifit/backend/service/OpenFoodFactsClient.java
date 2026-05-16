package com.nutrifit.backend.service;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

import com.fasterxml.jackson.databind.JsonNode;
import com.nutrifit.backend.config.AppSettings;
import com.nutrifit.backend.model.Food;
import com.nutrifit.backend.model.Macros;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class OpenFoodFactsClient {
    private static final Pattern SERVING_SIZE_NUMBER = Pattern.compile("(\\d+(?:[.,]\\d+)?)");

    private final RestClient restClient;

    public OpenFoodFactsClient(AppSettings settings, RestClient.Builder builder) {
        this.restClient = builder
                .baseUrl(settings.openFoodFactsBaseUrl())
                .defaultHeader(HttpHeaders.USER_AGENT, settings.userAgent())
                .build();
    }

    public Food getByBarcode(String barcode) {
        try {
            JsonNode data = restClient.get()
                    .uri("/api/v2/product/{barcode}.json", barcode)
                    .retrieve()
                    .body(JsonNode.class);
            if (data == null || data.path("status").asInt(0) != 1) {
                return null;
            }
            return toFood(data.path("product"), barcode);
        } catch (HttpClientErrorException.NotFound ignored) {
            return null;
        } catch (RestClientException ex) {
            throw new OpenFoodFactsException("upstream error: " + ex.getMessage(), ex);
        }
    }

    public SearchResponse search(String query, int page, int pageSize) {
        try {
            JsonNode data = restClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/cgi/search.pl")
                            .queryParam("search_terms", query)
                            .queryParam("json", 1)
                            .queryParam("page", page)
                            .queryParam("page_size", pageSize)
                            .queryParam("fields", String.join(",", List.of(
                                    "code",
                                    "product_name",
                                    "product_name_en",
                                    "generic_name",
                                    "brands",
                                    "image_front_url",
                                    "image_url",
                                    "serving_size",
                                    "nutriments"
                            )))
                            .build())
                    .retrieve()
                    .body(JsonNode.class);
            if (data == null) {
                return new SearchResponse(List.of(), 0);
            }

            List<Food> items = new ArrayList<>();
            JsonNode products = data.path("products");
            if (products.isArray()) {
                int index = 0;
                for (JsonNode product : products) {
                    Food food = toFood(product, query + ":" + index);
                    if (food != null) {
                        items.add(food);
                    }
                    index++;
                }
            }
            int total = data.path("count").asInt(items.size());
            return new SearchResponse(items, total);
        } catch (RestClientException ex) {
            throw new OpenFoodFactsException("upstream error: " + ex.getMessage(), ex);
        }
    }

    private static Food toFood(JsonNode product, String fallbackId) {
        if (product == null || product.isMissingNode() || product.isNull()) {
            return null;
        }
        String name = firstText(product, "product_name", "product_name_en", "generic_name");
        if (name == null || name.isBlank()) {
            return null;
        }
        String brands = text(product, "brands");
        String brand = null;
        if (brands != null && !brands.isBlank()) {
            brand = brands.split(",")[0].trim();
            if (brand.isBlank()) {
                brand = null;
            }
        }
        String id = firstText(product, "code", "_id");
        return new Food(
                id == null ? fallbackId : id,
                name.trim(),
                brand,
                firstText(product, "image_front_url", "image_url"),
                parseServingSizeG(text(product, "serving_size")),
                buildMacros(product.path("nutriments"))
        );
    }

    private static Macros buildMacros(JsonNode nutriments) {
        return new Macros(
                firstDouble(nutriments, "energy-kcal_100g", "energy-kcal", 0.0),
                firstDouble(nutriments, "proteins_100g", 0.0),
                firstDouble(nutriments, "carbohydrates_100g", 0.0),
                firstDouble(nutriments, "fat_100g", 0.0),
                optionalDouble(nutriments, "fiber_100g"),
                optionalDouble(nutriments, "sugars_100g"),
                optionalDouble(nutriments, "salt_100g")
        );
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
        JsonNode value = node.path(field);
        if (value.isMissingNode() || value.isNull()) {
            return null;
        }
        return value.asText();
    }

    private static double firstDouble(JsonNode node, String firstField, String secondField, double fallback) {
        Double first = optionalDouble(node, firstField);
        if (first != null) {
            return first;
        }
        Double second = optionalDouble(node, secondField);
        return second == null ? fallback : second;
    }

    private static double firstDouble(JsonNode node, String field, double fallback) {
        Double value = optionalDouble(node, field);
        return value == null ? fallback : value;
    }

    private static Double optionalDouble(JsonNode node, String field) {
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

    private static Double parseServingSizeG(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        var matcher = SERVING_SIZE_NUMBER.matcher(raw.toLowerCase().replace(',', '.'));
        if (!matcher.find()) {
            return null;
        }
        try {
            return Double.parseDouble(matcher.group(1));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    public record SearchResponse(List<Food> items, int total) {
    }
}
