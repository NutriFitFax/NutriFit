package com.nutrifit.backend.config;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

@Configuration
@ConditionalOnProperty(name = "SUPABASE_DB_URL")
public class DatabaseConfig {

    @Bean
    public DataSource dataSource(
            @Value("${SUPABASE_DB_URL}") String url,
            @Value("${SUPABASE_DB_USER:postgres}") String username,
            @Value("${SUPABASE_DB_PASSWORD:}") String password
    ) {
        return DataSourceBuilder.create()
                .driverClassName("org.postgresql.Driver")
                .url(url)
                .username(username)
                .password(password)
                .build();
    }

    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}
