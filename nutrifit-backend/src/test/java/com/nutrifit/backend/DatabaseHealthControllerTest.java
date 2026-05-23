package com.nutrifit.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class DatabaseHealthControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void reportsNotConfiguredWhenSupabaseEnvIsMissing() throws Exception {
        mockMvc.perform(get("/db-health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.configured", is(false)))
                .andExpect(jsonPath("$.ok", is(false)))
                .andExpect(jsonPath("$.error").doesNotExist());
    }
}
