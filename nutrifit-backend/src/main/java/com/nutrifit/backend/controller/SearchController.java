package com.nutrifit.backend.controller;

import com.nutrifit.backend.model.SearchResult;
import com.nutrifit.backend.service.OpenFoodFactsClient;
import com.nutrifit.backend.service.OpenFoodFactsException;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@Validated
@RestController
public class SearchController {
    private final OpenFoodFactsClient client;

    public SearchController(OpenFoodFactsClient client) {
        this.client = client;
    }

    @GetMapping("/search")
    public SearchResult search(
            @RequestParam("q") @Size(min = 1, max = 120) String query,
            @RequestParam(defaultValue = "1") @Min(1) @Max(50) int page,
            @RequestParam(name = "page_size", defaultValue = "20") @Min(1) @Max(50) int pageSize
    ) {
        try {
            OpenFoodFactsClient.SearchResponse response = client.search(query, page, pageSize);
            return new SearchResult(query, page, pageSize, response.total(), response.items());
        } catch (OpenFoodFactsException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, ex.getMessage(), ex);
        }
    }
}
