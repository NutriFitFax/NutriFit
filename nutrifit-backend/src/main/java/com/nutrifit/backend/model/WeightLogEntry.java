package com.nutrifit.backend.model;

import java.time.OffsetDateTime;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record WeightLogEntry(
        String id,
        @JsonProperty("user_id") String userId,
        @JsonProperty("logged_at") OffsetDateTime loggedAt,
        @JsonProperty("weight_kg") @DecimalMin("20.0") @DecimalMax("500.0") double weightKg
) {
}
