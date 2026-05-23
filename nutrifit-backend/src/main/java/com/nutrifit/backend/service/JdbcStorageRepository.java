package com.nutrifit.backend.service;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import com.nutrifit.backend.model.ActivityLogEntry;
import com.nutrifit.backend.model.DailyStorageSummary;
import com.nutrifit.backend.model.DailyTotals;
import com.nutrifit.backend.model.MealLogEntry;
import com.nutrifit.backend.model.StoredUserProfile;
import com.nutrifit.backend.model.WaterLogEntry;
import com.nutrifit.backend.model.WeightLogEntry;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
@ConditionalOnBean(JdbcTemplate.class)
public class JdbcStorageRepository implements StorageRepository {
    private final JdbcTemplate jdbcTemplate;

    public JdbcStorageRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void initializeSchema() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS nutrifit_profiles (
                    user_id TEXT PRIMARY KEY,
                    display_name TEXT,
                    height_cm NUMERIC(6,2),
                    goal_calories_kcal NUMERIC(10,2),
                    goal_protein_g NUMERIC(10,2),
                    goal_carbs_g NUMERIC(10,2),
                    goal_fat_g NUMERIC(10,2),
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS nutrifit_meal_logs (
                    id UUID PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    logged_at TIMESTAMPTZ NOT NULL,
                    name TEXT NOT NULL,
                    calories_kcal NUMERIC(10,2) NOT NULL DEFAULT 0,
                    protein_g NUMERIC(10,2) NOT NULL DEFAULT 0,
                    carbs_g NUMERIC(10,2) NOT NULL DEFAULT 0,
                    fat_g NUMERIC(10,2) NOT NULL DEFAULT 0,
                    source TEXT,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """);
        jdbcTemplate.execute("""
                CREATE INDEX IF NOT EXISTS idx_nutrifit_meal_logs_user_time
                ON nutrifit_meal_logs (user_id, logged_at DESC)
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS nutrifit_water_logs (
                    id UUID PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    logged_at TIMESTAMPTZ NOT NULL,
                    amount_ml INTEGER NOT NULL CHECK (amount_ml > 0),
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """);
        jdbcTemplate.execute("""
                CREATE INDEX IF NOT EXISTS idx_nutrifit_water_logs_user_time
                ON nutrifit_water_logs (user_id, logged_at DESC)
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS nutrifit_weight_logs (
                    id UUID PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    logged_at TIMESTAMPTZ NOT NULL,
                    weight_kg NUMERIC(6,2) NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """);
        jdbcTemplate.execute("""
                CREATE INDEX IF NOT EXISTS idx_nutrifit_weight_logs_user_time
                ON nutrifit_weight_logs (user_id, logged_at DESC)
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS nutrifit_activity_logs (
                    id UUID PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    logged_at TIMESTAMPTZ NOT NULL,
                    name TEXT NOT NULL,
                    met NUMERIC(5,2) NOT NULL,
                    duration_minutes NUMERIC(8,2) NOT NULL,
                    calories_burned_kcal NUMERIC(10,2) NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """);
        jdbcTemplate.execute("""
                CREATE INDEX IF NOT EXISTS idx_nutrifit_activity_logs_user_time
                ON nutrifit_activity_logs (user_id, logged_at DESC)
                """);
    }

    @Override
    public StoredUserProfile getProfile(String userId) {
        List<StoredUserProfile> profiles = jdbcTemplate.query("""
                        SELECT user_id, display_name, height_cm, goal_calories_kcal,
                               goal_protein_g, goal_carbs_g, goal_fat_g, updated_at
                        FROM nutrifit_profiles
                        WHERE user_id = ?
                        """,
                (rs, rowNum) -> profile(rs),
                userId);
        return profiles.isEmpty() ? null : profiles.getFirst();
    }

    @Override
    public StoredUserProfile saveProfile(String userId, StoredUserProfile profile) {
        jdbcTemplate.update("""
                        INSERT INTO nutrifit_profiles (
                            user_id, display_name, height_cm, goal_calories_kcal,
                            goal_protein_g, goal_carbs_g, goal_fat_g, updated_at
                        )
                        VALUES (?, ?, ?, ?, ?, ?, ?, now())
                        ON CONFLICT (user_id) DO UPDATE SET
                            display_name = EXCLUDED.display_name,
                            height_cm = EXCLUDED.height_cm,
                            goal_calories_kcal = EXCLUDED.goal_calories_kcal,
                            goal_protein_g = EXCLUDED.goal_protein_g,
                            goal_carbs_g = EXCLUDED.goal_carbs_g,
                            goal_fat_g = EXCLUDED.goal_fat_g,
                            updated_at = now()
                        """,
                userId,
                profile.displayName(),
                profile.heightCm(),
                profile.goalCaloriesKcal(),
                profile.goalProteinG(),
                profile.goalCarbsG(),
                profile.goalFatG());
        return getProfile(userId);
    }

    @Override
    public MealLogEntry addMeal(String userId, MealLogEntry meal) {
        String id = newId();
        OffsetDateTime loggedAt = orNow(meal.loggedAt());
        jdbcTemplate.update("""
                        INSERT INTO nutrifit_meal_logs (
                            id, user_id, logged_at, name, calories_kcal,
                            protein_g, carbs_g, fat_g, source
                        )
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                uuid(id), userId, loggedAt, meal.name(), meal.caloriesKcal(),
                meal.proteinG(), meal.carbsG(), meal.fatG(), meal.source());
        return new MealLogEntry(id, userId, loggedAt, meal.name(), meal.caloriesKcal(),
                meal.proteinG(), meal.carbsG(), meal.fatG(), meal.source());
    }

    @Override
    public List<MealLogEntry> getMeals(String userId, LocalDate date) {
        TimeRange range = range(date);
        return jdbcTemplate.query("""
                        SELECT id, user_id, logged_at, name, calories_kcal,
                               protein_g, carbs_g, fat_g, source
                        FROM nutrifit_meal_logs
                        WHERE user_id = ? AND logged_at >= ? AND logged_at < ?
                        ORDER BY logged_at DESC
                        """,
                (rs, rowNum) -> meal(rs),
                userId, range.start(), range.end());
    }

    @Override
    public boolean deleteMeal(String userId, String id) {
        int rows = jdbcTemplate.update("DELETE FROM nutrifit_meal_logs WHERE user_id = ? AND id = ?",
                userId, uuid(id));
        return rows > 0;
    }

    @Override
    public WaterLogEntry addWater(String userId, WaterLogEntry water) {
        String id = newId();
        OffsetDateTime loggedAt = orNow(water.loggedAt());
        jdbcTemplate.update("""
                        INSERT INTO nutrifit_water_logs (id, user_id, logged_at, amount_ml)
                        VALUES (?, ?, ?, ?)
                        """,
                uuid(id), userId, loggedAt, water.amountMl());
        return new WaterLogEntry(id, userId, loggedAt, water.amountMl());
    }

    @Override
    public List<WaterLogEntry> getWater(String userId, LocalDate date) {
        TimeRange range = range(date);
        return jdbcTemplate.query("""
                        SELECT id, user_id, logged_at, amount_ml
                        FROM nutrifit_water_logs
                        WHERE user_id = ? AND logged_at >= ? AND logged_at < ?
                        ORDER BY logged_at DESC
                        """,
                (rs, rowNum) -> water(rs),
                userId, range.start(), range.end());
    }

    @Override
    public WeightLogEntry addWeight(String userId, WeightLogEntry weight) {
        String id = newId();
        OffsetDateTime loggedAt = orNow(weight.loggedAt());
        jdbcTemplate.update("""
                        INSERT INTO nutrifit_weight_logs (id, user_id, logged_at, weight_kg)
                        VALUES (?, ?, ?, ?)
                        """,
                uuid(id), userId, loggedAt, weight.weightKg());
        return new WeightLogEntry(id, userId, loggedAt, weight.weightKg());
    }

    @Override
    public List<WeightLogEntry> getWeights(String userId, int limit) {
        return jdbcTemplate.query("""
                        SELECT id, user_id, logged_at, weight_kg
                        FROM nutrifit_weight_logs
                        WHERE user_id = ?
                        ORDER BY logged_at DESC
                        LIMIT ?
                        """,
                (rs, rowNum) -> weight(rs),
                userId, limit);
    }

    @Override
    public ActivityLogEntry addActivity(String userId, ActivityLogEntry activity) {
        String id = newId();
        OffsetDateTime loggedAt = orNow(activity.loggedAt());
        jdbcTemplate.update("""
                        INSERT INTO nutrifit_activity_logs (
                            id, user_id, logged_at, name, met,
                            duration_minutes, calories_burned_kcal
                        )
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                        """,
                uuid(id), userId, loggedAt, activity.name(), activity.met(),
                activity.durationMinutes(), activity.caloriesBurnedKcal());
        return new ActivityLogEntry(id, userId, loggedAt, activity.name(), activity.met(),
                activity.durationMinutes(), activity.caloriesBurnedKcal());
    }

    @Override
    public List<ActivityLogEntry> getActivities(String userId, LocalDate date) {
        TimeRange range = range(date);
        return jdbcTemplate.query("""
                        SELECT id, user_id, logged_at, name, met,
                               duration_minutes, calories_burned_kcal
                        FROM nutrifit_activity_logs
                        WHERE user_id = ? AND logged_at >= ? AND logged_at < ?
                        ORDER BY logged_at DESC
                        """,
                (rs, rowNum) -> activity(rs),
                userId, range.start(), range.end());
    }

    @Override
    public DailyStorageSummary getDailySummary(String userId, LocalDate date) {
        List<MealLogEntry> meals = getMeals(userId, date);
        List<WaterLogEntry> water = getWater(userId, date);
        List<WeightLogEntry> weights = getWeights(userId, 30);
        List<ActivityLogEntry> activities = getActivities(userId, date);
        DailyTotals totals = new DailyTotals(
                meals.stream().mapToDouble(MealLogEntry::caloriesKcal).sum(),
                meals.stream().mapToDouble(MealLogEntry::proteinG).sum(),
                meals.stream().mapToDouble(MealLogEntry::carbsG).sum(),
                meals.stream().mapToDouble(MealLogEntry::fatG).sum(),
                water.stream().mapToInt(WaterLogEntry::amountMl).sum(),
                activities.stream().mapToDouble(ActivityLogEntry::caloriesBurnedKcal).sum()
        );
        return new DailyStorageSummary(userId, date, getProfile(userId), totals, meals, water, weights, activities);
    }

    private static StoredUserProfile profile(ResultSet rs) throws SQLException {
        return new StoredUserProfile(
                rs.getString("user_id"),
                rs.getString("display_name"),
                nullableDouble(rs, "height_cm"),
                nullableDouble(rs, "goal_calories_kcal"),
                nullableDouble(rs, "goal_protein_g"),
                nullableDouble(rs, "goal_carbs_g"),
                nullableDouble(rs, "goal_fat_g"),
                time(rs, "updated_at")
        );
    }

    private static MealLogEntry meal(ResultSet rs) throws SQLException {
        return new MealLogEntry(
                rs.getString("id"),
                rs.getString("user_id"),
                time(rs, "logged_at"),
                rs.getString("name"),
                rs.getDouble("calories_kcal"),
                rs.getDouble("protein_g"),
                rs.getDouble("carbs_g"),
                rs.getDouble("fat_g"),
                rs.getString("source")
        );
    }

    private static WaterLogEntry water(ResultSet rs) throws SQLException {
        return new WaterLogEntry(
                rs.getString("id"),
                rs.getString("user_id"),
                time(rs, "logged_at"),
                rs.getInt("amount_ml")
        );
    }

    private static WeightLogEntry weight(ResultSet rs) throws SQLException {
        return new WeightLogEntry(
                rs.getString("id"),
                rs.getString("user_id"),
                time(rs, "logged_at"),
                rs.getDouble("weight_kg")
        );
    }

    private static ActivityLogEntry activity(ResultSet rs) throws SQLException {
        return new ActivityLogEntry(
                rs.getString("id"),
                rs.getString("user_id"),
                time(rs, "logged_at"),
                rs.getString("name"),
                rs.getDouble("met"),
                rs.getDouble("duration_minutes"),
                rs.getDouble("calories_burned_kcal")
        );
    }

    private static Double nullableDouble(ResultSet rs, String column) throws SQLException {
        double value = rs.getDouble(column);
        return rs.wasNull() ? null : value;
    }

    private static OffsetDateTime time(ResultSet rs, String column) throws SQLException {
        Object value = rs.getObject(column);
        if (value instanceof OffsetDateTime offsetDateTime) {
            return offsetDateTime;
        }
        if (value instanceof Timestamp timestamp) {
            return timestamp.toInstant().atOffset(ZoneOffset.UTC);
        }
        return null;
    }

    private static OffsetDateTime orNow(OffsetDateTime value) {
        return value == null ? OffsetDateTime.now(ZoneOffset.UTC) : value;
    }

    private static TimeRange range(LocalDate date) {
        LocalDate target = date == null ? LocalDate.now(ZoneOffset.UTC) : date;
        OffsetDateTime start = target.atStartOfDay().atOffset(ZoneOffset.UTC);
        return new TimeRange(start, start.plusDays(1));
    }

    private static String newId() {
        return UUID.randomUUID().toString();
    }

    private static UUID uuid(String id) {
        return UUID.fromString(id);
    }

    private record TimeRange(OffsetDateTime start, OffsetDateTime end) {
    }
}
