import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/features/meal_estimation/widgets/confidence_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ConfidenceBadge', () {
    testWidgets('shows High confidence at exactly 0.75', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.75)));
      expect(find.text('High confidence'), findsOneWidget);
    });

    testWidgets('shows High confidence above 0.75', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.92)));
      expect(find.text('High confidence'), findsOneWidget);
    });

    testWidgets('shows Estimate just below 0.75', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.74)));
      expect(find.text('Estimate'), findsOneWidget);
    });

    testWidgets('shows Estimate for low confidence', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.30)));
      expect(find.text('Estimate'), findsOneWidget);
    });

    testWidgets('never shows both labels at once', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.80)));
      expect(find.text('High confidence'), findsOneWidget);
      expect(find.text('Estimate'), findsNothing);
    });
  });
}
