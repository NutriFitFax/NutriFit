import 'package:flutter/material.dart';

import '../../../api/models.dart';

class MealTotalsFooter extends StatelessWidget {
  final MealEstimate estimate;

  const MealTotalsFooter({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    final t = estimate;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Meal total',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Total('Calories',
                    '${t.totalCaloriesKcal.toStringAsFixed(0)} kcal',
                    large: true),
                _Total('Protein', '${t.totalProteinG.toStringAsFixed(1)} g'),
                _Total('Carbs', '${t.totalCarbsG.toStringAsFixed(1)} g'),
                _Total('Fat', '${t.totalFatG.toStringAsFixed(1)} g'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final String value;
  final bool large;

  const _Total(this.label, this.value, {this.large = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: large ? 18 : 14,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}
