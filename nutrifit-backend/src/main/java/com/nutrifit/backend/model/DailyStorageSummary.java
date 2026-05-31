package com.nutrifit.backend.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record DailyStorageSummary(
        @JsonProperty("user_id")       String userId,
        String date,
        StoredUserProfile profile,
        DailyTotals totals,
        List<MealLogEntry> meals,
        @JsonProperty("water_logs")    List<WaterLogEntry> waterLogs,
        @JsonProperty("weight_logs")   List<WeightLogEntry> weightLogs,
        @JsonProperty("activity_logs") List<ActivityLogEntry> activityLogs
) {}
