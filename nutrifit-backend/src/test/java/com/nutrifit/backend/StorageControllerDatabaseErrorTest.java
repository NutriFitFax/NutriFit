package com.nutrifit.backend;

import java.time.LocalDate;
import java.util.List;

import com.nutrifit.backend.model.ActivityLogEntry;
import com.nutrifit.backend.model.DailyStorageSummary;
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
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(classes = {NutriFitBackendApplication.class, StorageControllerDatabaseErrorTest.Config.class})
@AutoConfigureMockMvc
class StorageControllerDatabaseErrorTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void storageDatabaseErrorsReturn502() throws Exception {
        mockMvc.perform(get("/storage/summary"))
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.detail", containsString("database error")));
    }

    @TestConfiguration
    static class Config {
        @Bean
        StorageRepository storageRepository() {
            return new FailingStorageRepository();
        }
    }

    private static class FailingStorageRepository implements StorageRepository {
        @Override
        public void initializeSchema() {
        }

        @Override
        public StoredUserProfile getProfile(String userId) {
            throw failure();
        }

        @Override
        public StoredUserProfile saveProfile(String userId, StoredUserProfile profile) {
            throw failure();
        }

        @Override
        public MealLogEntry addMeal(String userId, MealLogEntry meal) {
            throw failure();
        }

        @Override
        public List<MealLogEntry> getMeals(String userId, LocalDate date) {
            throw failure();
        }

        @Override
        public boolean deleteMeal(String userId, String id) {
            throw failure();
        }

        @Override
        public WaterLogEntry addWater(String userId, WaterLogEntry water) {
            throw failure();
        }

        @Override
        public List<WaterLogEntry> getWater(String userId, LocalDate date) {
            throw failure();
        }

        @Override
        public WeightLogEntry addWeight(String userId, WeightLogEntry weight) {
            throw failure();
        }

        @Override
        public List<WeightLogEntry> getWeights(String userId, int limit) {
            throw failure();
        }

        @Override
        public ActivityLogEntry addActivity(String userId, ActivityLogEntry activity) {
            throw failure();
        }

        @Override
        public List<ActivityLogEntry> getActivities(String userId, LocalDate date) {
            throw failure();
        }

        @Override
        public DailyStorageSummary getDailySummary(String userId, LocalDate date) {
            throw failure();
        }

        private static DataAccessResourceFailureException failure() {
            return new DataAccessResourceFailureException("db unavailable");
        }
    }
}
