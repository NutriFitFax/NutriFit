package com.nutrifit.backend.model;

import java.time.OffsetDateTime;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record MealLogEntry(
        String id,
        @JsonProperty("user_id") String userId,
        @JsonProperty("logged_at") OffsetDateTime loggedAt,
        @NotBlank @Size(max = 180) String name,
        @JsonProperty("calories_kcal") @DecimalMin("0.0") @DecimalMax("10000.0") double caloriesKcal,
        @JsonProperty("protein_g") @DecimalMin("0.0") @DecimalMax("1000.0") double proteinG,
        @JsonProperty("carbs_g") @DecimalMin("0.0") @DecimalMax("1000.0") double carbsG,
        @JsonProperty("fat_g") @DecimalMin("0.0") @DecimalMax("1000.0") double fatG,
        @Size(max = 60) String source
) {
}
