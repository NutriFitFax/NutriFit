package com.nutrifit.backend;

import java.time.OffsetDateTime;
import java.util.Optional;

import com.nutrifit.backend.model.UserProfile;
import com.nutrifit.backend.model.UserProfileRequest;
import com.nutrifit.backend.service.UserProfileRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class UserProfileControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserProfileRepository repository;

    @Test
    void putProfileCreatesOrUpdatesProfile() throws Exception {
        when(repository.upsert(eq("codex-test-user"), any(UserProfileRequest.class)))
                .thenReturn(profile());

        mockMvc.perform(put("/profile")
                        .header("X-User-Id", " codex-test-user ")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "display_name": "Codex Test User",
                                  "height_cm": 170,
                                  "goal_calories_kcal": 2000,
                                  "goal_protein_g": 120,
                                  "goal_carbs_g": 220,
                                  "goal_fat_g": 65
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id", is("codex-test-user")))
                .andExpect(jsonPath("$.display_name", is("Codex Test User")))
                .andExpect(jsonPath("$.height_cm", is(170.0)))
                .andExpect(jsonPath("$.goal_calories_kcal", is(2000.0)));

        ArgumentCaptor<UserProfileRequest> captor = ArgumentCaptor.forClass(UserProfileRequest.class);
        verify(repository).upsert(eq("codex-test-user"), captor.capture());
        org.assertj.core.api.Assertions.assertThat(captor.getValue().displayName())
                .isEqualTo("Codex Test User");
    }

    @Test
    void getProfileReturnsStoredProfile() throws Exception {
        when(repository.findByUserId("codex-test-user")).thenReturn(Optional.of(profile()));

        mockMvc.perform(get("/profile").header("X-User-Id", "codex-test-user"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id", is("codex-test-user")))
                .andExpect(jsonPath("$.display_name", is("Codex Test User")));
    }

    @Test
    void getProfileReturns404ForUnknownUser() throws Exception {
        when(repository.findByUserId("missing")).thenReturn(Optional.empty());

        mockMvc.perform(get("/profile").header("X-User-Id", "missing"))
                .andExpect(status().isNotFound());
    }

    @Test
    void invalidProfileReturns400() throws Exception {
        mockMvc.perform(put("/profile")
                        .header("X-User-Id", "codex-test-user")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "height_cm": 20
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    private static UserProfile profile() {
        return new UserProfile(
                "codex-test-user",
                "Codex Test User",
                170.0,
                2000.0,
                120.0,
                220.0,
                65.0,
                OffsetDateTime.parse("2026-05-31T12:00:00Z")
        );
    }
}
