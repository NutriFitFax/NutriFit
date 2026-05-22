package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record PlannedMeal(
        String id,
        String title,
        @JsonProperty("image_url") String imageUrl,
        @JsonProperty("ready_in_minutes") Integer readyInMinutes,
        Integer servings,
        @JsonProperty("source_url") String sourceUrl
) {
}
