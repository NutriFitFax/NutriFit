import 'package:flutter/material.dart';

import '../app/nutri_colors.dart';

/// A row of 8 outlined glass tokens that fill in proportionally to
/// [currentMl] / [goalMl]. Tap-area is delegated to the parent (wrap in
/// a [WarmCard] with `onTap`).
class WaterGlasses extends StatelessWidget {
  final int currentMl;
  final int goalMl;
  final int count;

  const WaterGlasses({
    super.key,
    required this.currentMl,
    required this.goalMl,
    this.count = 8,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final filledCount = (currentMl / goalMl * count).round().clamp(0, count);

    return Row(
      children: List.generate(count, (i) {
        final filled = i < filledCount;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
            height: 26,
            decoration: BoxDecoration(
              color: filled ? c.water.withValues(alpha: 0.85) : Colors.transparent,
              border: Border.all(color: c.water.withValues(alpha: filled ? 0.85 : 0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
