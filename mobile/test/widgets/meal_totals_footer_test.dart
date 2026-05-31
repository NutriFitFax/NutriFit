import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/api/models.dart';
import 'package:nutrifit/app/nutri_colors.dart';
import 'package:nutrifit/db/daily_log.dart';
import 'package:nutrifit/features/meal_estimation/widgets/meal_totals_footer.dart';

class _FakeStore implements DailyLogStore {
  final _notifier = ValueNotifier(const DailyLog(
    goalCalories: 2000, goalProteinG: 130, goalCarbsG: 240, goalFatG: 70,
    goalWaterMl: 2500, consumedCalories: 0, consumedProteinG: 0,
    consumedCarbsG: 0, consumedFatG: 0, consumedWaterMl: 0,
    meals: [], latestWeightKg: null, heightCm: 170, weightTrend: [],
  ));
  @override ValueListenable<DailyLog> get todayListenable => _notifier;
  @override Future<void> logMeal({required String name, required double caloriesKcal, required double proteinG, required double carbsG, required double fatG}) async {}
  @override Future<void> deleteMeal(int id) async {}
  @override Future<void> logWater(int amountMl) async {}
  @override Future<void> logWeight(double weightKg) async {}
  @override Future<void> refresh() async {}
  @override Future<void> clearAllData() async {}
  @override Future<void> resetTodayWater() async {}
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(extensions: const [NutriColors.light]),
      home: Scaffold(body: child),
    );

MealEstimate _estimate({
  double cal = 520,
  double protein = 42.5,
  double carbs = 38.0,
  double fat = 18.2,
}) =>
    MealEstimate(
      items: const [],
      totalCaloriesKcal: cal,
      totalProteinG: protein,
      totalCarbsG: carbs,
      totalFatG: fat,
      source: 'stub',
    );

void main() {
  group('MealTotalsFooter', () {
    testWidgets('shows MEAL TOTAL label', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(), store: _FakeStore())));
      expect(find.text('MEAL TOTAL'), findsOneWidget);
    });

    testWidgets('shows calories with no decimals and kcal unit', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(cal: 520), store: _FakeStore())));
      expect(find.text('520 kcal'), findsOneWidget);
    });

    testWidgets('calories rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(cal: 347.7), store: _FakeStore())));
      expect(find.text('348 kcal'), findsOneWidget);
    });

    testWidgets('shows protein rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(protein: 42.5), store: _FakeStore())));
      expect(find.text('43'), findsOneWidget);
    });

    testWidgets('shows carbs rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(carbs: 38.0), store: _FakeStore())));
      expect(find.text('38'), findsOneWidget);
    });

    testWidgets('shows fat rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(fat: 18.2), store: _FakeStore())));
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('shows P C F macro labels', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(), store: _FakeStore())));
      expect(find.text('P'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });
  });
}
