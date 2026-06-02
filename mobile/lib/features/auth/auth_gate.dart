import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../app/app_shell.dart';
import '../../app/notification_service.dart';
import '../../app/settings_prefs.dart';
import '../../db/daily_log.dart';
import '../../features/history/viewed_food_history_store.dart';
import '../../api/api_exception.dart';
import 'login_screen.dart';
import 'user_profile.dart';

String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  return sha256.convert(bytes).toString();
}

class AuthGate extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;
  final DailyLogStore store;

  const AuthGate({
    super.key,
    required this.api,
    required this.history,
    required this.store,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool get _isLoggedIn => SettingsPrefs.instance.getUserEmail() != null;

  @override
  void initState() {
    super.initState();
    if (_isLoggedIn) {
      // Reschedule after the first frame so the Android Activity is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService.instance.rescheduleFromPrefs();
      });
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────

  /// Verifies the account with the backend and saves credentials locally.
  /// Returns null on success or an error message to show the user.
  Future<String?> _handleLogin(String email, String password) async {
    // Check password against the locally stored hash first.
    final storedHash = SettingsPrefs.instance.passwordHash;
    if (storedHash != null) {
      if (_hashPassword(password) != storedHash) {
        return 'Incorrect password. Please try again.';
      }
    }

    widget.api.userId = email;
    try {
      // Throws NotFoundException (404) if email is not in the users table.
      await widget.api.getUserAccount();
    } on NotFoundException {
      widget.api.userId = 'demo-user';
      return 'No account found for $email. Please register first.';
    } catch (_) {
      // Network error / backend down — allow offline login.
    }
    await SettingsPrefs.instance.setUserEmail(email);
    // Restore the real display name from the backend, but only if the backend
    // returns a proper name — not the email-prefix that some backends echo back
    // as the userId. Guard: skip the update if the returned name is identical
    // to the local part of the email (e.g. "bakirba" from "bakirba@example.com").
    try {
      final stored = await widget.api.getStorageProfile();
      final emailPrefix = email.split('@').first.toLowerCase();
      if (stored.displayName?.isNotEmpty == true &&
          stored.displayName!.toLowerCase() != emailPrefix) {
        await SettingsPrefs.instance.setDisplayName(stored.displayName!);
      }
    } catch (_) {}
    // Reset today's water intake so every login starts with a fresh counter.
    await widget.store.resetTodayWater();
    return null;
  }

  // ── Sign-up ───────────────────────────────────────────────────────────

  /// Creates the user profile on the backend and saves credentials locally.
  Future<void> _handleProfileCreated(UserProfile profile) async {
    widget.api.userId = profile.email;
    // Each call gets its own try/catch so a timeout or error on step 1 does
    // not prevent step 2 from running (server may have committed the INSERT
    // before the client received the response).
    try {
      await widget.api.registerUser(
        email: profile.email,
        displayName: profile.name,
      );
    } catch (_) {}
    try {
      await widget.api.saveStorageProfile(StoredUserProfile(
        userId: profile.email,
        displayName: profile.name,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
        goalCaloriesKcal: profile.macroCalories.toDouble(),
        goalProteinG: profile.proteinGoalG.toDouble(),
        goalCarbsG: profile.carbsGoalG.toDouble(),
        goalFatG: profile.fatGoalG.toDouble(),
        sex: profile.gender.name,
        activityLevel: profile.activityLevel.name,
        dateOfBirth: profile.dateOfBirth != null
            ? '${profile.dateOfBirth!.year.toString().padLeft(4,'0')}-${profile.dateOfBirth!.month.toString().padLeft(2,'0')}-${profile.dateOfBirth!.day.toString().padLeft(2,'0')}'
            : null,
        updatedAt: null,
      ));
    } catch (e) {
      debugPrint('[NutriFit] saveStorageProfile failed: $e');
    }
    // Hash and persist the password that was saved in sign-up step 1, then
    // clear the plain-text copy so it doesn't linger in SharedPreferences.
    final pending = SettingsPrefs.instance.pendingPassword;
    if (pending != null && pending.isNotEmpty) {
      await SettingsPrefs.instance.setPasswordHash(_hashPassword(pending));
      await SettingsPrefs.instance.clearPendingPassword();
    }
    // Always enable haptics for a fresh account so the default is on.
    await SettingsPrefs.instance.setHaptics(true);
    // Reminders start off for every new account — the user can enable them in settings.
    await SettingsPrefs.instance.setMealReminders(false);
    await SettingsPrefs.instance.setWaterReminders(false);
    await SettingsPrefs.instance.setUserEmail(profile.email);
    await SettingsPrefs.instance.setDisplayName(profile.name);
    await SettingsPrefs.instance.setWeightKg(profile.weightKg);
    await SettingsPrefs.instance.setHeightCm(profile.heightCm);
    await SettingsPrefs.instance.setGoalProteinG(profile.proteinGoalG);
    await SettingsPrefs.instance.setGoalCarbsG(profile.carbsGoalG);
    await SettingsPrefs.instance.setGoalFatG(profile.fatGoalG);
    await SettingsPrefs.instance.setGoalCaloriesKcal(profile.macroCalories);
    await SettingsPrefs.instance.setGender(profile.gender);
    await SettingsPrefs.instance.setActivityLevel(profile.activityLevel);
    if (profile.dateOfBirth != null) {
      await SettingsPrefs.instance.setDateOfBirth(profile.dateOfBirth!);
    }
    // Log the sign-up weight as the first weight entry so the dashboard
    // shows it immediately and the sparkline has a starting point.
    await widget.store.logWeight(profile.weightKg);
    try {
      await widget.api.addWeightLog(WeightLogEntry(
        weightKg: profile.weightKg,
        loggedAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('[NutriFit] addWeightLog failed: $e');
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────

  /// Called after login or sign-up succeeds. Pops any auth routes and
  /// rebuilds to show AppShell.
  void _handleAuthenticated() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {});
    NotificationService.instance.rescheduleFromPrefs();
  }

  // ── Logout / delete ───────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    await NotificationService.instance.cancelAll();
    // Reset today's water intake before logging out so the next session starts fresh.
    await widget.store.resetTodayWater();
    await SettingsPrefs.instance.clearUserEmail();
    // Avatar path is intentionally NOT cleared on logout so the picture
    // is still there when the same user logs back in.
    widget.api.userId = 'demo-user';
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {});
    }
  }

  Future<void> _handleDeleteAccount() async {
    await NotificationService.instance.cancelAll();
    // Delete from backend first (all 6 tables: users, user_profiles, and all logs).
    try {
      await widget.api.deleteAccount();
    } catch (_) {
      // Backend unavailable — proceed with local-only deletion.
    }

    // Clear local SQLite logs, viewed-food history, and all profile/session data.
    await widget.store.clearAllData();
    await widget.history.clear();
    await SettingsPrefs.instance.clearUserEmail();
    await SettingsPrefs.instance.clearAvatarPath();
    await SettingsPrefs.instance.clearAccent();
    await SettingsPrefs.instance.clearProfile();

    widget.api.userId = 'demo-user';

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {});
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLogin: (email, password) => _handleLogin(email, password),
        onAuthenticated: _handleAuthenticated,
        onProfileCreated: _handleProfileCreated,
      );
    }

    return AppShell(
      api: widget.api,
      history: widget.history,
      store: widget.store,
      onLogout: _handleLogout,
      onDeleteAccount: _handleDeleteAccount,
    );
  }
}
