import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/api/models.dart';
import 'package:nutrifit/app/nutri_colors.dart';
import 'package:nutrifit/features/meal_estimation/widgets/meal_totals_footer.dart';

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
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate())));
      expect(find.text('MEAL TOTAL'), findsOneWidget);
    });

    testWidgets('shows calories with no decimals and kcal unit', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(cal: 520))));
      expect(find.text('520 kcal'), findsOneWidget);
    });

    testWidgets('calories rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(cal: 347.7))));
      expect(find.text('348 kcal'), findsOneWidget);
    });

    testWidgets('shows protein rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(protein: 42.5))));
      expect(find.text('43'), findsOneWidget);
    });

    testWidgets('shows carbs rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(carbs: 38.0))));
      expect(find.text('38'), findsOneWidget);
    });

    testWidgets('shows fat rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(fat: 18.2))));
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('shows P C F macro labels', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate())));
      expect(find.text('P'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });
  });
}
