package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record UserAccount(
        String id,
        String email,
        @JsonProperty("display_name") String displayName,
        @JsonProperty("created_at")   String createdAt
) {}
