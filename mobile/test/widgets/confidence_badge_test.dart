import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/app/nutri_colors.dart';
import 'package:nutrifit/features/meal_estimation/widgets/confidence_badge.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(extensions: const [NutriColors.light]),
      home: Scaffold(body: child),
    );

void main() {
  group('ConfidenceBadge', () {
    testWidgets('shows High confidence at exactly 0.85', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.85)));
      expect(find.text('High confidence · 85%'), findsOneWidget);
    });

    testWidgets('shows High confidence above 0.85', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.92)));
      expect(find.text('High confidence · 92%'), findsOneWidget);
    });

    testWidgets('shows Estimate at exactly 0.70', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.70)));
      expect(find.text('Estimate · 70%'), findsOneWidget);
    });

    testWidgets('shows Estimate just below 0.85', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.80)));
      expect(find.text('Estimate · 80%'), findsOneWidget);
    });

    testWidgets('shows Low confidence below 0.70', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.30)));
      expect(find.text('Low confidence · 30%'), findsOneWidget);
    });

    testWidgets('never shows multiple labels at once', (tester) async {
      await tester.pumpWidget(_wrap(const ConfidenceBadge(confidence: 0.90)));
      expect(find.text('High confidence · 90%'), findsOneWidget);
      expect(find.textContaining('Estimate'), findsNothing);
      expect(find.textContaining('Low confidence'), findsNothing);
    });
  });
}
