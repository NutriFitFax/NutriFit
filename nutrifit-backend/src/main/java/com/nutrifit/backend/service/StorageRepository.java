package com.nutrifit.backend.service;

import java.time.LocalDate;
import java.util.List;

import com.nutrifit.backend.model.ActivityLogEntry;
import com.nutrifit.backend.model.DailyStorageSummary;
import com.nutrifit.backend.model.MealLogEntry;
import com.nutrifit.backend.model.StoredUserProfile;
import com.nutrifit.backend.model.WaterLogEntry;
import com.nutrifit.backend.model.WeightLogEntry;

public interface StorageRepository {
    void initializeSchema();

    StoredUserProfile getProfile(String userId);

    StoredUserProfile saveProfile(String userId, StoredUserProfile profile);

    MealLogEntry addMeal(String userId, MealLogEntry meal);

    List<MealLogEntry> getMeals(String userId, LocalDate date);

    boolean deleteMeal(String userId, String id);

    WaterLogEntry addWater(String userId, WaterLogEntry water);

    List<WaterLogEntry> getWater(String userId, LocalDate date);

    WeightLogEntry addWeight(String userId, WeightLogEntry weight);

    List<WeightLogEntry> getWeights(String userId, int limit);

    ActivityLogEntry addActivity(String userId, ActivityLogEntry activity);

    List<ActivityLogEntry> getActivities(String userId, LocalDate date);

    DailyStorageSummary getDailySummary(String userId, LocalDate date);
}
