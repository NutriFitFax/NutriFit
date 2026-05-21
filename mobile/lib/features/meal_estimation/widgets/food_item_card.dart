import 'package:flutter/material.dart';

import '../../../api/models.dart';
import '../../../app/nutri_colors.dart';
import 'confidence_badge.dart';

class FoodItemCard extends StatelessWidget {
  final EstimatedFood item;
  final VoidCallback? onTap;
  const FoodItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final scaled = item.macrosPer100g.forGrams(item.estimatedGrams);
    final dom = _dominant(item.macrosPer100g);
    final (badgeBg, badgeFg, glyph) = switch (dom) {
      _Dom.protein => (c.proteinSoft, c.protein, 'P'),
      _Dom.carbs   => (c.carbsSoft,   c.carbs,   'C'),
      _Dom.fat     => (c.fatSoft,     c.fat,     'F'),
    };

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(
                      glyph,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: badgeFg, fontSize: 17, fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalize(item.name),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '~${item.estimatedGrams.toStringAsFixed(0)} g',
                          style: TextStyle(fontSize: 11.5, color: c.ink2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        scaled.caloriesKcal.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                      Text('kcal', style: TextStyle(fontSize: 10, color: c.ink3)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConfidenceBadge(confidence: item.confidence),
                  Row(
                    children: [
                      _MacroChip(value: scaled.proteinG, label: 'P', color: c.protein),
                      const SizedBox(width: 10),
                      _MacroChip(value: scaled.carbsG,   label: 'C', color: c.carbs),
                      const SizedBox(width: 10),
                      _MacroChip(value: scaled.fatG,     label: 'F', color: c.fat),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  _Dom _dominant(Macros m) {
    final p = m.proteinG * 4, c = m.carbsG * 4, f = m.fatG * 9;
    if (p >= c && p >= f) return _Dom.protein;
    if (f >= c) return _Dom.fat;
    return _Dom.carbs;
  }
}

enum _Dom { protein, carbs, fat }

class _MacroChip extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const _MacroChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value.toStringAsFixed(1),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
          TextSpan(text: ' $label', style: TextStyle(fontSize: 11.5, color: c.ink2)),
        ],
      ),
    );
  }
}
