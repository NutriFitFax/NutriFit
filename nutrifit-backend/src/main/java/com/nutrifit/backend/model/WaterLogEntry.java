package com.nutrifit.backend.model;

import java.time.OffsetDateTime;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record WaterLogEntry(
        String id,
        @JsonProperty("user_id") String userId,
        @JsonProperty("logged_at") OffsetDateTime loggedAt,
        @JsonProperty("amount_ml") @Min(1) @Max(10000) int amountMl
) {
}
