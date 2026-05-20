import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/api/models.dart';
import 'package:nutrifit/features/meal_estimation/widgets/meal_totals_footer.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

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
    testWidgets('shows Meal total label', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate())));
      expect(find.text('Meal total'), findsOneWidget);
    });

    testWidgets('shows calories with no decimals and kcal unit', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(cal: 520))));
      expect(find.text('520 kcal'), findsOneWidget);
    });

    testWidgets('calories rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(cal: 347.7))));
      expect(find.text('348 kcal'), findsOneWidget);
    });

    testWidgets('shows protein with one decimal and g unit', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(protein: 42.5))));
      expect(find.text('42.5 g'), findsOneWidget);
    });

    testWidgets('shows carbs with one decimal and g unit', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(carbs: 38.0))));
      expect(find.text('38.0 g'), findsOneWidget);
    });

    testWidgets('shows fat with one decimal and g unit', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate(fat: 18.2))));
      expect(find.text('18.2 g'), findsOneWidget);
    });

    testWidgets('shows all four macro labels', (tester) async {
      await tester.pumpWidget(_wrap(MealTotalsFooter(estimate: _estimate())));
      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
    });
  });
}
