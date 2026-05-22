package com.nutrifit.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class MealControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void returns502WithoutOpenAiKeyInsteadOfFakeFood() throws Exception {
        MockMultipartFile image = new MockMultipartFile(
                "image",
                "meal.jpg",
                "image/jpeg",
                new byte[]{1, 2, 3}
        );

        mockMvc.perform(multipart("/estimate-meal").file(image))
                .andExpect(status().isBadGateway());
    }

    @Test
    void rejectsUnsupportedImageType() throws Exception {
        MockMultipartFile image = new MockMultipartFile(
                "image",
                "meal.gif",
                "image/gif",
                new byte[]{1, 2, 3}
        );

        mockMvc.perform(multipart("/estimate-meal").file(image))
                .andExpect(status().isUnsupportedMediaType());
    }
}
