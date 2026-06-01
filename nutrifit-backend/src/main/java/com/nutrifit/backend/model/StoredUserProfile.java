package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record StoredUserProfile(
        @JsonProperty("user_id")            String userId,
        @JsonProperty("display_name")       String displayName,
        @JsonProperty("height_cm")          @Positive Double heightCm,
        @JsonProperty("goal_calories_kcal") @PositiveOrZero Double goalCaloriesKcal,
        @JsonProperty("goal_protein_g")     @PositiveOrZero Double goalProteinG,
        @JsonProperty("goal_carbs_g")       @PositiveOrZero Double goalCarbsG,
        @JsonProperty("goal_fat_g")         @PositiveOrZero Double goalFatG,
        @JsonProperty("sex")                String sex,
        @JsonProperty("activity_level")     String activityLevel,
        @JsonProperty("date_of_birth")      String dateOfBirth,
        @JsonProperty("updated_at")         String updatedAt
) {}
