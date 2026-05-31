package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record WaterLogEntry(
        String id,
        @JsonProperty("user_id")   String userId,
        @JsonProperty("logged_at") String loggedAt,
        @JsonProperty("amount_ml") int amountMl
) {}
