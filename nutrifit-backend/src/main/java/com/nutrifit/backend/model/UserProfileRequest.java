package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;

public record UserProfileRequest(
        @JsonProperty("display_name") @Size(max = 120) String displayName,
        @JsonProperty("height_cm") @DecimalMin("50.0") @DecimalMax("260.0") Double heightCm,
        @JsonProperty("goal_calories_kcal") @DecimalMin("500.0") @DecimalMax("10000.0") Double goalCaloriesKcal,
        @JsonProperty("goal_protein_g") @DecimalMin("0.0") @DecimalMax("1000.0") Double goalProteinG,
        @JsonProperty("goal_carbs_g") @DecimalMin("0.0") @DecimalMax("2000.0") Double goalCarbsG,
        @JsonProperty("goal_fat_g") @DecimalMin("0.0") @DecimalMax("1000.0") Double goalFatG
) {
}
