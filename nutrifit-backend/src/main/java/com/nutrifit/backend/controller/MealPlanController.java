package com.nutrifit.backend.controller;

import com.nutrifit.backend.model.MealPlanResponse;
import com.nutrifit.backend.model.RecipeDetails;
import com.nutrifit.backend.service.SpoonacularClient;
import com.nutrifit.backend.service.SpoonacularException;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@Validated
@RestController
public class MealPlanController {
    private final SpoonacularClient client;

    public MealPlanController(SpoonacularClient client) {
        this.client = client;
    }

    @GetMapping("/meal-plan")
    public MealPlanResponse generateMealPlan(
            @RequestParam(name = "time_frame", defaultValue = "day")
            @Pattern(regexp = "^(day|week)$")
            String timeFrame,
            @RequestParam(name = "target_calories", required = false)
            @Min(800)
            @Max(6000)
            Integer targetCalories,
            @RequestParam(required = false)
            @Size(max = 80)
            String diet
    ) {
        try {
            return client.generateMealPlan(timeFrame, targetCalories, diet);
        } catch (SpoonacularException ex) {
            throw toHttpException(ex);
        }
    }

    @GetMapping("/recipes/{id}")
    public RecipeDetails getRecipeDetails(
            @PathVariable
            @Pattern(regexp = "^\\d{1,10}$")
            String id
    ) {
        try {
            return client.getRecipeDetails(id);
        } catch (SpoonacularException ex) {
            throw toHttpException(ex);
        }
    }

    private static ResponseStatusException toHttpException(SpoonacularException ex) {
        HttpStatus status = ex.configurationError() ? HttpStatus.SERVICE_UNAVAILABLE : HttpStatus.BAD_GATEWAY;
        return new ResponseStatusException(status, ex.getMessage(), ex);
    }
}
