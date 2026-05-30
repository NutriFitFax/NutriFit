import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../features/barcode/barcode_scanner_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/viewed_food_history_store.dart';
import '../features/meal_estimation/meal_entry_screen.dart';
import '../features/settings/settings_screen.dart';
import '../screens/search_screen.dart';
import '../ui/barcode_icon.dart';
import 'home_dashboard_screen.dart';
import 'nutri_colors.dart';

enum AppTabId { home, search, barcode, meal, history }

class AppShell extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const AppShell({super.key, required this.api, required this.history});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openTab(AppTabId id) {
    final next = AppTabId.values.indexOf(id);
    if (next == -1 || next == _index) return;
    _selectTab(next);
    HapticFeedback.lightImpact();
  }

  void _selectTab(int index) {
    setState(() => _index = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final selectedColor = c.primary;
    final unselectedColor = c.ink2;

    final tabs = <_TabDef>[
      _TabDef(
        id: AppTabId.home,
        label: 'Home',
        icon: Icon(Icons.home_outlined, color: unselectedColor),
        activeIcon: Icon(Icons.home_rounded, color: selectedColor),
        build: () => HomeDashboardScreen(
          history: widget.history,
          onOpenTab: _openTab,
          onOpenSettings: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(
                api: widget.api,
                history: widget.history,
              ),
            ),
          ),
        ),
      ),
      _TabDef(
        id: AppTabId.search,
        label: 'Search',
        icon: Icon(Icons.search, color: unselectedColor),
        activeIcon: Icon(Icons.search, color: selectedColor),
        build: () => SearchScreen(api: widget.api, history: widget.history),
      ),
      _TabDef(
        id: AppTabId.barcode,
        label: 'Scan',
        icon: BarcodeIcon(size: 22, color: unselectedColor),
        activeIcon: BarcodeIcon(size: 22, color: selectedColor),
        build: () => BarcodeScannerScreen(
          api: widget.api,
          history: widget.history,
          onGoToSearch: () => _openTab(AppTabId.search),
        ),
      ),
      _TabDef(
        id: AppTabId.meal,
        label: 'Meal',
        icon: Icon(Icons.camera_alt_outlined, color: unselectedColor),
        activeIcon: Icon(Icons.camera_alt, color: selectedColor),
        build: () => MealEntryScreen(api: widget.api, history: widget.history),
      ),
      _TabDef(
        id: AppTabId.history,
        label: 'History',
        icon: Icon(Icons.history, color: unselectedColor),
        activeIcon: Icon(Icons.history, color: selectedColor),
        build: () => HistoryScreen(history: widget.history),
      ),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(0);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _index = index),
            children: tabs
                .map((t) => _KeepAlivePage(child: t.build()))
                .toList(growable: false),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _selectTab,
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: t.icon,
                  selectedIcon: t.activeIcon,
                  label: t.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  final AppTabId id;
  final String label;
  final Widget icon;
  final Widget activeIcon;
  final Widget Function() build;
  const _TabDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.build,
  });
}

// Keeps each tab's widget tree alive so scroll position and state survive
// swiping away.
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
