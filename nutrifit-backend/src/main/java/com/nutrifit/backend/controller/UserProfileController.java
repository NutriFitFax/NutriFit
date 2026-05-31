package com.nutrifit.backend.controller;

import com.nutrifit.backend.model.UserProfile;
import com.nutrifit.backend.model.UserProfileRequest;
import com.nutrifit.backend.service.UserProfileRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@Validated
@RestController
public class UserProfileController {
    private final ObjectProvider<UserProfileRepository> repositoryProvider;

    public UserProfileController(ObjectProvider<UserProfileRepository> repositoryProvider) {
        this.repositoryProvider = repositoryProvider;
    }

    @GetMapping("/profile")
    public UserProfile getProfile(
            @RequestHeader("X-User-Id") @NotBlank @Size(max = 120) String userId
    ) {
        UserProfileRepository repository = configuredRepository();
        return repository.findByUserId(userId.trim())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "profile not found"));
    }

    @PutMapping("/profile")
    public UserProfile saveProfile(
            @RequestHeader("X-User-Id") @NotBlank @Size(max = 120) String userId,
            @Valid @RequestBody UserProfileRequest request
    ) {
        UserProfileRepository repository = configuredRepository();
        return repository.upsert(userId.trim(), request);
    }

    private UserProfileRepository configuredRepository() {
        UserProfileRepository repository = repositoryProvider.getIfAvailable();
        if (repository == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "database not configured");
        }
        return repository;
    }
}
