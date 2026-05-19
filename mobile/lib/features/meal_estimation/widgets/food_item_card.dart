import 'package:flutter/material.dart';

import '../../../api/models.dart';
import 'confidence_badge.dart';

class FoodItemCard extends StatelessWidget {
  final EstimatedFood item;
  final VoidCallback? onTap;

  const FoodItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scaled = item.macrosPer100g.forGrams(item.estimatedGrams);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _capitalize(item.name),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConfidenceBadge(confidence: item.confidence),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '~${item.estimatedGrams.toStringAsFixed(0)} g',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Macro('Cal', '${scaled.caloriesKcal.toStringAsFixed(0)} kcal'),
                  _Macro('Protein', '${scaled.proteinG.toStringAsFixed(1)} g'),
                  _Macro('Carbs', '${scaled.carbsG.toStringAsFixed(1)} g'),
                  _Macro('Fat', '${scaled.fatG.toStringAsFixed(1)} g'),
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Adjust portion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Macro extends StatelessWidget {
  final String label;
  final String value;
  const _Macro(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontSize: 11)),
        ],
      );
}
