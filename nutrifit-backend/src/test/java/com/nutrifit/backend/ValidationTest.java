package com.nutrifit.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Verifies that all @Validated constraint annotations on controller parameters
 * are wired correctly and return HTTP 400 for invalid input.
 * No external services are called — validation fires before any I/O.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ValidationTest {

    @Autowired
    private MockMvc mockMvc;

    // ── /search ──────────────────────────────────────────────────────────────

    @Test
    void searchRejectsEmptyQuery() throws Exception {
        mockMvc.perform(get("/search").param("q", ""))
                .andExpect(status().isBadRequest());
    }

    @Test
    void searchRejectsQueryOver120Characters() throws Exception {
        String longQuery = "a".repeat(121);
        mockMvc.perform(get("/search").param("q", longQuery))
                .andExpect(status().isBadRequest());
    }

    @Test
    void searchRejectsPageZero() throws Exception {
        mockMvc.perform(get("/search").param("q", "chicken").param("page", "0"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void searchRejectsPageOver50() throws Exception {
        mockMvc.perform(get("/search").param("q", "chicken").param("page", "51"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void searchRejectsPageSizeZero() throws Exception {
        mockMvc.perform(get("/search").param("q", "chicken").param("page_size", "0"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void searchRejectsPageSizeOver50() throws Exception {
        mockMvc.perform(get("/search").param("q", "chicken").param("page_size", "51"))
                .andExpect(status().isBadRequest());
    }

    // ── /barcode ─────────────────────────────────────────────────────────────

    @Test
    void barcodeRejectsTooShortCode() throws Exception {
        mockMvc.perform(get("/barcode/12345"))   // 5 digits — min is 6
                .andExpect(status().isBadRequest());
    }

    @Test
    void barcodeRejectsTooLongCode() throws Exception {
        String overlong = "1".repeat(21);        // 21 digits — max is 20
        mockMvc.perform(get("/barcode/" + overlong))
                .andExpect(status().isBadRequest());
    }

    @Test
    void barcodeRejectsNonNumericCharacters() throws Exception {
        mockMvc.perform(get("/barcode/ABCDEFGHIJ"))   // letters, not digits
                .andExpect(status().isBadRequest());
    }

    // ── /meal-plan ───────────────────────────────────────────────────────────

    @Test
    void mealPlanRejectsCaloriesBelowMinimum() throws Exception {
        mockMvc.perform(get("/meal-plan")
                        .param("time_frame", "day")
                        .param("target_calories", "799"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void mealPlanRejectsCaloriesAboveMaximum() throws Exception {
        mockMvc.perform(get("/meal-plan")
                        .param("time_frame", "day")
                        .param("target_calories", "6001"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void mealPlanRejectsInvalidTimeFrame() throws Exception {
        mockMvc.perform(get("/meal-plan").param("time_frame", "weekend"))
                .andExpect(status().isBadRequest());
    }

    // ── /estimate-meal ───────────────────────────────────────────────────────

    @Test
    void estimateMealAcceptsPng() throws Exception {
        MockMultipartFile png = new MockMultipartFile(
                "image", "meal.png", "image/png", new byte[]{1, 2, 3}
        );
        // PNG is an accepted type — should not be rejected with 415.
        // No OpenAI key in test env → 502 is the expected outcome.
        mockMvc.perform(multipart("/estimate-meal").file(png))
                .andExpect(status().is(org.hamcrest.Matchers.not(415)));
    }

    @Test
    void estimateMealRejectsGif() throws Exception {
        MockMultipartFile gif = new MockMultipartFile(
                "image", "meal.gif", "image/gif", new byte[]{1, 2, 3}
        );
        mockMvc.perform(multipart("/estimate-meal").file(gif))
                .andExpect(status().isUnsupportedMediaType());
    }
}
