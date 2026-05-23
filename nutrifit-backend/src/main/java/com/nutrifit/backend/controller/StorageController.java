package com.nutrifit.backend.controller;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import com.nutrifit.backend.model.ActivityLogEntry;
import com.nutrifit.backend.model.DailyStorageSummary;
import com.nutrifit.backend.model.MealLogEntry;
import com.nutrifit.backend.model.StoredUserProfile;
import com.nutrifit.backend.model.WaterLogEntry;
import com.nutrifit.backend.model.WeightLogEntry;
import com.nutrifit.backend.service.StorageRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.dao.DataAccessException;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@Validated
@RestController
public class StorageController {
    private static final String DEFAULT_USER_ID = "demo-user";

    private final ObjectProvider<StorageRepository> repositoryProvider;

    public StorageController(ObjectProvider<StorageRepository> repositoryProvider) {
        this.repositoryProvider = repositoryProvider;
    }

    @GetMapping("/storage/profile")
    public StoredUserProfile getProfile(@RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId) {
        StoredUserProfile profile = repository().getProfile(normalizeUserId(userId));
        if (profile == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "profile not found");
        }
        return profile;
    }

    @PutMapping("/storage/profile")
    public StoredUserProfile saveProfile(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestBody @Valid StoredUserProfile profile
    ) {
        return repository().saveProfile(normalizeUserId(userId), profile);
    }

    @GetMapping("/storage/summary")
    public DailyStorageSummary getDailySummary(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {
        return repository().getDailySummary(normalizeUserId(userId), date == null ? LocalDate.now() : date);
    }

    @PostMapping("/storage/meals")
    public MealLogEntry addMeal(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestBody @Valid MealLogEntry meal
    ) {
        return repository().addMeal(normalizeUserId(userId), meal);
    }

    @GetMapping("/storage/meals")
    public List<MealLogEntry> getMeals(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {
        return repository().getMeals(normalizeUserId(userId), date == null ? LocalDate.now() : date);
    }

    @DeleteMapping("/storage/meals/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteMeal(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @PathVariable @Pattern(regexp = "^[0-9a-fA-F-]{36}$") String id
    ) {
        if (!repository().deleteMeal(normalizeUserId(userId), id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "meal log not found");
        }
    }

    @PostMapping("/storage/water")
    public WaterLogEntry addWater(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestBody @Valid WaterLogEntry water
    ) {
        return repository().addWater(normalizeUserId(userId), water);
    }

    @GetMapping("/storage/water")
    public List<WaterLogEntry> getWater(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {
        return repository().getWater(normalizeUserId(userId), date == null ? LocalDate.now() : date);
    }

    @PostMapping("/storage/weight")
    public WeightLogEntry addWeight(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestBody @Valid WeightLogEntry weight
    ) {
        return repository().addWeight(normalizeUserId(userId), weight);
    }

    @GetMapping("/storage/weight")
    public List<WeightLogEntry> getWeights(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestParam(defaultValue = "30") @Min(1) @Max(365) int limit
    ) {
        return repository().getWeights(normalizeUserId(userId), limit);
    }

    @PostMapping("/storage/activity")
    public ActivityLogEntry addActivity(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestBody @Valid ActivityLogEntry activity
    ) {
        return repository().addActivity(normalizeUserId(userId), activity);
    }

    @GetMapping("/storage/activity")
    public List<ActivityLogEntry> getActivities(
            @RequestHeader(name = "X-User-Id", defaultValue = DEFAULT_USER_ID) String userId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {
        return repository().getActivities(normalizeUserId(userId), date == null ? LocalDate.now() : date);
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, String>> databaseError(DataAccessException ex) {
        return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                .body(Map.of("detail", "database error: " + ex.getClass().getSimpleName()));
    }

    private StorageRepository repository() {
        StorageRepository repository = repositoryProvider.getIfAvailable();
        if (repository == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "database not configured");
        }
        return repository;
    }

    private static String normalizeUserId(@Size(min = 1, max = 120) String userId) {
        String normalized = userId == null || userId.isBlank() ? DEFAULT_USER_ID : userId.trim();
        if (normalized.length() > 120) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "X-User-Id is too long");
        }
        return normalized;
    }
}
