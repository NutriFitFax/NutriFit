import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/api/models.dart';
import 'package:nutrifit/features/meal_estimation/widgets/food_item_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

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
      // 165 kcal per 100g × 150g = 247.5 → rounds to "248 kcal"
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(cal: 165, grams: 150))));
      expect(find.text('248 kcal'), findsOneWidget);
    });

    testWidgets('shows scaled protein with one decimal', (tester) async {
      // 31g per 100g × 150g = 46.5g
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(protein: 31, grams: 150))));
      expect(find.text('46.5 g'), findsOneWidget);
    });

    testWidgets('shows scaled carbs with one decimal', (tester) async {
      // 20g carbs per 100g × 200g = 40.0g
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(carbs: 20, grams: 200))));
      expect(find.text('40.0 g'), findsOneWidget);
    });

    testWidgets('shows scaled fat with one decimal', (tester) async {
      // 3.6g fat per 100g × 150g = 5.4g
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(fat: 3.6, grams: 150))));
      expect(find.text('5.4 g'), findsOneWidget);
    });

    testWidgets('hides Adjust portion when onTap is null', (tester) async {
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item())));
      expect(find.text('Adjust portion'), findsNothing);
    });

    testWidgets('shows Adjust portion when onTap is provided', (tester) async {
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(), onTap: () {})));
      expect(find.text('Adjust portion'), findsOneWidget);
    });

    testWidgets('fires onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(FoodItemCard(item: _item(), onTap: () => tapped = true)));
      await tester.tap(find.byType(FoodItemCard));
      expect(tapped, isTrue);
    });
  });
}
