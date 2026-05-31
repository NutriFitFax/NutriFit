package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record StoredUserProfile(
        @JsonProperty("user_id")           String userId,
        @JsonProperty("display_name")      String displayName,
        @JsonProperty("height_cm")         Double heightCm,
        @JsonProperty("goal_calories_kcal") Double goalCaloriesKcal,
        @JsonProperty("goal_protein_g")    Double goalProteinG,
        @JsonProperty("goal_carbs_g")      Double goalCarbsG,
        @JsonProperty("goal_fat_g")        Double goalFatG,
        @JsonProperty("updated_at")        String updatedAt
) {}
