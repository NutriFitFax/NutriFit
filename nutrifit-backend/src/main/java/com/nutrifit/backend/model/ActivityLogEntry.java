package com.nutrifit.backend.model;

import java.time.OffsetDateTime;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ActivityLogEntry(
        String id,
        @JsonProperty("user_id") String userId,
        @JsonProperty("logged_at") OffsetDateTime loggedAt,
        @NotBlank @Size(max = 120) String name,
        @DecimalMin("0.0") @DecimalMax("30.0") double met,
        @JsonProperty("duration_minutes") @DecimalMin("1.0") @DecimalMax("1440.0") double durationMinutes,
        @JsonProperty("calories_burned_kcal") @DecimalMin("0.0") @DecimalMax("10000.0") double caloriesBurnedKcal
) {
}
