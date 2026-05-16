package com.nutrifit.backend.model;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

public record SearchResult(
        String query,
        int page,
        @JsonProperty("page_size") int pageSize,
        int total,
        List<Food> items
) {
}
