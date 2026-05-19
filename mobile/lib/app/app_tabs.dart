import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../features/history/viewed_food_history_store.dart';

enum AppTabId { home, search, barcode, meal, history }

typedef AppTabBuilder =
    Widget Function(
      BuildContext context,
      NutriFitApi api,
      ViewedFoodHistoryStore history,
      void Function(AppTabId tabId) openTab,
    );

class AppTabDefinition {
  final AppTabId id;
  final String label;
  final IconData icon;
  final AppTabBuilder builder;

  const AppTabDefinition({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });
}
