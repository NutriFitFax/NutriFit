import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrifit/api/api_client.dart';
import 'package:nutrifit/api/api_exception.dart';

const _foodJson = '''
{
  "id": "737628064502",
  "name": "Peanut Butter",
  "brand": "Acme",
  "image_url": null,
  "serving_size_g": 30.0,
  "macros_per_100g": {
    "calories_kcal": 588.0,
    "protein_g": 25.0,
    "carbs_g": 20.0,
    "fat_g": 50.0
  }
}
''';

const _mealJson = '''
{
  "items": [
    {
      "name": "grilled chicken breast",
      "estimated_grams": 150.0,
      "confidence": 0.92,
      "macros_per_100g": {
        "calories_kcal": 165.0,
        "protein_g": 31.0,
        "carbs_g": 0.0,
        "fat_g": 3.6
      }
    }
  ],
  "total_calories_kcal": 247.5,
  "total_protein_g": 46.5,
  "total_carbs_g": 0.0,
  "total_fat_g": 5.4,
  "source": "ai",
  "notes": null
}
''';

const _emptyMealJson = '''
{
  "items": [],
  "total_calories_kcal": 0.0,
  "total_protein_g": 0.0,
  "total_carbs_g": 0.0,
  "total_fat_g": 0.0,
  "source": "ai",
  "notes": null
}
''';

const _searchJson = '''
{
  "query": "yogurt",
  "page": 1,
  "page_size": 20,
  "total": 1,
  "items": [
    {
      "id": "food1",
      "name": "Greek Yogurt",
      "macros_per_100g": {
        "calories_kcal": 59.0,
        "protein_g": 10.0,
        "carbs_g": 3.6,
        "fat_g": 0.4
      }
    }
  ]
}
''';

const _errorJson = '{"detail": "something went wrong"}';

NutriFitApi _apiWith(MockClient client) => NutriFitApi(
      baseUrl: Uri.parse('http://test.local'),
      client: client,
    );

MockClient _respond(String body, int status) =>
    MockClient((_) async => http.Response(body, status));

void main() {
  group('getByBarcode', () {
    test('200 → returns Food with correct fields', () async {
      final api = _apiWith(_respond(_foodJson, 200));
      final food = await api.getByBarcode('737628064502');
      expect(food.name, 'Peanut Butter');
      expect(food.brand, 'Acme');
      expect(food.macrosPer100g.caloriesKcal, 588.0);
    });

    test('404 → throws NotFoundException', () async {
      final api = _apiWith(_respond(_errorJson, 404));
      expect(api.getByBarcode('000000000000'), throwsA(isA<NotFoundException>()));
    });

    test('400 → throws BadRequestException', () async {
      final api = _apiWith(_respond(_errorJson, 400));
      expect(api.getByBarcode('bad'), throwsA(isA<BadRequestException>()));
    });

    test('502 → throws UpstreamException', () async {
      final api = _apiWith(_respond(_errorJson, 502));
      expect(api.getByBarcode('737628064502'), throwsA(isA<UpstreamException>()));
    });

    test('503 → throws UpstreamException', () async {
      final api = _apiWith(_respond(_errorJson, 503));
      expect(api.getByBarcode('737628064502'), throwsA(isA<UpstreamException>()));
    });

    test('504 → throws UpstreamException', () async {
      final api = _apiWith(_respond(_errorJson, 504));
      expect(api.getByBarcode('737628064502'), throwsA(isA<UpstreamException>()));
    });

    test('500 → throws ServerException', () async {
      final api = _apiWith(_respond(_errorJson, 500));
      expect(api.getByBarcode('737628064502'), throwsA(isA<ServerException>()));
    });

    test('network error → throws NetworkException', () async {
      final api = _apiWith(MockClient((_) async => throw const SocketException('no route')));
      expect(api.getByBarcode('737628064502'), throwsA(isA<NetworkException>()));
    });
  });

  group('estimateMeal', () {
    test('200 with items → returns MealEstimate', () async {
      final api = _apiWith(_respond(_mealJson, 200));
      final estimate = await api.estimateMeal(Uint8List(0));
      expect(estimate.items, hasLength(1));
      expect(estimate.items.first.name, 'grilled chicken breast');
      expect(estimate.items.first.confidence, 0.92);
      expect(estimate.totalCaloriesKcal, 247.5);
      expect(estimate.source, 'ai');
    });

    test('200 with empty items → no food detected case', () async {
      final api = _apiWith(_respond(_emptyMealJson, 200));
      final estimate = await api.estimateMeal(Uint8List(0));
      expect(estimate.items, isEmpty);
    });

    test('413 → throws BadRequestException (image too large)', () async {
      final api = _apiWith(_respond(_errorJson, 413));
      expect(api.estimateMeal(Uint8List(0)), throwsA(isA<BadRequestException>()));
    });

    test('400 → throws BadRequestException (invalid image)', () async {
      final api = _apiWith(_respond(_errorJson, 400));
      expect(api.estimateMeal(Uint8List(0)), throwsA(isA<BadRequestException>()));
    });

    test('502 → throws UpstreamException (OpenAI/USDA down)', () async {
      final api = _apiWith(_respond(_errorJson, 502));
      expect(api.estimateMeal(Uint8List(0)), throwsA(isA<UpstreamException>()));
    });

    test('network error → throws NetworkException', () async {
      final api = _apiWith(MockClient((_) async => throw const SocketException('offline')));
      expect(api.estimateMeal(Uint8List(0)), throwsA(isA<NetworkException>()));
    });
  });

  group('search', () {
    test('200 → returns SearchResult with items', () async {
      final api = _apiWith(_respond(_searchJson, 200));
      final result = await api.search('yogurt');
      expect(result.query, 'yogurt');
      expect(result.total, 1);
      expect(result.items, hasLength(1));
      expect(result.items.first.name, 'Greek Yogurt');
    });

    test('sends correct query params', () async {
      Uri? captured;
      final api = _apiWith(MockClient((req) async {
        captured = req.url;
        return http.Response(_searchJson, 200);
      }));
      await api.search('chicken', page: 2, pageSize: 10);
      expect(captured?.queryParameters['q'], 'chicken');
      expect(captured?.queryParameters['page'], '2');
      expect(captured?.queryParameters['page_size'], '10');
    });
  });

  group('ping', () {
    test('200 → returns true', () async {
      final api = _apiWith(_respond('ok', 200));
      expect(await api.ping(), isTrue);
    });

    test('503 → returns false', () async {
      final api = _apiWith(_respond('', 503));
      expect(await api.ping(), isFalse);
    });

    test('network error → returns false', () async {
      final api = _apiWith(MockClient((_) async => throw const SocketException('offline')));
      expect(await api.ping(), isFalse);
    });
  });
}
