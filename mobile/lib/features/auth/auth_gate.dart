import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../app/app_shell.dart';
import '../../app/settings_prefs.dart';
import '../../db/daily_log.dart';
import '../../features/history/viewed_food_history_store.dart';
import 'login_screen.dart';

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

  void _handleLogin(String email) {
    SettingsPrefs.instance.setUserEmail(email);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLogin: _handleLogin,
        onRegister: () {},
      );
    }

    return AppShell(
      api: widget.api,
      history: widget.history,
      store: widget.store,
    );
  }
}
