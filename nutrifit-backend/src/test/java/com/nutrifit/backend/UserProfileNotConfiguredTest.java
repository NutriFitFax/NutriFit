package com.nutrifit.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class UserProfileNotConfiguredTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void profileEndpointReturns503WhenDatabaseIsNotConfigured() throws Exception {
        mockMvc.perform(get("/profile").header("X-User-Id", "codex-test-user"))
                .andExpect(status().isServiceUnavailable());
    }
}
