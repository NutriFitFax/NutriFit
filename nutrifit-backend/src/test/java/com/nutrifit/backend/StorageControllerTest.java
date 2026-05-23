package com.nutrifit.backend;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.nutrifit.backend.model.ActivityLogEntry;
import com.nutrifit.backend.model.DailyStorageSummary;
import com.nutrifit.backend.model.DailyTotals;
import com.nutrifit.backend.model.MealLogEntry;
import com.nutrifit.backend.model.StoredUserProfile;
import com.nutrifit.backend.model.WaterLogEntry;
import com.nutrifit.backend.model.WeightLogEntry;
import com.nutrifit.backend.service.StorageRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(classes = {NutriFitBackendApplication.class, StorageControllerTest.Config.class})
@AutoConfigureMockMvc
class StorageControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void savesProfileAndReturnsSummary() throws Exception {
        mockMvc.perform(put("/storage/profile")
                        .header("X-User-Id", "user-1")
                        .contentType("application/json")
                        .content("""
                                {
                                  "display_name": "Esma",
                                  "height_cm": 170,
                                  "goal_calories_kcal": 2100,
                                  "goal_protein_g": 120,
                                  "goal_carbs_g": 240,
                                  "goal_fat_g": 70
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id", is("user-1")))
                .andExpect(jsonPath("$.display_name", is("Esma")))
                .andExpect(jsonPath("$.goal_calories_kcal", is(2100.0)));

        mockMvc.perform(post("/storage/meals")
                        .header("X-User-Id", "user-1")
                        .contentType("application/json")
                        .content("""
                                {
                                  "logged_at": "2026-05-23T09:30:00Z",
                                  "name": "Banana",
                                  "calories_kcal": 105,
                                  "protein_g": 1.3,
                                  "carbs_g": 27,
                                  "fat_g": 0.4,
                                  "source": "manual"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id", is("user-1")))
                .andExpect(jsonPath("$.name", is("Banana")));

        mockMvc.perform(post("/storage/water")
                        .header("X-User-Id", "user-1")
                        .contentType("application/json")
                        .content("""
                                {
                                  "logged_at": "2026-05-23T10:00:00Z",
                                  "amount_ml": 500
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.amount_ml", is(500)));

        mockMvc.perform(get("/storage/summary")
                        .header("X-User-Id", "user-1")
                        .param("date", "2026-05-23"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id", is("user-1")))
                .andExpect(jsonPath("$.profile.display_name", is("Esma")))
                .andExpect(jsonPath("$.totals.calories_kcal", is(105.0)))
                .andExpect(jsonPath("$.totals.water_ml", is(500)))
                .andExpect(jsonPath("$.meals[0].name", is("Banana")));
    }

    @Test
    void deletesMealForUser() throws Exception {
        String body = mockMvc.perform(post("/storage/meals")
                        .header("X-User-Id", "user-2")
                        .contentType("application/json")
                        .content("""
                                {
                                  "name": "Lunch",
                                  "calories_kcal": 500,
                                  "protein_g": 20,
                                  "carbs_g": 50,
                                  "fat_g": 15
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String id = body.replaceFirst(".*\"id\":\"([^\"]+)\".*", "$1");

        mockMvc.perform(delete("/storage/meals/{id}", id).header("X-User-Id", "user-2"))
                .andExpect(status().isNoContent());

        mockMvc.perform(delete("/storage/meals/{id}", id).header("X-User-Id", "user-2"))
                .andExpect(status().isNotFound());
    }

    @TestConfiguration
    static class Config {
        @Bean
        StorageRepository storageRepository() {
            return new InMemoryStorageRepository();
        }
    }

    private static class InMemoryStorageRepository implements StorageRepository {
        private final Map<String, StoredUserProfile> profiles = new HashMap<>();
        private final Map<String, List<MealLogEntry>> meals = new HashMap<>();
        private final Map<String, List<WaterLogEntry>> water = new HashMap<>();
        private final Map<String, List<WeightLogEntry>> weights = new HashMap<>();
        private final Map<String, List<ActivityLogEntry>> activities = new HashMap<>();

        @Override
        public void initializeSchema() {
        }

        @Override
        public StoredUserProfile getProfile(String userId) {
            return profiles.get(userId);
        }

        @Override
        public StoredUserProfile saveProfile(String userId, StoredUserProfile profile) {
            StoredUserProfile saved = new StoredUserProfile(userId, profile.displayName(), profile.heightCm(),
                    profile.goalCaloriesKcal(), profile.goalProteinG(), profile.goalCarbsG(), profile.goalFatG(),
                    OffsetDateTime.now(ZoneOffset.UTC));
            profiles.put(userId, saved);
            return saved;
        }

        @Override
        public MealLogEntry addMeal(String userId, MealLogEntry meal) {
            MealLogEntry saved = new MealLogEntry(UUID.randomUUID().toString(), userId, orNow(meal.loggedAt()),
                    meal.name(), meal.caloriesKcal(), meal.proteinG(), meal.carbsG(), meal.fatG(), meal.source());
            meals.computeIfAbsent(userId, key -> new ArrayList<>()).add(saved);
            return saved;
        }

        @Override
        public List<MealLogEntry> getMeals(String userId, LocalDate date) {
            return meals.getOrDefault(userId, List.of()).stream()
                    .filter(meal -> sameDay(meal.loggedAt(), date))
                    .toList();
        }

        @Override
        public boolean deleteMeal(String userId, String id) {
            return meals.getOrDefault(userId, List.of()).removeIf(meal -> meal.id().equals(id));
        }

        @Override
        public WaterLogEntry addWater(String userId, WaterLogEntry entry) {
            WaterLogEntry saved = new WaterLogEntry(UUID.randomUUID().toString(), userId, orNow(entry.loggedAt()),
                    entry.amountMl());
            water.computeIfAbsent(userId, key -> new ArrayList<>()).add(saved);
            return saved;
        }

        @Override
        public List<WaterLogEntry> getWater(String userId, LocalDate date) {
            return water.getOrDefault(userId, List.of()).stream()
                    .filter(entry -> sameDay(entry.loggedAt(), date))
                    .toList();
        }

        @Override
        public WeightLogEntry addWeight(String userId, WeightLogEntry weight) {
            WeightLogEntry saved = new WeightLogEntry(UUID.randomUUID().toString(), userId, orNow(weight.loggedAt()),
                    weight.weightKg());
            weights.computeIfAbsent(userId, key -> new ArrayList<>()).add(saved);
            return saved;
        }

        @Override
        public List<WeightLogEntry> getWeights(String userId, int limit) {
            return weights.getOrDefault(userId, List.of()).stream().limit(limit).toList();
        }

        @Override
        public ActivityLogEntry addActivity(String userId, ActivityLogEntry activity) {
            ActivityLogEntry saved = new ActivityLogEntry(UUID.randomUUID().toString(), userId,
                    orNow(activity.loggedAt()), activity.name(), activity.met(), activity.durationMinutes(),
                    activity.caloriesBurnedKcal());
            activities.computeIfAbsent(userId, key -> new ArrayList<>()).add(saved);
            return saved;
        }

        @Override
        public List<ActivityLogEntry> getActivities(String userId, LocalDate date) {
            return activities.getOrDefault(userId, List.of()).stream()
                    .filter(entry -> sameDay(entry.loggedAt(), date))
                    .toList();
        }

        @Override
        public DailyStorageSummary getDailySummary(String userId, LocalDate date) {
            List<MealLogEntry> dailyMeals = getMeals(userId, date);
            List<WaterLogEntry> dailyWater = getWater(userId, date);
            List<ActivityLogEntry> dailyActivities = getActivities(userId, date);
            DailyTotals totals = new DailyTotals(
                    dailyMeals.stream().mapToDouble(MealLogEntry::caloriesKcal).sum(),
                    dailyMeals.stream().mapToDouble(MealLogEntry::proteinG).sum(),
                    dailyMeals.stream().mapToDouble(MealLogEntry::carbsG).sum(),
                    dailyMeals.stream().mapToDouble(MealLogEntry::fatG).sum(),
                    dailyWater.stream().mapToInt(WaterLogEntry::amountMl).sum(),
                    dailyActivities.stream().mapToDouble(ActivityLogEntry::caloriesBurnedKcal).sum()
            );
            return new DailyStorageSummary(userId, date, getProfile(userId), totals, dailyMeals, dailyWater,
                    getWeights(userId, 30), dailyActivities);
        }

        private static OffsetDateTime orNow(OffsetDateTime value) {
            return value == null ? OffsetDateTime.now(ZoneOffset.UTC) : value;
        }

        private static boolean sameDay(OffsetDateTime value, LocalDate date) {
            return value.toLocalDate().equals(date);
        }
    }
}
