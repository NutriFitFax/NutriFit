import 'package:flutter/material.dart';

import '../../api/api_client.dart';
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

  void _handleLogin(String email) {
    SettingsPrefs.instance.setUserEmail(email);
    SettingsPrefs.instance.setDisplayName(email.split('@').first);
    widget.api.userId = email;
    setState(() {});
  }

  void _handleRegister(String email, String name) {
    SettingsPrefs.instance.setUserEmail(email);
    SettingsPrefs.instance.setDisplayName(name.isNotEmpty ? name : email.split('@').first);
    widget.api.userId = email;
    setState(() { _showRegister = false; });
  }

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
