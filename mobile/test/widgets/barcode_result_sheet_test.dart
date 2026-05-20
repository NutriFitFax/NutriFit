import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';
import 'package:nutrifit/api/api_client.dart';
import 'package:nutrifit/features/barcode/barcode_result_sheet.dart';
import 'package:nutrifit/features/history/viewed_food_history_store.dart';

const _baseUrl = 'http://localhost';

const _foodJson = {
  'id': 'f1',
  'name': 'Chicken Breast',
  'brand': 'Generic',
  'macros_per_100g': {
    'calories_kcal': 165.0,
    'protein_g': 31.0,
    'carbs_g': 0.0,
    'fat_g': 3.6,
  },
};

NutriFitApi _apiWith(MockClient client) =>
    NutriFitApi(baseUrl: Uri.parse(_baseUrl), client: client);

Widget _sheet(
  NutriFitApi api, {
  VoidCallback? onScanAgain,
  VoidCallback? onEnterManually,
}) =>
    MaterialApp(
      home: Scaffold(
        body: BarcodeResultSheet(
          barcode: '1234567890',
          api: api,
          history: InMemoryViewedFoodHistoryStore(),
          onScanAgain: onScanAgain ?? () {},
          onEnterManually: onEnterManually,
        ),
      ),
    );

void main() {
  group('BarcodeResultSheet', () {
    testWidgets('shows loading state before response arrives', (tester) async {
      final client = MockClient((_) async {
        // Delay so the widget renders in loading state first.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Response(jsonEncode(_foodJson), 200,
            headers: {'content-type': 'application/json'});
      });
      await tester.pumpWidget(_sheet(_apiWith(client)));
      // First frame: future not resolved yet.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Looking up product…'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('shows food name and brand on success', (tester) async {
      final client = MockClient((_) async => Response(
            jsonEncode(_foodJson),
            200,
            headers: {'content-type': 'application/json'},
          ));
      await tester.pumpWidget(_sheet(_apiWith(client)));
      await tester.pumpAndSettle();
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Generic'), findsOneWidget);
    });

    testWidgets('shows View full nutrition and Scan another on success', (tester) async {
      final client = MockClient((_) async => Response(
            jsonEncode(_foodJson),
            200,
            headers: {'content-type': 'application/json'},
          ));
      await tester.pumpWidget(_sheet(_apiWith(client)));
      await tester.pumpAndSettle();
      expect(find.text('View full nutrition'), findsOneWidget);
      expect(find.text('Scan another'), findsOneWidget);
    });

    testWidgets('shows not-found error on 404', (tester) async {
      final client = MockClient((_) async => Response('', 404));
      await tester.pumpWidget(_sheet(_apiWith(client)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Product not found'), findsOneWidget);
    });

    testWidgets('shows retry and scan again on error', (tester) async {
      final client = MockClient((_) async => Response('', 404));
      await tester.pumpWidget(_sheet(_apiWith(client)));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Scan again'), findsOneWidget);
    });

    testWidgets('shows upstream error on 503', (tester) async {
      final client = MockClient((_) async => Response('', 503));
      await tester.pumpWidget(_sheet(_apiWith(client)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Service is having trouble'), findsOneWidget);
    });

    testWidgets('fires onScanAgain when Scan another is tapped on success', (tester) async {
      final client = MockClient((_) async => Response(
            jsonEncode(_foodJson),
            200,
            headers: {'content-type': 'application/json'},
          ));
      var fired = false;
      await tester.pumpWidget(_sheet(_apiWith(client), onScanAgain: () => fired = true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan another'));
      await tester.pumpAndSettle();
      expect(fired, isTrue);
    });

    testWidgets('fires onScanAgain when Scan again is tapped on error', (tester) async {
      final client = MockClient((_) async => Response('', 404));
      var fired = false;
      await tester.pumpWidget(_sheet(_apiWith(client), onScanAgain: () => fired = true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan again'));
      await tester.pumpAndSettle();
      expect(fired, isTrue);
    });

    testWidgets('shows Search by name button on 404 when onEnterManually provided', (tester) async {
      final client = MockClient((_) async => Response('', 404));
      await tester.pumpWidget(_sheet(_apiWith(client), onEnterManually: () {}));
      await tester.pumpAndSettle();
      expect(find.text('Search by name'), findsOneWidget);
    });

    testWidgets('hides Search by name button when onEnterManually is null', (tester) async {
      final client = MockClient((_) async => Response('', 404));
      await tester.pumpWidget(_sheet(_apiWith(client)));
      await tester.pumpAndSettle();
      expect(find.text('Search by name'), findsNothing);
    });

    testWidgets('hides Search by name button on non-404 errors', (tester) async {
      final client = MockClient((_) async => Response('', 503));
      await tester.pumpWidget(_sheet(_apiWith(client), onEnterManually: () {}));
      await tester.pumpAndSettle();
      expect(find.text('Search by name'), findsNothing);
    });

    testWidgets('fires onEnterManually when Search by name is tapped', (tester) async {
      final client = MockClient((_) async => Response('', 404));
      var fired = false;
      await tester.pumpWidget(_sheet(_apiWith(client), onEnterManually: () => fired = true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search by name'));
      await tester.pumpAndSettle();
      expect(fired, isTrue);
    });

    testWidgets('Retry triggers a new lookup', (tester) async {
      var callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        return Response('', 503);
      });
      await tester.pumpWidget(_sheet(_apiWith(client)));
      await tester.pumpAndSettle();
      expect(callCount, 1);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(callCount, 2);
    });
  });
}
