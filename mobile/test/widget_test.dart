import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nutrifit/api/api_client.dart';
import 'package:nutrifit/app/settings_prefs.dart';
import 'package:nutrifit/db/daily_log.dart';
import 'package:nutrifit/features/history/viewed_food_history_store.dart';
import 'package:nutrifit/main.dart';

// Minimal in-memory store so tests never touch SQLite.
class _FakeStore implements DailyLogStore {
  // Single notifier instance — must not be recreated on each access or
  // ValueListenableBuilder will listen to one object and read from another.
  final _notifier = ValueNotifier(const DailyLog(
    goalCalories: 2000, goalProteinG: 130, goalCarbsG: 240, goalFatG: 70,
    goalWaterMl: 2500, consumedCalories: 0, consumedProteinG: 0,
    consumedCarbsG: 0, consumedFatG: 0, consumedWaterMl: 0,
    meals: [], latestWeightKg: null, heightCm: 170, weightTrend: [],
  ));

  @override
  ValueListenable<DailyLog> get todayListenable => _notifier;

  @override Future<void> logMeal({required String name, required double caloriesKcal, required double proteinG, required double carbsG, required double fatG}) async {}
  @override Future<void> deleteMeal(int id) async {}
  @override Future<void> logWater(int amountMl) async {}
  @override Future<void> logWeight(double weightKg) async {}
  @override Future<void> refresh() async {}
  @override Future<void> clearAllData() async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsPrefs.init();
  });

  testWidgets('shows login screen when no user is signed in', (tester) async {
    final api = NutriFitApi(baseUrl: Uri.parse('http://localhost:8000'));
    await tester.pumpWidget(NutriFitApp(
      api: api,
      history: InMemoryViewedFoodHistoryStore(),
      store: _FakeStore(),
    ));

    expect(find.text('NutriFit'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    api.close();
  });

  testWidgets('bottom nav renders five tabs when signed in', (tester) async {
    SharedPreferences.setMockInitialValues({'user_email': 'test@example.com'});
    await SettingsPrefs.init();

    final api = NutriFitApi(baseUrl: Uri.parse('http://localhost:8000'));
    await tester.pumpWidget(NutriFitApp(
      api: api,
      history: InMemoryViewedFoodHistoryStore(),
      store: _FakeStore(),
    ));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Meal'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    api.close();
  });
}
