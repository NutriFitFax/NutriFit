package com.nutrifit.backend.service;

import java.util.Optional;

import com.nutrifit.backend.model.UserProfile;
import com.nutrifit.backend.model.UserProfileRequest;

public interface UserProfileRepository {
    Optional<UserProfile> findByUserId(String userId);

    UserProfile upsert(String userId, UserProfileRequest request);
}
