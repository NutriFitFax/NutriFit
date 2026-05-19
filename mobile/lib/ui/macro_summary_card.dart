import 'package:flutter/material.dart';

import '../api/models.dart';

class MacroSummaryCard extends StatelessWidget {
  final String title;
  final Macros macros;
  final String? subtitle;
  final Widget? trailing;

  const MacroSummaryCard({
    super.key,
    required this.title,
    required this.macros,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(height: 24),
            MacroRow(
              label: 'Calories',
              value: '${macros.caloriesKcal.toStringAsFixed(0)} kcal',
            ),
            MacroRow(
              label: 'Protein',
              value: '${macros.proteinG.toStringAsFixed(1)} g',
            ),
            MacroRow(
              label: 'Carbs',
              value: '${macros.carbsG.toStringAsFixed(1)} g',
            ),
            MacroRow(
              label: 'Fat',
              value: '${macros.fatG.toStringAsFixed(1)} g',
            ),
            if (macros.fiberG != null)
              MacroRow(
                label: 'Fiber',
                value: '${macros.fiberG!.toStringAsFixed(1)} g',
              ),
          ],
        ),
      ),
    );
  }
}

class MacroRow extends StatelessWidget {
  final String label;
  final String value;

  const MacroRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
