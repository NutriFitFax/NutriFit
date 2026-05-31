package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record MealLogEntry(
        String id,
        @JsonProperty("user_id")       String userId,
        @JsonProperty("logged_at")     String loggedAt,
        String name,
        @JsonProperty("calories_kcal") double caloriesKcal,
        @JsonProperty("protein_g")     double proteinG,
        @JsonProperty("carbs_g")       double carbsG,
        @JsonProperty("fat_g")         double fatG,
        String source
) {}
