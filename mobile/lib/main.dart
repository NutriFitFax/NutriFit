import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/api_config.dart';
import 'app/app_theme.dart';
import 'app/notification_service.dart';
import 'app/settings_prefs.dart';
import 'db/daily_log.dart';
import 'db/sqlite_daily_log_store.dart';
import 'features/auth/auth_gate.dart';
import 'features/history/viewed_food_history_store.dart';
import 'features/settings/widgets/settings_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsPrefs.init();
  await NotificationService.instance.init();
  final store = await SqliteDailyLogStore.open();
  final savedEmail = SettingsPrefs.instance.getUserEmail();
  runApp(
    NutriFitApp(
      api: NutriFitApi(
        baseUrl: ApiConfig.baseUrl,
        userId: savedEmail ?? 'demo-user',
      ),
      history: InMemoryViewedFoodHistoryStore(),
      store: store,
    ),
  );
}

class NutriFitApp extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;
  final DailyLogStore store;

  const NutriFitApp({super.key, required this.api, required this.history, required this.store});

  @override
  State<NutriFitApp> createState() => _NutriFitAppState();
}

class _NutriFitAppState extends State<NutriFitApp> {
  @override
  void initState() {
    super.initState();
    SettingsPrefs.instance.accentNotifier.addListener(_onAccentChanged);
  }

  @override
  void dispose() {
    SettingsPrefs.instance.accentNotifier.removeListener(_onAccentChanged);
    super.dispose();
  }

  void _onAccentChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final primary = nutriAccentColor[SettingsPrefs.instance.accent]!;
    return MaterialApp(
      title: 'NutriFit',
      theme: buildAppTheme(primary: primary),
      home: AuthGate(api: widget.api, history: widget.history, store: widget.store),
    );
  }
}
