package com.nutrifit.backend.model;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record MealPlanResponse(
        @JsonProperty("time_frame") String timeFrame,
        @JsonProperty("target_calories") Integer targetCalories,
        String diet,
        List<PlannedMeal> meals,
        RecipeNutrients nutrients,
        String source
) {
}
