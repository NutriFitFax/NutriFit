package com.nutrifit.backend.model;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record MealEstimate(
        List<EstimatedFood> items,
        @JsonProperty("total_calories_kcal") double totalCaloriesKcal,
        @JsonProperty("total_protein_g") double totalProteinG,
        @JsonProperty("total_carbs_g") double totalCarbsG,
        @JsonProperty("total_fat_g") double totalFatG,
        String source,
        String notes
) {
}
