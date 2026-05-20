import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/api/models.dart';

void main() {
  group('Macros.fromJson', () {
    test('parses all fields', () {
      final m = Macros.fromJson({
        'calories_kcal': 588.0,
        'protein_g': 25.0,
        'carbs_g': 20.0,
        'fat_g': 50.0,
        'fiber_g': 6.0,
        'sugar_g': 9.0,
        'salt_g': 0.5,
      });
      expect(m.caloriesKcal, 588.0);
      expect(m.proteinG, 25.0);
      expect(m.carbsG, 20.0);
      expect(m.fatG, 50.0);
      expect(m.fiberG, 6.0);
      expect(m.sugarG, 9.0);
      expect(m.saltG, 0.5);
    });

    test('optional fields are null when absent', () {
      final m = Macros.fromJson({
        'calories_kcal': 100.0,
        'protein_g': 10.0,
        'carbs_g': 5.0,
        'fat_g': 3.0,
      });
      expect(m.fiberG, isNull);
      expect(m.sugarG, isNull);
      expect(m.saltG, isNull);
    });
  });

  group('Macros.forGrams', () {
    const per100g = Macros(
      caloriesKcal: 200.0,
      proteinG: 10.0,
      carbsG: 20.0,
      fatG: 5.0,
      fiberG: 4.0,
    );

    test('scales down to 50g', () {
      final per50g = per100g.forGrams(50);
      expect(per50g.caloriesKcal, 100.0);
      expect(per50g.proteinG, 5.0);
      expect(per50g.carbsG, 10.0);
      expect(per50g.fatG, 2.5);
      expect(per50g.fiberG, 2.0);
    });

    test('scales up to 200g', () {
      final per200g = per100g.forGrams(200);
      expect(per200g.caloriesKcal, 400.0);
      expect(per200g.proteinG, 20.0);
    });

    test('keeps null optional fields null after scaling', () {
      final per50g = per100g.forGrams(50);
      expect(per50g.sugarG, isNull);
    });

    test('returns zero macros for 0g', () {
      final per0g = per100g.forGrams(0);
      expect(per0g.caloriesKcal, 0.0);
      expect(per0g.proteinG, 0.0);
    });
  });

  group('Food.fromJson', () {
    test('parses required fields, optional fields null', () {
      final food = Food.fromJson({
        'id': 'abc123',
        'name': 'Peanut Butter',
        'macros_per_100g': {
          'calories_kcal': 588.0,
          'protein_g': 25.0,
          'carbs_g': 20.0,
          'fat_g': 50.0,
        },
      });
      expect(food.id, 'abc123');
      expect(food.name, 'Peanut Butter');
      expect(food.brand, isNull);
      expect(food.imageUrl, isNull);
      expect(food.servingSizeG, isNull);
      expect(food.macrosPer100g.caloriesKcal, 588.0);
    });

    test('parses optional fields when present', () {
      final food = Food.fromJson({
        'id': 'abc123',
        'name': 'Peanut Butter',
        'brand': 'Acme',
        'image_url': 'https://example.com/img.jpg',
        'serving_size_g': 30.0,
        'macros_per_100g': {
          'calories_kcal': 588.0,
          'protein_g': 25.0,
          'carbs_g': 20.0,
          'fat_g': 50.0,
        },
      });
      expect(food.brand, 'Acme');
      expect(food.imageUrl, 'https://example.com/img.jpg');
      expect(food.servingSizeG, 30.0);
    });
  });

  group('MealEstimate.fromJson', () {
    test('parses items, totals, and source', () {
      final estimate = MealEstimate.fromJson({
        'items': [
          {
            'name': 'grilled chicken breast',
            'estimated_grams': 150.0,
            'confidence': 0.92,
            'macros_per_100g': {
              'calories_kcal': 165.0,
              'protein_g': 31.0,
              'carbs_g': 0.0,
              'fat_g': 3.6,
            },
          },
        ],
        'total_calories_kcal': 247.5,
        'total_protein_g': 46.5,
        'total_carbs_g': 0.0,
        'total_fat_g': 5.4,
        'source': 'ai',
        'notes': null,
      });
      expect(estimate.items, hasLength(1));
      expect(estimate.items.first.name, 'grilled chicken breast');
      expect(estimate.items.first.estimatedGrams, 150.0);
      expect(estimate.items.first.confidence, 0.92);
      expect(estimate.totalCaloriesKcal, 247.5);
      expect(estimate.source, 'ai');
      expect(estimate.notes, isNull);
    });

    test('empty items list is valid', () {
      final estimate = MealEstimate.fromJson({
        'items': [],
        'total_calories_kcal': 0.0,
        'total_protein_g': 0.0,
        'total_carbs_g': 0.0,
        'total_fat_g': 0.0,
        'source': 'ai',
        'notes': 'No food detected',
      });
      expect(estimate.items, isEmpty);
      expect(estimate.notes, 'No food detected');
    });
  });

  group('SearchResult.fromJson', () {
    test('parses pagination metadata and items', () {
      final result = SearchResult.fromJson({
        'query': 'yogurt',
        'page': 1,
        'page_size': 20,
        'total': 42,
        'items': [
          {
            'id': 'food1',
            'name': 'Greek Yogurt',
            'macros_per_100g': {
              'calories_kcal': 59.0,
              'protein_g': 10.0,
              'carbs_g': 3.6,
              'fat_g': 0.4,
            },
          },
        ],
      });
      expect(result.query, 'yogurt');
      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.total, 42);
      expect(result.items, hasLength(1));
      expect(result.items.first.name, 'Greek Yogurt');
    });

    test('empty items list is valid', () {
      final result = SearchResult.fromJson({
        'query': 'xyznonexistent',
        'page': 1,
        'page_size': 20,
        'total': 0,
        'items': [],
      });
      expect(result.items, isEmpty);
      expect(result.total, 0);
    });
  });
}
