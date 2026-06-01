package com.nutrifit.backend.controller;

import com.nutrifit.backend.model.*;
import jakarta.annotation.PostConstruct;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Persists per-user logs (meals, water, weight, activity) and profile data.
 *
 * All endpoints require an X-User-Id header — this is the user's email address,
 * set by the Flutter client after login/registration.  No password is checked
 * here; the user is identified solely by that header value.
 *
 * When SUPABASE_DB_URL is not set the JdbcTemplate bean is absent, the
 * Optional<JdbcTemplate> is empty, and every endpoint returns an empty-but-
 * valid response so the app degrades gracefully.
 */
@Validated
@RestController
@RequestMapping("/storage")
public class StorageController {

    private static final DateTimeFormatter ISO = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

    private final Optional<JdbcTemplate> db;

    public StorageController(Optional<JdbcTemplate> db) {
        this.db = db;
    }

    // ── Schema bootstrap ──────────────────────────────────────────────────

    @PostConstruct
    public void initSchema() {
        db.ifPresent(jdbc -> {
            try {
                // users — one row per registered account (email is the userId key)
                jdbc.execute("""
                    CREATE TABLE IF NOT EXISTS users (
                        id          TEXT PRIMARY KEY,
                        email       TEXT UNIQUE NOT NULL,
                        display_name TEXT,
                        created_at  TIMESTAMPTZ DEFAULT NOW()
                    )
                    """);
                jdbc.execute("""
                    CREATE TABLE IF NOT EXISTS user_profiles (
                        user_id           TEXT PRIMARY KEY,
                        display_name      TEXT,
                        height_cm         DOUBLE PRECISION,
                        goal_calories_kcal DOUBLE PRECISION,
                        goal_protein_g    DOUBLE PRECISION,
                        goal_carbs_g      DOUBLE PRECISION,
                        goal_fat_g        DOUBLE PRECISION,
                        sex               TEXT,
                        activity_level    TEXT,
                        updated_at        TIMESTAMPTZ DEFAULT NOW()
                    )
                    """);
                // Migrate existing rows: add columns if the table was created before this version.
                jdbc.execute("ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS sex TEXT");
                jdbc.execute("ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS activity_level TEXT");
                jdbc.execute("ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE");
                jdbc.execute("""
                    CREATE TABLE IF NOT EXISTS meal_logs (
                        id           TEXT PRIMARY KEY,
                        user_id      TEXT NOT NULL,
                        logged_at    TIMESTAMPTZ NOT NULL,
                        name         TEXT NOT NULL,
                        calories_kcal DOUBLE PRECISION NOT NULL DEFAULT 0,
                        protein_g    DOUBLE PRECISION NOT NULL DEFAULT 0,
                        carbs_g      DOUBLE PRECISION NOT NULL DEFAULT 0,
                        fat_g        DOUBLE PRECISION NOT NULL DEFAULT 0,
                        source       TEXT
                    )
                    """);
                jdbc.execute("""
                    CREATE TABLE IF NOT EXISTS water_logs (
                        id        TEXT PRIMARY KEY,
                        user_id   TEXT NOT NULL,
                        logged_at TIMESTAMPTZ NOT NULL,
                        amount_ml INTEGER NOT NULL
                    )
                    """);
                jdbc.execute("""
                    CREATE TABLE IF NOT EXISTS weight_logs (
                        id        TEXT PRIMARY KEY,
                        user_id   TEXT NOT NULL,
                        logged_at TIMESTAMPTZ NOT NULL,
                        weight_kg DOUBLE PRECISION NOT NULL
                    )
                    """);
                jdbc.execute("""
                    CREATE TABLE IF NOT EXISTS activity_logs (
                        id                   TEXT PRIMARY KEY,
                        user_id              TEXT NOT NULL,
                        logged_at            TIMESTAMPTZ NOT NULL,
                        name                 TEXT NOT NULL,
                        met                  DOUBLE PRECISION,
                        duration_minutes     DOUBLE PRECISION,
                        calories_burned_kcal DOUBLE PRECISION
                    )
                    """);
            } catch (Exception e) {
                System.err.println("[StorageController] Schema init failed: " + e.getMessage());
            }
        });
    }

    // ── Users ─────────────────────────────────────────────────────────────

    /** Register a new account. Idempotent — calling again with the same email is a no-op. */
    @PostMapping("/users")
    @ResponseStatus(HttpStatus.CREATED)
    public UserAccount registerUser(@Valid @RequestBody UserAccount body) {
        String id  = uuid();
        String now = nowIso();
        if (db.isPresent()) {
            db.get().update("""
                    INSERT INTO users (id, email, display_name, created_at)
                    VALUES (?, ?, ?, ?::timestamptz)
                    ON CONFLICT (email) DO NOTHING
                    """,
                    id, body.email(), body.displayName(), now);
            List<UserAccount> existing = db.get().query(
                    "SELECT * FROM users WHERE email = ?",
                    (rs, rowNum) -> new UserAccount(
                            rs.getString("id"),
                            rs.getString("email"),
                            rs.getString("display_name"),
                            rs.getString("created_at")),
                    body.email());
            if (!existing.isEmpty()) return existing.get(0);
        }
        return new UserAccount(id, body.email(), body.displayName(), now);
    }

    /**
     * Delete the calling user's account and every piece of data they own.
     * Wipes: meal_logs, water_logs, weight_logs, activity_logs, user_profiles, users.
     */
    @DeleteMapping("/account")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAccount(@RequestHeader("X-User-Id") String userId) {
        db.ifPresent(jdbc -> {
            jdbc.update("DELETE FROM meal_logs     WHERE user_id = ?", userId);
            jdbc.update("DELETE FROM water_logs    WHERE user_id = ?", userId);
            jdbc.update("DELETE FROM weight_logs   WHERE user_id = ?", userId);
            jdbc.update("DELETE FROM activity_logs WHERE user_id = ?", userId);
            jdbc.update("DELETE FROM user_profiles WHERE user_id = ?", userId);
            jdbc.update("DELETE FROM users         WHERE email   = ?", userId);
        });
    }

    /**
     * Read back the account row for the current user (identified by X-User-Id = email).
     * Returns 404 if the email is not registered — the Flutter login screen uses this
     * to block unregistered users from logging in.
     */
    @GetMapping("/users/me")
    public UserAccount getUser(@RequestHeader("X-User-Id") String email) {
        if (db.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "database not configured");
        }
        List<UserAccount> rows = db.get().query(
                "SELECT * FROM users WHERE email = ?",
                (rs, rowNum) -> new UserAccount(
                        rs.getString("id"),
                        rs.getString("email"),
                        rs.getString("display_name"),
                        rs.getString("created_at")),
                email);
        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "no account found for " + email);
        }
        return rows.get(0);
    }

    // ── Profile ───────────────────────────────────────────────────────────

    @GetMapping("/profile")
    public StoredUserProfile getProfile(@RequestHeader("X-User-Id") String userId) {
        if (db.isEmpty()) return emptyProfile(userId);
        List<StoredUserProfile> rows = db.get().query(
                "SELECT * FROM user_profiles WHERE user_id = ?",
                profileMapper(),
                userId);
        return rows.isEmpty() ? emptyProfile(userId) : rows.get(0);
    }

    @PutMapping("/profile")
    public StoredUserProfile saveProfile(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody StoredUserProfile body) {
        if (db.isEmpty()) return body;
        db.get().update("""
                INSERT INTO user_profiles
                    (user_id, display_name, height_cm, goal_calories_kcal,
                     goal_protein_g, goal_carbs_g, goal_fat_g,
                     sex, activity_level, date_of_birth, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?::date, NOW())
                ON CONFLICT (user_id) DO UPDATE SET
                    display_name       = EXCLUDED.display_name,
                    height_cm          = EXCLUDED.height_cm,
                    goal_calories_kcal = EXCLUDED.goal_calories_kcal,
                    goal_protein_g     = EXCLUDED.goal_protein_g,
                    goal_carbs_g       = EXCLUDED.goal_carbs_g,
                    goal_fat_g         = EXCLUDED.goal_fat_g,
                    sex                = EXCLUDED.sex,
                    activity_level     = EXCLUDED.activity_level,
                    date_of_birth      = EXCLUDED.date_of_birth,
                    updated_at         = NOW()
                """,
                userId, body.displayName(), body.heightCm(),
                body.goalCaloriesKcal(), body.goalProteinG(),
                body.goalCarbsG(), body.goalFatG(),
                body.sex(), body.activityLevel(), body.dateOfBirth());
        return getProfile(userId);
    }

    // ── Daily summary ─────────────────────────────────────────────────────

    @GetMapping("/summary")
    public DailyStorageSummary getDailySummary(
            @RequestHeader("X-User-Id") String userId,
            @RequestParam(required = false) String date) {
        String targetDate = (date != null && !date.isBlank()) ? date : LocalDate.now().toString();
        if (db.isEmpty()) return emptySummary(userId, targetDate);

        List<MealLogEntry>     meals      = getMealLogs(userId, targetDate);
        List<WaterLogEntry>    waterLogs  = getWaterLogs(userId, targetDate);
        List<WeightLogEntry>   weightLogs = getWeightLogs(userId, 30);
        List<ActivityLogEntry> activities = getActivityLogs(userId, targetDate);
        StoredUserProfile      profile    = getProfile(userId);

        double cal  = meals.stream().mapToDouble(MealLogEntry::caloriesKcal).sum();
        double prot = meals.stream().mapToDouble(MealLogEntry::proteinG).sum();
        double carb = meals.stream().mapToDouble(MealLogEntry::carbsG).sum();
        double fat  = meals.stream().mapToDouble(MealLogEntry::fatG).sum();
        int    water = waterLogs.stream().mapToInt(WaterLogEntry::amountMl).sum();
        double actCal = activities.stream()
                .mapToDouble(a -> a.caloriesBurnedKcal() != null ? a.caloriesBurnedKcal() : 0)
                .sum();

        return new DailyStorageSummary(
                userId, targetDate, profile,
                new DailyTotals(cal, prot, carb, fat, water, actCal),
                meals, waterLogs, weightLogs, activities);
    }

    // ── Meals ─────────────────────────────────────────────────────────────

    @PostMapping("/meals")
    @ResponseStatus(HttpStatus.CREATED)
    public MealLogEntry addMeal(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody MealLogEntry body) {
        String id  = uuid();
        String ts  = body.loggedAt() != null ? body.loggedAt() : nowIso();
        if (db.isPresent()) {
            db.get().update("""
                    INSERT INTO meal_logs
                        (id, user_id, logged_at, name, calories_kcal,
                         protein_g, carbs_g, fat_g, source)
                    VALUES (?, ?, ?::timestamptz, ?, ?, ?, ?, ?, ?)
                    """,
                    id, userId, ts,
                    body.name(), body.caloriesKcal(),
                    body.proteinG(), body.carbsG(), body.fatG(),
                    body.source() != null ? body.source() : "manual");
        }
        return new MealLogEntry(id, userId, ts,
                body.name(), body.caloriesKcal(),
                body.proteinG(), body.carbsG(), body.fatG(),
                body.source() != null ? body.source() : "manual");
    }

    @GetMapping("/meals")
    public List<MealLogEntry> getMeals(
            @RequestHeader("X-User-Id") String userId,
            @RequestParam(required = false) String date) {
        return getMealLogs(userId, date);
    }

    @DeleteMapping("/meals/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteMeal(
            @RequestHeader("X-User-Id") String userId,
            @PathVariable String id) {
        db.ifPresent(jdbc -> jdbc.update(
                "DELETE FROM meal_logs WHERE id = ? AND user_id = ?", id, userId));
    }

    // ── Water ─────────────────────────────────────────────────────────────

    @PostMapping("/water")
    @ResponseStatus(HttpStatus.CREATED)
    public WaterLogEntry addWater(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody WaterLogEntry body) {
        String id  = uuid();
        String tsW = body.loggedAt() != null ? body.loggedAt() : nowIso();
        if (db.isPresent()) {
            db.get().update(
                    "INSERT INTO water_logs (id, user_id, logged_at, amount_ml) VALUES (?, ?, ?::timestamptz, ?)",
                    id, userId, tsW, body.amountMl());
        }
        return new WaterLogEntry(id, userId, tsW, body.amountMl());
    }

    @GetMapping("/water")
    public List<WaterLogEntry> getWater(
            @RequestHeader("X-User-Id") String userId,
            @RequestParam(required = false) String date) {
        return getWaterLogs(userId, date);
    }

    // ── Weight ────────────────────────────────────────────────────────────

    @PostMapping("/weight")
    @ResponseStatus(HttpStatus.CREATED)
    public WeightLogEntry addWeight(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody WeightLogEntry body) {
        String id  = uuid();
        String tsWt = body.loggedAt() != null ? body.loggedAt() : nowIso();
        if (db.isPresent()) {
            db.get().update(
                    "INSERT INTO weight_logs (id, user_id, logged_at, weight_kg) VALUES (?, ?, ?::timestamptz, ?)",
                    id, userId, tsWt, body.weightKg());
        }
        return new WeightLogEntry(id, userId, tsWt, body.weightKg());
    }

    @GetMapping("/weight")
    public List<WeightLogEntry> getWeight(
            @RequestHeader("X-User-Id") String userId,
            @RequestParam(defaultValue = "30") int limit) {
        return getWeightLogs(userId, limit);
    }

    // ── Activity ──────────────────────────────────────────────────────────

    @PostMapping("/activity")
    @ResponseStatus(HttpStatus.CREATED)
    public ActivityLogEntry addActivity(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody ActivityLogEntry body) {
        String id  = uuid();
        String tsA = body.loggedAt() != null ? body.loggedAt() : nowIso();
        if (db.isPresent()) {
            db.get().update("""
                    INSERT INTO activity_logs
                        (id, user_id, logged_at, name, met, duration_minutes, calories_burned_kcal)
                    VALUES (?, ?, ?::timestamptz, ?, ?, ?, ?)
                    """,
                    id, userId, tsA,
                    body.name(), body.met(), body.durationMinutes(), body.caloriesBurnedKcal());
        }
        return new ActivityLogEntry(id, userId, tsA,
                body.name(), body.met(), body.durationMinutes(), body.caloriesBurnedKcal());
    }

    @GetMapping("/activity")
    public List<ActivityLogEntry> getActivity(
            @RequestHeader("X-User-Id") String userId,
            @RequestParam(required = false) String date) {
        return getActivityLogs(userId, date);
    }

    // ── Private helpers ───────────────────────────────────────────────────

    private List<MealLogEntry> getMealLogs(String userId, String date) {
        if (db.isEmpty()) return List.of();
        if (date != null && !date.isBlank()) {
            return db.get().query("""
                    SELECT * FROM meal_logs
                    WHERE user_id = ? AND logged_at::date = ?::date
                    ORDER BY logged_at ASC
                    """, mealMapper(), userId, date);
        }
        return db.get().query(
                "SELECT * FROM meal_logs WHERE user_id = ? ORDER BY logged_at ASC",
                mealMapper(), userId);
    }

    private List<WaterLogEntry> getWaterLogs(String userId, String date) {
        if (db.isEmpty()) return List.of();
        if (date != null && !date.isBlank()) {
            return db.get().query("""
                    SELECT * FROM water_logs
                    WHERE user_id = ? AND logged_at::date = ?::date
                    ORDER BY logged_at ASC
                    """, waterMapper(), userId, date);
        }
        return db.get().query(
                "SELECT * FROM water_logs WHERE user_id = ? ORDER BY logged_at ASC",
                waterMapper(), userId);
    }

    private List<WeightLogEntry> getWeightLogs(String userId, int limit) {
        if (db.isEmpty()) return List.of();
        return db.get().query(
                "SELECT * FROM weight_logs WHERE user_id = ? ORDER BY logged_at DESC LIMIT ?",
                weightMapper(), userId, limit);
    }

    private List<ActivityLogEntry> getActivityLogs(String userId, String date) {
        if (db.isEmpty()) return List.of();
        if (date != null && !date.isBlank()) {
            return db.get().query("""
                    SELECT * FROM activity_logs
                    WHERE user_id = ? AND logged_at::date = ?::date
                    ORDER BY logged_at ASC
                    """, activityMapper(), userId, date);
        }
        return db.get().query(
                "SELECT * FROM activity_logs WHERE user_id = ? ORDER BY logged_at ASC",
                activityMapper(), userId);
    }

    // ── Row mappers ───────────────────────────────────────────────────────

    private static RowMapper<StoredUserProfile> profileMapper() {
        return (rs, rowNum) -> new StoredUserProfile(
                rs.getString("user_id"),
                rs.getString("display_name"),
                (Double) rs.getObject("height_cm"),
                (Double) rs.getObject("goal_calories_kcal"),
                (Double) rs.getObject("goal_protein_g"),
                (Double) rs.getObject("goal_carbs_g"),
                (Double) rs.getObject("goal_fat_g"),
                rs.getString("sex"),
                rs.getString("activity_level"),
                rs.getString("date_of_birth"),
                rs.getString("updated_at"));
    }

    private static RowMapper<MealLogEntry> mealMapper() {
        return (rs, rowNum) -> new MealLogEntry(
                rs.getString("id"),
                rs.getString("user_id"),
                rs.getString("logged_at"),
                rs.getString("name"),
                rs.getDouble("calories_kcal"),
                rs.getDouble("protein_g"),
                rs.getDouble("carbs_g"),
                rs.getDouble("fat_g"),
                rs.getString("source"));
    }

    private static RowMapper<WaterLogEntry> waterMapper() {
        return (rs, rowNum) -> new WaterLogEntry(
                rs.getString("id"),
                rs.getString("user_id"),
                rs.getString("logged_at"),
                rs.getInt("amount_ml"));
    }

    private static RowMapper<WeightLogEntry> weightMapper() {
        return (rs, rowNum) -> new WeightLogEntry(
                rs.getString("id"),
                rs.getString("user_id"),
                rs.getString("logged_at"),
                rs.getDouble("weight_kg"));
    }

    private static RowMapper<ActivityLogEntry> activityMapper() {
        return (rs, rowNum) -> new ActivityLogEntry(
                rs.getString("id"),
                rs.getString("user_id"),
                rs.getString("logged_at"),
                rs.getString("name"),
                (Double) rs.getObject("met"),
                (Double) rs.getObject("duration_minutes"),
                (Double) rs.getObject("calories_burned_kcal"));
    }

    // ── Utility ───────────────────────────────────────────────────────────

    private static String uuid() {
        return UUID.randomUUID().toString();
    }

    private static String nowIso() {
        return OffsetDateTime.now().format(ISO);
    }

    private static StoredUserProfile emptyProfile(String userId) {
        return new StoredUserProfile(userId, null, null, null, null, null, null, null, null, null, null);
    }

    private static DailyStorageSummary emptySummary(String userId, String date) {
        return new DailyStorageSummary(
                userId, date, null,
                new DailyTotals(0, 0, 0, 0, 0, 0),
                List.of(), List.of(), List.of(), List.of());
    }
}
