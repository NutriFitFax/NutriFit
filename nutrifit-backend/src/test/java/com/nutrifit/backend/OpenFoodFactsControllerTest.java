package com.nutrifit.backend;

import java.io.IOException;

import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class OpenFoodFactsControllerTest {
    private static final MockWebServer server = startServer();

    @Autowired
    private MockMvc mockMvc;

    @AfterAll
    static void stopServer() throws IOException {
        server.shutdown();
    }

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("OPENFOODFACTS_BASE_URL", () -> server.url("/").toString());
    }

    @Test
    void barcodeLookupMapsFood() throws Exception {
        server.enqueue(json("""
                {
                  "status": 1,
                  "product": {
                    "code": "5449000000996",
                    "product_name": "Cola",
                    "brands": "NutriFit",
                    "image_url": "https://example.test/cola.jpg",
                    "serving_size": "330 ml",
                    "nutriments": {
                      "energy-kcal_100g": 42,
                      "proteins_100g": 0,
                      "carbohydrates_100g": 10.6,
                      "fat_100g": 0,
                      "sugars_100g": 10.6
                    }
                  }
                }
                """));

        mockMvc.perform(get("/barcode/5449000000996"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is("5449000000996")))
                .andExpect(jsonPath("$.name", is("Cola")))
                .andExpect(jsonPath("$.brand", is("NutriFit")))
                .andExpect(jsonPath("$.serving_size_g", is(330.0)))
                .andExpect(jsonPath("$.macros_per_100g.calories_kcal", is(42.0)))
                .andExpect(jsonPath("$.macros_per_100g.sugar_g", is(10.6)));
    }

    @Test
    void barcodeLookupReturns404ForMiss() throws Exception {
        server.enqueue(json("{\"status\": 0}"));

        mockMvc.perform(get("/barcode/1234567890123"))
                .andExpect(status().isNotFound());
    }

    @Test
    void searchMapsResultList() throws Exception {
        server.enqueue(json("""
                {
                  "count": 1,
                  "products": [
                    {
                      "code": "1",
                      "product_name": "Greek yogurt",
                      "brands": "Dairy Co",
                      "nutriments": {
                        "energy-kcal_100g": 90,
                        "proteins_100g": 9,
                        "carbohydrates_100g": 4,
                        "fat_100g": 3
                      }
                    }
                  ]
                }
                """));

        mockMvc.perform(get("/search").param("q", "yogurt").param("page_size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.query", is("yogurt")))
                .andExpect(jsonPath("$.page", is(1)))
                .andExpect(jsonPath("$.page_size", is(10)))
                .andExpect(jsonPath("$.total", is(1)))
                .andExpect(jsonPath("$.items[0].name", is("Greek yogurt")));
    }

    @Test
    void upstreamFailureReturns502() throws Exception {
        server.enqueue(new MockResponse().setResponseCode(503).setBody("unavailable"));

        mockMvc.perform(get("/search").param("q", "milk"))
                .andExpect(status().isBadGateway());
    }

    private static MockResponse json(String body) {
        return new MockResponse()
                .setHeader("Content-Type", "application/json")
                .setBody(body);
    }

    private static MockWebServer startServer() {
        try {
            MockWebServer mockWebServer = new MockWebServer();
            mockWebServer.start();
            return mockWebServer;
        } catch (IOException ex) {
            throw new ExceptionInInitializerError(ex);
        }
    }
}
