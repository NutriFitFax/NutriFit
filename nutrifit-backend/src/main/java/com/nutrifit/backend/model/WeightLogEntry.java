package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Positive;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record WeightLogEntry(
        String id,
        @JsonProperty("user_id")   String userId,
        @JsonProperty("logged_at") String loggedAt,
        @JsonProperty("weight_kg") @Positive double weightKg
) {}
