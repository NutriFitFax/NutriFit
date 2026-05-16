package com.nutrifit.backend.controller;

import com.nutrifit.backend.model.Food;
import com.nutrifit.backend.service.OpenFoodFactsClient;
import com.nutrifit.backend.service.OpenFoodFactsException;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@Validated
@RestController
public class BarcodeController {
    private final OpenFoodFactsClient client;

    public BarcodeController(OpenFoodFactsClient client) {
        this.client = client;
    }

    @GetMapping("/barcode/{barcode}")
    public Food getByBarcode(
            @PathVariable
            @Size(min = 6, max = 20)
            @Pattern(regexp = "^\\d+$")
            String barcode
    ) {
        try {
            Food food = client.getByBarcode(barcode);
            if (food == null) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "product not found");
            }
            return food;
        } catch (OpenFoodFactsException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, ex.getMessage(), ex);
        }
    }
}
