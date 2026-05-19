import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/api_config.dart';
import 'app/app_shell.dart';
import 'app/app_theme.dart';
import 'features/history/viewed_food_history_store.dart';

void main() {
  runApp(
    NutriFitApp(
      api: NutriFitApi(baseUrl: ApiConfig.baseUrl),
      history: InMemoryViewedFoodHistoryStore(),
    ),
  );
}

class NutriFitApp extends StatelessWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const NutriFitApp({
    super.key,
    required this.api,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFit',
      theme: buildAppTheme(),
      home: AppShell(
        api: api,
        history: history,
      ),
    );
  }
}
