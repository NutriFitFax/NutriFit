package com.nutrifit.backend.controller;

import com.nutrifit.backend.model.Food;
import com.nutrifit.backend.service.OpenFoodFactsClient;
import com.nutrifit.backend.service.OpenFoodFactsException;
import com.nutrifit.backend.service.UsdaFoodDataClient;
import com.nutrifit.backend.service.UsdaFoodDataException;
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
    private final UsdaFoodDataClient usdaClient;
    private final OpenFoodFactsClient openFoodFactsClient;

    public BarcodeController(UsdaFoodDataClient usdaClient, OpenFoodFactsClient openFoodFactsClient) {
        this.usdaClient = usdaClient;
        this.openFoodFactsClient = openFoodFactsClient;
    }

    @GetMapping("/barcode/{barcode}")
    public Food getByBarcode(
            @PathVariable
            @Size(min = 6, max = 20)
            @Pattern(regexp = "^\\d+$")
            String barcode
    ) {
        UsdaFoodDataException usdaFailure = null;
        try {
            Food food = usdaClient.getByBarcode(barcode);
            if (food != null) {
                return food;
            }
        } catch (UsdaFoodDataException ex) {
            usdaFailure = ex;
        }

        try {
            Food food = openFoodFactsClient.getByBarcode(barcode);
            if (food != null) {
                return food;
            }
        } catch (OpenFoodFactsException ex) {
            if (usdaFailure != null) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                        usdaFailure.getMessage() + "; " + ex.getMessage(), ex);
            }
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, ex.getMessage(), ex);
        }

        if (usdaFailure != null) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, usdaFailure.getMessage(), usdaFailure);
        }
        throw new ResponseStatusException(HttpStatus.NOT_FOUND, "product not found");
    }
}
