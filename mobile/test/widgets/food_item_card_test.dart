import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/api/models.dart';
import 'package:nutrifit/app/nutri_colors.dart';
import 'package:nutrifit/features/meal_estimation/widgets/food_item_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(extensions: const [NutriColors.light]),
      home: Scaffold(body: child),
    );

EstimatedFood _item({
  String name = 'chicken breast',
  double grams = 150,
  double confidence = 0.85,
  double cal = 165,
  double protein = 31,
  double carbs = 0,
  double fat = 3.6,
}) =>
    EstimatedFood(
      name: name,
      estimatedGrams: grams,
      confidence: confidence,
      macrosPer100g: Macros(
        caloriesKcal: cal,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
      ),
    );

void main() {
  group('FoodItemCard', () {
    testWidgets('capitalizes food name', (tester) async {
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(name: 'rice'))));
      expect(find.text('Rice'), findsOneWidget);
    });

    testWidgets('already-capitalized name is unchanged', (tester) async {
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(name: 'Oatmeal'))));
      expect(find.text('Oatmeal'), findsOneWidget);
    });

    testWidgets('shows estimated grams', (tester) async {
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(grams: 200))));
      expect(find.text('~200 g'), findsOneWidget);
    });

    testWidgets('shows grams rounded to whole number', (tester) async {
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(grams: 133.7))));
      expect(find.text('~134 g'), findsOneWidget);
    });

    testWidgets('shows scaled calories', (tester) async {
      // 165 kcal per 100g × 150g = 247.5 → rounds to "248"
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(cal: 165, grams: 150))));
      expect(find.text('248'), findsOneWidget);
      expect(find.text('kcal'), findsOneWidget);
    });

    testWidgets('shows scaled protein with one decimal', (tester) async {
      // 31g per 100g × 150g = 46.5g → shown as "46.5 P"
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(protein: 31, grams: 150))));
      expect(find.text('46.5 P'), findsOneWidget);
    });

    testWidgets('shows scaled carbs with one decimal', (tester) async {
      // 20g carbs per 100g × 200g = 40.0g → shown as "40.0 C"
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(carbs: 20, grams: 200))));
      expect(find.text('40.0 C'), findsOneWidget);
    });

    testWidgets('shows scaled fat with one decimal', (tester) async {
      // 3.6g fat per 100g × 150g = 5.4g → shown as "5.4 F"
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(fat: 3.6, grams: 150))));
      expect(find.text('5.4 F'), findsOneWidget);
    });

    testWidgets('always shows confidence badge', (tester) async {
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(confidence: 0.92))));
      expect(find.text('High confidence · 92%'), findsOneWidget);
    });

    testWidgets('fires onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(), onTap: () => tapped = true)));
      await tester.tap(find.byType(FoodItemCard));
      expect(tapped, isTrue);
    });
  });
}
