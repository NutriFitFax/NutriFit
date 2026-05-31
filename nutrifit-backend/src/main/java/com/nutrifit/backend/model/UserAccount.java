package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record UserAccount(
        String id,
        @NotBlank @Email String email,
        @JsonProperty("display_name") @NotBlank String displayName,
        @JsonProperty("created_at")   String createdAt
) {}
