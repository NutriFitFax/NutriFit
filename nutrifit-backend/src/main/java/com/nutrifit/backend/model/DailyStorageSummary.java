package com.nutrifit.backend.model;

import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record DailyStorageSummary(
        @JsonProperty("user_id") String userId,
        LocalDate date,
        StoredUserProfile profile,
        DailyTotals totals,
        List<MealLogEntry> meals,
        @JsonProperty("water_logs") List<WaterLogEntry> waterLogs,
        @JsonProperty("weight_logs") List<WeightLogEntry> weightLogs,
        @JsonProperty("activity_logs") List<ActivityLogEntry> activityLogs
) {
}
