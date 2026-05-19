import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/api_config.dart';
import 'screens/barcode_screen.dart';
import 'screens/meal_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(NutriFitApp(api: NutriFitApi(baseUrl: ApiConfig.baseUrl)));
}

class NutriFitApp extends StatelessWidget {
  final NutriFitApi api;
  const NutriFitApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFit',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: HomeShell(api: api),
    );
  }
}

class HomeShell extends StatefulWidget {
  final NutriFitApi api;
  const HomeShell({super.key, required this.api});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      SearchScreen(api: widget.api),
      BarcodeScreen(api: widget.api),
      MealScreen(api: widget.api),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Barcode'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Meal'),
        ],
      ),
    );
  }
}
