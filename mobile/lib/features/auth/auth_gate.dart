import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../app/app_shell.dart';
import '../../app/settings_prefs.dart';
import '../../db/daily_log.dart';
import '../../features/history/viewed_food_history_store.dart';
import '../../api/api_exception.dart';
import 'login_screen.dart';
import 'user_profile.dart';

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

  // ── Login ─────────────────────────────────────────────────────────────

  /// Verifies the account with the backend and saves credentials locally.
  /// Returns null on success or an error message to show the user.
  Future<String?> _handleLogin(String email) async {
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
    await SettingsPrefs.instance.setDisplayName(email.split('@').first);
    // Reset today's water intake so every login starts with a fresh counter.
    await widget.store.resetTodayWater();
    return null;
  }

  // ── Sign-up ───────────────────────────────────────────────────────────

  /// Creates the user profile on the backend and saves credentials locally.
  Future<void> _handleProfileCreated(UserProfile profile) async {
    widget.api.userId = profile.email;
    try {
      // 1. Create the account row in the users table.
      await widget.api.registerUser(
        email: profile.email,
        displayName: profile.name,
      );
      // 2. Create the profile row with goals and measurements.
      await widget.api.saveStorageProfile(StoredUserProfile(
        userId: profile.email,
        displayName: profile.name,
        heightCm: profile.heightCm,
        goalCaloriesKcal: profile.macroCalories.toDouble(),
        goalProteinG: profile.proteinGoalG.toDouble(),
        goalCarbsG: profile.carbsGoalG.toDouble(),
        goalFatG: profile.fatGoalG.toDouble(),
        updatedAt: null,
      ));
    } catch (_) {
      // Backend unavailable — proceed with local-only registration.
    }
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
  }

  // ── Navigation ────────────────────────────────────────────────────────

  /// Called after login or sign-up succeeds. Pops any auth routes and
  /// rebuilds to show AppShell.
  void _handleAuthenticated() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {});
  }

  // ── Logout / delete ───────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    // Reset today's water intake before logging out so the next session starts fresh.
    await widget.store.resetTodayWater();
    await SettingsPrefs.instance.clearUserEmail();
    await SettingsPrefs.instance.clearAvatarPath();
    widget.api.userId = 'demo-user';
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {});
    }
  }

  Future<void> _handleDeleteAccount() async {
    // Delete from backend first (all 6 tables: users, user_profiles, and all logs).
    try {
      await widget.api.deleteAccount();
    } catch (_) {
      // Backend unavailable — proceed with local-only deletion.
    }

    // Clear local SQLite logs and session.
    await widget.store.clearAllData();
    await SettingsPrefs.instance.clearUserEmail();

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
        onLogin: _handleLogin,
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
