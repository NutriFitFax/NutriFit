package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ActivityLogEntry(
        String id,
        @JsonProperty("user_id")              String userId,
        @JsonProperty("logged_at")            String loggedAt,
        String name,
        Double met,
        @JsonProperty("duration_minutes")     Double durationMinutes,
        @JsonProperty("calories_burned_kcal") Double caloriesBurnedKcal
) {}
