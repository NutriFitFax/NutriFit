package com.nutrifit.backend.service;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.util.Optional;

import com.nutrifit.backend.model.UserProfile;
import com.nutrifit.backend.model.UserProfileRequest;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
@ConditionalOnProperty(name = "SUPABASE_DB_URL")
public class JdbcUserProfileRepository implements UserProfileRepository {
    private final JdbcTemplate jdbcTemplate;

    public JdbcUserProfileRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Optional<UserProfile> findByUserId(String userId) {
        var results = jdbcTemplate.query("""
                SELECT user_id, display_name, height_cm, goal_calories_kcal,
                       goal_protein_g, goal_carbs_g, goal_fat_g, updated_at
                FROM user_profiles
                WHERE user_id = ?
                """, JdbcUserProfileRepository::mapRow, userId);
        return results.stream().findFirst();
    }

    @Override
    public UserProfile upsert(String userId, UserProfileRequest request) {
        return jdbcTemplate.queryForObject("""
                INSERT INTO user_profiles (
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
                RETURNING user_id, display_name, height_cm, goal_calories_kcal,
                          goal_protein_g, goal_carbs_g, goal_fat_g, updated_at
                """,
                JdbcUserProfileRepository::mapRow,
                userId,
                clean(request.displayName()),
                request.heightCm(),
                request.goalCaloriesKcal(),
                request.goalProteinG(),
                request.goalCarbsG(),
                request.goalFatG()
        );
    }

    private static UserProfile mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new UserProfile(
                rs.getString("user_id"),
                rs.getString("display_name"),
                nullableDouble(rs, "height_cm"),
                nullableDouble(rs, "goal_calories_kcal"),
                nullableDouble(rs, "goal_protein_g"),
                nullableDouble(rs, "goal_carbs_g"),
                nullableDouble(rs, "goal_fat_g"),
                rs.getObject("updated_at", OffsetDateTime.class)
        );
    }

    private static Double nullableDouble(ResultSet rs, String column) throws SQLException {
        double value = rs.getDouble(column);
        return rs.wasNull() ? null : value;
    }

    private static String clean(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
