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
class UsdaFoodDataControllerTest {
    private static final MockWebServer server = startServer();

    @Autowired
    private MockMvc mockMvc;

    @AfterAll
    static void stopServer() throws IOException {
        server.shutdown();
    }

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("USDA_BASE_URL", () -> server.url("/").toString());
        registry.add("USDA_API_KEY", () -> "TEST_KEY");
    }

    @Test
    void barcodeLookupMapsFood() throws Exception {
        server.enqueue(json("""
                {
                  "totalHits": 1,
                  "foods": [
                    {
                      "fdcId": 2105222,
                      "description": "NUT 'N BERRY MIX",
                      "gtinUpc": "077034085228",
                      "brandName": "KAR'S",
                      "servingSize": 28,
                      "servingSizeUnit": "g",
                      "foodNutrients": [
                        {"nutrientNumber": "208", "value": 500, "unitName": "KCAL"},
                        {"nutrientNumber": "203", "value": 14.3, "unitName": "G"},
                        {"nutrientNumber": "205", "value": 42.9, "unitName": "G"},
                        {"nutrientNumber": "204", "value": 32.1, "unitName": "G"},
                        {"nutrientNumber": "269", "value": 28.6, "unitName": "G"},
                        {"nutrientNumber": "291", "value": 7.1, "unitName": "G"},
                        {"nutrientNumber": "307", "value": 0, "unitName": "MG"}
                      ]
                    }
                  ]
                }
                """));

        mockMvc.perform(get("/barcode/077034085228"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is("2105222")))
                .andExpect(jsonPath("$.name", is("NUT 'N BERRY MIX")))
                .andExpect(jsonPath("$.brand", is("KAR'S")))
                .andExpect(jsonPath("$.serving_size_g", is(28.0)))
                .andExpect(jsonPath("$.macros_per_100g.calories_kcal", is(500.0)))
                .andExpect(jsonPath("$.macros_per_100g.sugar_g", is(28.6)))
                .andExpect(jsonPath("$.macros_per_100g.salt_g", is(0.0)));
    }

    @Test
    void barcodeLookupReturns404ForMiss() throws Exception {
        server.enqueue(json("{\"totalHits\": 0, \"foods\": []}"));

        mockMvc.perform(get("/barcode/1234567890123"))
                .andExpect(status().isNotFound());
    }

    @Test
    void searchMapsResultList() throws Exception {
        server.enqueue(json("""
                {
                  "totalHits": 1,
                  "foods": [
                    {
                      "fdcId": 2057648,
                      "description": "CHEDDAR CHEESE",
                      "brandOwner": "Grafton Village Cheese Co, LLC",
                      "servingSize": 28,
                      "servingSizeUnit": "g",
                      "foodNutrients": [
                        {"nutrientNumber": "208", "value": 393},
                        {"nutrientNumber": "203", "value": 21.4},
                        {"nutrientNumber": "205", "value": 3.57},
                        {"nutrientNumber": "204", "value": 28.6}
                      ]
                    }
                  ]
                }
                """));

        mockMvc.perform(get("/search").param("q", "cheddar cheese").param("page_size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.query", is("cheddar cheese")))
                .andExpect(jsonPath("$.page", is(1)))
                .andExpect(jsonPath("$.page_size", is(10)))
                .andExpect(jsonPath("$.total", is(1)))
                .andExpect(jsonPath("$.items[0].id", is("2057648")))
                .andExpect(jsonPath("$.items[0].name", is("CHEDDAR CHEESE")));
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
