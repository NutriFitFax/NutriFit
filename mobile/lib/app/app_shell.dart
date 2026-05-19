import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../features/barcode/barcode_scanner_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/viewed_food_history_store.dart';
import '../features/meal_estimation/meal_entry_screen.dart';
import '../screens/search_screen.dart';
import 'app_tabs.dart';
import 'home_dashboard_screen.dart';

class AppShell extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const AppShell({
    super.key,
    required this.api,
    required this.history,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final List<AppTabDefinition> _tabs = [
    AppTabDefinition(
      id: AppTabId.home,
      label: 'Home',
      icon: Icons.home_outlined,
      builder: (context, api, history, openTab) => HomeDashboardScreen(
        onOpenTab: openTab,
      ),
    ),
    AppTabDefinition(
      id: AppTabId.search,
      label: 'Search',
      icon: Icons.search,
      builder: (context, api, history, openTab) => SearchScreen(
        api: api,
        history: history,
      ),
    ),
    AppTabDefinition(
      id: AppTabId.barcode,
      label: 'Barcode',
      icon: Icons.qr_code_scanner,
      builder: (context, api, history, openTab) =>
          BarcodeScannerScreen(api: api),
    ),
    AppTabDefinition(
      id: AppTabId.meal,
      label: 'Meal',
      icon: Icons.camera_alt,
      builder: (context, api, history, openTab) => MealEntryScreen(api: api),
    ),
    AppTabDefinition(
      id: AppTabId.history,
      label: 'History',
      icon: Icons.history,
      builder: (context, api, history, openTab) => HistoryScreen(
        history: history,
      ),
    ),
  ];

  int _index = 0;

  void _openTab(AppTabId tabId) {
    final nextIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (nextIndex == -1 || nextIndex == _index) return;
    setState(() => _index = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _tabs
              .map(
                (tab) => tab.builder(
                  context,
                  widget.api,
                  widget.history,
                  _openTab,
                ),
              )
              .toList(growable: false),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
