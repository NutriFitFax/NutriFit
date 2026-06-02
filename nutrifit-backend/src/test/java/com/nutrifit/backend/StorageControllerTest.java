package com.nutrifit.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Tests StorageController with no database configured (Optional<JdbcTemplate> = empty).
 * This covers the graceful-degradation code paths that run in production when
 * SUPABASE_DB_URL is not set, and exercises every controller method for coverage.
 */
@SpringBootTest
@AutoConfigureMockMvc
class StorageControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private static final String USER_ID = "alice@example.com";

    // ── Users ───────────────────────────────────────────────────────────────

    @Test
    void registerUserReturns201WithEmailAndName() throws Exception {
        mockMvc.perform(post("/storage/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"alice@example.com","display_name":"Alice"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email", is("alice@example.com")))
                .andExpect(jsonPath("$.display_name", is("Alice")))
                .andExpect(jsonPath("$.id", notNullValue()));
    }

    @Test
    void registerUserRejectsBlankEmail() throws Exception {
        mockMvc.perform(post("/storage/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"","display_name":"Alice"}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getUserMeReturns404WhenDatabaseNotConfigured() throws Exception {
        // Without DB, db.isEmpty() → 404
        mockMvc.perform(get("/storage/users/me")
                        .header("X-User-Id", USER_ID))
                .andExpect(status().isNotFound());
    }

    // ── Profile ─────────────────────────────────────────────────────────────

    @Test
    void saveProfileReturns200WithPostedData() throws Exception {
        // Without DB, saveProfile returns the request body unchanged
        mockMvc.perform(put("/storage/profile")
                        .header("X-User-Id", USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "user_id": "alice@example.com",
                                  "display_name": "Alice",
                                  "height_cm": 165.0,
                                  "weight_kg": 60.0,
                                  "goal_calories_kcal": 2000.0,
                                  "goal_protein_g": 130.0,
                                  "goal_carbs_g": 240.0,
                                  "goal_fat_g": 70.0
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id", is(USER_ID)))
                .andExpect(jsonPath("$.height_cm", is(165.0)));
    }

    @Test
    void getProfileReturns200WithUserId() throws Exception {
        // Without DB, emptyProfile(userId) returned — only user_id is set
        mockMvc.perform(get("/storage/profile")
                        .header("X-User-Id", USER_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id", is(USER_ID)));
    }

    // ── Meals ────────────────────────────────────────────────────────────────

    @Test
    void logMealReturns201WithGeneratedId() throws Exception {
        // Without DB, meal is generated in memory and returned
        mockMvc.perform(post("/storage/meals")
                        .header("X-User-Id", USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Grilled Chicken",
                                  "calories_kcal": 250.0,
                                  "protein_g": 30.0,
                                  "carbs_g": 0.0,
                                  "fat_g": 5.0
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", notNullValue()))
                .andExpect(jsonPath("$.name", is("Grilled Chicken")))
                .andExpect(jsonPath("$.calories_kcal", is(250.0)));
    }

    @Test
    void getMealsReturns200EmptyList() throws Exception {
        mockMvc.perform(get("/storage/meals").header("X-User-Id", USER_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", empty()));
    }

    @Test
    void deleteMealReturns204() throws Exception {
        mockMvc.perform(delete("/storage/meals/some-meal-id")
                        .header("X-User-Id", USER_ID))
                .andExpect(status().isNoContent());
    }

    // ── Water ────────────────────────────────────────────────────────────────

    @Test
    void logWaterReturns201WithAmountMl() throws Exception {
        mockMvc.perform(post("/storage/water")
                        .header("X-User-Id", USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"amount_ml": 500}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.amount_ml", is(500)));
    }

    @Test
    void getWaterReturns200EmptyList() throws Exception {
        mockMvc.perform(get("/storage/water").header("X-User-Id", USER_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", empty()));
    }

    // ── Weight ───────────────────────────────────────────────────────────────

    @Test
    void logWeightReturns201WithWeightKg() throws Exception {
        mockMvc.perform(post("/storage/weight")
                        .header("X-User-Id", USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"weight_kg": 72.5}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.weight_kg", is(72.5)));
    }

    @Test
    void getWeightReturns200EmptyList() throws Exception {
        mockMvc.perform(get("/storage/weight").header("X-User-Id", USER_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", empty()));
    }

    // ── Activity ─────────────────────────────────────────────────────────────

    @Test
    void logActivityReturns201WithName() throws Exception {
        mockMvc.perform(post("/storage/activity")
                        .header("X-User-Id", USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "Running", "calories_burned_kcal": 300.0, "duration_minutes": 30.0}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name", is("Running")))
                .andExpect(jsonPath("$.calories_burned_kcal", is(300.0)));
    }

    @Test
    void getActivityReturns200EmptyList() throws Exception {
        mockMvc.perform(get("/storage/activity").header("X-User-Id", USER_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", empty()));
    }

    // ── Summary ──────────────────────────────────────────────────────────────

    @Test
    void getDailySummaryReturns200WithUserIdAndDate() throws Exception {
        mockMvc.perform(get("/storage/summary")
                        .header("X-User-Id", USER_ID)
                        .param("date", "2024-01-15"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id", is(USER_ID)))
                .andExpect(jsonPath("$.date", is("2024-01-15")));
    }

    // ── Account deletion ─────────────────────────────────────────────────────

    @Test
    void deleteAccountReturns204() throws Exception {
        mockMvc.perform(delete("/storage/account")
                        .header("X-User-Id", USER_ID))
                .andExpect(status().isNoContent());
    }
}
