package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record Food(
        String id,
        String name,
        String brand,
        @JsonProperty("image_url") String imageUrl,
        @JsonProperty("serving_size_g") Double servingSizeG,
        @JsonProperty("macros_per_100g") Macros macrosPer100g
) {
}
