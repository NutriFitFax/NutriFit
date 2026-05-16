package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public record EstimatedFood(
        String name,
        @JsonProperty("estimated_grams") double estimatedGrams,
        double confidence,
        @JsonProperty("macros_per_100g") Macros macrosPer100g
) {
}
