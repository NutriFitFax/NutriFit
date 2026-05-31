package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record MealLogEntry(
        String id,
        @JsonProperty("user_id")       String userId,
        @JsonProperty("logged_at")     String loggedAt,
        @NotBlank String name,
        @JsonProperty("calories_kcal") @PositiveOrZero double caloriesKcal,
        @JsonProperty("protein_g")     @PositiveOrZero double proteinG,
        @JsonProperty("carbs_g")       @PositiveOrZero double carbsG,
        @JsonProperty("fat_g")         @PositiveOrZero double fatG,
        String source
) {}
