import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../app/app_shell.dart';
import '../../app/settings_prefs.dart';
import '../../db/daily_log.dart';
import '../../features/history/viewed_food_history_store.dart';
import 'login_screen.dart';
import 'register_screen.dart';

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
  bool _showRegister = false;

  bool get _isLoggedIn => SettingsPrefs.instance.getUserEmail() != null;

  // ── Login ─────────────────────────────────────────────────────────────

  /// Returns null on success, or an error message to show the user.
  Future<String?> _handleLogin(String email) async {
    widget.api.userId = email;
    try {
      // Verify the account exists on the backend.
      await widget.api.getStorageProfile();
    } catch (_) {
      // Backend unavailable — allow offline login with whatever is in local DB.
    }
    await SettingsPrefs.instance.setUserEmail(email);
    await SettingsPrefs.instance.setDisplayName(email.split('@').first);
    if (mounted) setState(() {});
    return null;
  }

  // ── Register ──────────────────────────────────────────────────────────

  /// Returns null on success, or an error message to show the user.
  Future<String?> _handleRegister(String email, String name) async {
    widget.api.userId = email;
    try {
      // Create the user profile on the backend so the account exists in the DB.
      await widget.api.saveStorageProfile(StoredUserProfile(
        userId: email,
        displayName: name.isNotEmpty ? name : email.split('@').first,
        heightCm: null,
        goalCaloriesKcal: SettingsPrefs.instance.goalCaloriesKcal.toDouble(),
        goalProteinG: SettingsPrefs.instance.goalProteinG.toDouble(),
        goalCarbsG: SettingsPrefs.instance.goalCarbsG.toDouble(),
        goalFatG: SettingsPrefs.instance.goalFatG.toDouble(),
        updatedAt: null,
      ));
    } catch (_) {
      // Backend unavailable — proceed with local-only registration.
    }
    final displayName = name.isNotEmpty ? name : email.split('@').first;
    await SettingsPrefs.instance.setUserEmail(email);
    await SettingsPrefs.instance.setDisplayName(displayName);
    if (mounted) setState(() { _showRegister = false; });
    return null;
  }

  // ── Logout / delete ───────────────────────────────────────────────────

  void _handleLogout() {
    SettingsPrefs.instance.clearUserEmail();
    widget.api.userId = 'demo-user';
    setState(() { _showRegister = false; });
  }

  void _handleDeleteAccount() {
    widget.store.clearAllData();
    SettingsPrefs.instance.clearUserEmail();
    widget.api.userId = 'demo-user';
    setState(() { _showRegister = false; });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      if (_showRegister) {
        return RegisterScreen(
          onRegister: _handleRegister,
          onBackToLogin: () => setState(() => _showRegister = false),
        );
      }
      return LoginScreen(
        onLogin: _handleLogin,
        onRegister: () => setState(() => _showRegister = true),
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
