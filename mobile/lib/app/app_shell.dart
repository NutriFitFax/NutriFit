import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../features/barcode/barcode_scanner_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/viewed_food_history_store.dart';
import '../features/meal_estimation/meal_entry_screen.dart';
import '../screens/search_screen.dart';
import '../ui/barcode_icon.dart';
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
      icon: const Icon(Icons.home_outlined),
      builder: (context, api, history, openTab) => HomeDashboardScreen(
        onOpenTab: openTab,
      ),
    ),
    AppTabDefinition(
      id: AppTabId.search,
      label: 'Search',
      icon: const Icon(Icons.search),
      builder: (context, api, history, openTab) => SearchScreen(
        api: api,
        history: history,
      ),
    ),
    AppTabDefinition(
      id: AppTabId.barcode,
      label: 'Barcode',
      icon: const BarcodeIcon(),
      builder: (context, api, history, openTab) => BarcodeScannerScreen(
        api: api,
        history: history,
        onGoToSearch: () => openTab(AppTabId.search),
      ),
    ),
    AppTabDefinition(
      id: AppTabId.meal,
      label: 'Meal',
      icon: const Icon(Icons.camera_alt),
      builder: (context, api, history, openTab) =>
          MealEntryScreen(api: api, history: history),
    ),
    AppTabDefinition(
      id: AppTabId.history,
      label: 'History',
      icon: const Icon(Icons.history),
      builder: (context, api, history, openTab) => HistoryScreen(
        history: history,
      ),
    ),
  ];

  late final PageController _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openTab(AppTabId tabId) {
    final nextIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (nextIndex == -1 || nextIndex == _index) return;
    _selectTab(nextIndex);
  }

  void _selectTab(int index) {
    setState(() => _index = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(0);
      },
      child: Scaffold(
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _index = index),
            children: _tabs
                .map(
                  (tab) => _KeepAlivePage(
                    child: tab.builder(
                      context,
                      widget.api,
                      widget.history,
                      _openTab,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _selectTab,
          destinations: _tabs
              .map(
                (tab) => NavigationDestination(
                  icon: tab.icon,
                  label: tab.label,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

// Keeps the tab's widget tree alive after the first visit so state
// (scroll position, search results, etc.) survives swiping away.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
