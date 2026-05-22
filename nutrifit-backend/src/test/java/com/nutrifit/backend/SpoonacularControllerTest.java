package com.nutrifit.backend;

import java.io.IOException;

import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import okhttp3.mockwebserver.RecordedRequest;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class SpoonacularControllerTest {
    private static final MockWebServer spoonacularServer = startServer();

    @Autowired
    private MockMvc mockMvc;

    @AfterAll
    static void stopServer() throws IOException {
        spoonacularServer.shutdown();
    }

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("SPOONACULAR_BASE_URL", () -> spoonacularServer.url("/").toString());
        registry.add("SPOONACULAR_API_KEY", () -> "TEST_KEY");
    }

    @Test
    void mealPlanMapsSpoonacularResponse() throws Exception {
        spoonacularServer.enqueue(json("""
                {
                  "meals": [
                    {
                      "id": 655219,
                      "title": "Peanut Butter And Chocolate Oatmeal",
                      "imageType": "jpg",
                      "readyInMinutes": 45,
                      "servings": 1,
                      "sourceUrl": "https://spoonacular.com/recipes/peanut-butter-and-chocolate-oatmeal-655219"
                    }
                  ],
                  "nutrients": {
                    "calories": 1735.81,
                    "carbohydrates": 235.17,
                    "fat": 69.22,
                    "protein": 55.43
                  }
                }
                """));

        mockMvc.perform(get("/meal-plan")
                        .param("time_frame", "day")
                        .param("target_calories", "2000")
                        .param("diet", "vegetarian"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.time_frame", is("day")))
                .andExpect(jsonPath("$.target_calories", is(2000)))
                .andExpect(jsonPath("$.diet", is("vegetarian")))
                .andExpect(jsonPath("$.source", is("spoonacular")))
                .andExpect(jsonPath("$.meals[0].id", is("655219")))
                .andExpect(jsonPath("$.meals[0].title", is("Peanut Butter And Chocolate Oatmeal")))
                .andExpect(jsonPath("$.meals[0].image_url",
                        is("https://img.spoonacular.com/recipes/655219-312x231.jpg")))
                .andExpect(jsonPath("$.meals[0].ready_in_minutes", is(45)))
                .andExpect(jsonPath("$.meals[0].servings", is(1)))
                .andExpect(jsonPath("$.nutrients.calories_kcal", is(1735.81)))
                .andExpect(jsonPath("$.nutrients.protein_g", is(55.43)))
                .andExpect(jsonPath("$.nutrients.carbs_g", is(235.17)))
                .andExpect(jsonPath("$.nutrients.fat_g", is(69.22)));

        RecordedRequest request = spoonacularServer.takeRequest();
        assertThat(request.getPath())
                .contains("/mealplanner/generate")
                .contains("apiKey=TEST_KEY")
                .contains("timeFrame=day")
                .contains("targetCalories=2000")
                .contains("diet=vegetarian");
    }

    @Test
    void recipeDetailsMapsNutritionAndIngredients() throws Exception {
        spoonacularServer.enqueue(json("""
                {
                  "id": 716429,
                  "title": "Pasta with Garlic, Scallions, Cauliflower & Breadcrumbs",
                  "image": "https://img.spoonacular.com/recipes/716429-556x370.jpg",
                  "servings": 2,
                  "readyInMinutes": 45,
                  "sourceUrl": "https://example.test/recipe",
                  "extendedIngredients": [
                    {"original": "1 tbsp butter"},
                    {"name": "cauliflower florets"}
                  ],
                  "nutrition": {
                    "nutrients": [
                      {"name": "Calories", "amount": 584, "unit": "kcal"},
                      {"name": "Protein", "amount": 19, "unit": "g"},
                      {"name": "Carbohydrates", "amount": 84, "unit": "g"},
                      {"name": "Fat", "amount": 20, "unit": "g"}
                    ]
                  }
                }
                """));

        mockMvc.perform(get("/recipes/716429"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is("716429")))
                .andExpect(jsonPath("$.title", is("Pasta with Garlic, Scallions, Cauliflower & Breadcrumbs")))
                .andExpect(jsonPath("$.image_url", is("https://img.spoonacular.com/recipes/716429-556x370.jpg")))
                .andExpect(jsonPath("$.ready_in_minutes", is(45)))
                .andExpect(jsonPath("$.servings", is(2)))
                .andExpect(jsonPath("$.source_url", is("https://example.test/recipe")))
                .andExpect(jsonPath("$.ingredients[0]", is("1 tbsp butter")))
                .andExpect(jsonPath("$.ingredients[1]", is("cauliflower florets")))
                .andExpect(jsonPath("$.nutrients.calories_kcal", is(584.0)))
                .andExpect(jsonPath("$.nutrients.protein_g", is(19.0)))
                .andExpect(jsonPath("$.nutrients.carbs_g", is(84.0)))
                .andExpect(jsonPath("$.nutrients.fat_g", is(20.0)));

        RecordedRequest request = spoonacularServer.takeRequest();
        assertThat(request.getPath())
                .contains("/recipes/716429/information")
                .contains("apiKey=TEST_KEY")
                .contains("includeNutrition=true");
    }

    @Test
    void upstreamFailureReturns502() throws Exception {
        spoonacularServer.enqueue(new MockResponse().setResponseCode(503).setBody("unavailable"));

        mockMvc.perform(get("/meal-plan").param("time_frame", "day"))
                .andExpect(status().isBadGateway());

        RecordedRequest request = spoonacularServer.takeRequest();
        assertThat(request.getPath())
                .contains("/mealplanner/generate")
                .contains("apiKey=TEST_KEY")
                .contains("timeFrame=day");
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
