package com.nutrifit.backend.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "SUPABASE_DB_URL")
public class ProfileSchemaInitializer implements ApplicationRunner {
    private final JdbcTemplate jdbcTemplate;

    public ProfileSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(ApplicationArguments args) {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS user_profiles (
                    user_id TEXT PRIMARY KEY,
                    display_name TEXT,
                    height_cm NUMERIC,
                    goal_calories_kcal NUMERIC,
                    goal_protein_g NUMERIC,
                    goal_carbs_g NUMERIC,
                    goal_fat_g NUMERIC,
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """);
    }
}
