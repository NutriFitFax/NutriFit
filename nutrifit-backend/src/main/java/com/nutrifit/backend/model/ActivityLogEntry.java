package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ActivityLogEntry(
        String id,
        @JsonProperty("user_id")              String userId,
        @JsonProperty("logged_at")            String loggedAt,
        @NotBlank String name,
        @PositiveOrZero Double met,
        @JsonProperty("duration_minutes")     @PositiveOrZero Double durationMinutes,
        @JsonProperty("calories_burned_kcal") @PositiveOrZero Double caloriesBurnedKcal
) {}
