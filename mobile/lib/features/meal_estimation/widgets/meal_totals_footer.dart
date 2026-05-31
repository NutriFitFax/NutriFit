import 'package:flutter/material.dart';

import '../../../api/models.dart';
import '../../../app/haptics.dart';
import '../../../app/nutri_colors.dart';
import '../../../db/daily_log.dart';

class MealTotalsFooter extends StatelessWidget {
  final MealEstimate estimate;
  final DailyLogStore store;
  const MealTotalsFooter({super.key, required this.estimate, required this.store});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final t = estimate;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEAL TOTAL',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: c.ink2, letterSpacing: 0.8,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
                          children: [
                            TextSpan(text: t.totalCaloriesKcal.toStringAsFixed(0)),
                            TextSpan(text: ' kcal', style: TextStyle(fontSize: 16, color: c.ink2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _Mini(value: t.totalProteinG, label: 'P', color: c.protein),
                    const SizedBox(width: 14),
                    _Mini(value: t.totalCarbsG,   label: 'C', color: c.carbs),
                    const SizedBox(width: 14),
                    _Mini(value: t.totalFatG,     label: 'F', color: c.fat),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Haptics.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tap a food above to adjust its portion')),
                      );
                    },
                    child: const Text('Adjust portions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Haptics.mediumImpact();
                      for (final item in t.items) {
                        final m = item.macrosPer100g.forGrams(item.estimatedGrams);
                        await store.logMeal(
                          name: item.name,
                          caloriesKcal: m.caloriesKcal,
                          proteinG: m.proteinG,
                          carbsG: m.carbsG,
                          fatG: m.fatG,
                        );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${t.items.length} foods logged to today')),
                        );
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      }
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Log all ${t.items.length}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const _Mini({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toStringAsFixed(0),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 9, color: c.ink3, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
      ],
    );
  }
}
