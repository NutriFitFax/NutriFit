package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public record RecipeNutrients(
        @JsonProperty("calories_kcal") double caloriesKcal,
        @JsonProperty("protein_g") double proteinG,
        @JsonProperty("carbs_g") double carbsG,
        @JsonProperty("fat_g") double fatG
) {
}
