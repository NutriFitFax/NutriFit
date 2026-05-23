package com.nutrifit.backend.controller;

import com.nutrifit.backend.model.DatabaseHealthResponse;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DatabaseHealthController {
    private final ObjectProvider<JdbcTemplate> jdbcTemplateProvider;

    public DatabaseHealthController(ObjectProvider<JdbcTemplate> jdbcTemplateProvider) {
        this.jdbcTemplateProvider = jdbcTemplateProvider;
    }

    @GetMapping("/db-health")
    public ResponseEntity<DatabaseHealthResponse> dbHealth() {
        JdbcTemplate jdbcTemplate = jdbcTemplateProvider.getIfAvailable();
        if (jdbcTemplate == null) {
            return ResponseEntity.ok(DatabaseHealthResponse.notConfigured());
        }
        try {
            Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            if (result != null && result == 1) {
                return ResponseEntity.ok(DatabaseHealthResponse.healthy());
            }
            return ResponseEntity.status(502)
                    .body(DatabaseHealthResponse.unhealthy("unexpected SELECT 1 result"));
        } catch (Exception ex) {
            return ResponseEntity.status(502)
                    .body(DatabaseHealthResponse.unhealthy(ex.getClass().getSimpleName() + ": " + ex.getMessage()));
        }
    }
}
