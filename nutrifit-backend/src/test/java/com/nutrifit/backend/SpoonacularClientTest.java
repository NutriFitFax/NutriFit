package com.nutrifit.backend;

import com.nutrifit.backend.config.AppSettings;
import com.nutrifit.backend.service.SpoonacularClient;
import com.nutrifit.backend.service.SpoonacularException;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

class SpoonacularClientTest {
    @Test
    void missingApiKeyReturnsClearConfigurationError() {
        AppSettings settings = new AppSettings(
                "test",
                "*",
                "https://example.test/usda",
                "TEST_KEY",
                "https://example.test/openfoodfacts",
                "https://example.test/spoonacular",
                "",
                8.0,
                "",
                "gpt-4o",
                8388608,
                "NutriFit test"
        );
        SpoonacularClient client = new SpoonacularClient(settings, RestClient.builder());

        assertThatThrownBy(() -> client.generateMealPlan("day", null, null))
                .isInstanceOf(SpoonacularException.class)
                .hasMessageContaining("SPOONACULAR_API_KEY");
    }
}
