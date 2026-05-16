package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record Macros(
        @JsonProperty("calories_kcal") double caloriesKcal,
        @JsonProperty("protein_g") double proteinG,
        @JsonProperty("carbs_g") double carbsG,
        @JsonProperty("fat_g") double fatG,
        @JsonProperty("fiber_g") Double fiberG,
        @JsonProperty("sugar_g") Double sugarG,
        @JsonProperty("salt_g") Double saltG
) {
}
