import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../app/app_shell.dart';
import '../app/settings_prefs.dart';
import '../api/api_client.dart';
import '../features/history/viewed_food_history_store.dart';

class AuthGate extends StatelessWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const AuthGate({
    super.key,
    required this.api,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = SettingsPrefs.instance.getUserEmail() != null;

    if (!isLoggedIn) {
      return LoginScreen(
        onLogin: (email) {
          SettingsPrefs.instance.setUserEmail(email);
        },
        onRegister: () {},
      );
    }

    return AppShell(api: api, history: history);
  }
}

