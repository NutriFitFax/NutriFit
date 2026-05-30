import 'package:flutter/material.dart';

import '../api/models.dart';
import '../app/haptics.dart';
import '../app/nutri_colors.dart';

/// Compact food row used in search results, recents, today's meals, etc.
///
/// Shows a coloured glyph badge (P / C / F based on dominant macro), the food
/// name + brand line, and a trailing kcal/100g chip. Tap-aware.
///
/// Replaces the old `food_list_tile.dart`. Add a [trailing] widget to
/// override the default kcal/100g block (e.g. show "Logged" or a portion size).
class FoodTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final Macros macrosPer100g;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? sourceLabel;

  const FoodTile({
    super.key,
    required this.name,
    this.subtitle,
    required this.macrosPer100g,
    this.onTap,
    this.trailing,
    this.sourceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final dom = _dominantMacro(macrosPer100g);

    final badgeBg = switch (dom) {
      _Macro.protein => c.proteinSoft,
      _Macro.carbs   => c.carbsSoft,
      _Macro.fat     => c.fatSoft,
    };
    final badgeFg = switch (dom) {
      _Macro.protein => c.protein,
      _Macro.carbs   => c.carbs,
      _Macro.fat     => c.fat,
    };
    final glyph = switch (dom) {
      _Macro.protein => 'P',
      _Macro.carbs   => 'C',
      _Macro.fat     => 'F',
    };

    final subtitleText = [
      if (subtitle != null && subtitle!.isNotEmpty) subtitle!,
      if (sourceLabel != null) sourceLabel!,
    ].join(' · ');

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onTap == null ? null : () { Haptics.selectionClick(); onTap!(); },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    glyph,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: badgeFg,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      if (subtitleText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: c.ink2),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    _DefaultTrailing(kcalPer100g: macrosPer100g.caloriesKcal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _Macro _dominantMacro(Macros m) {
    final p = m.proteinG * 4;
    final c = m.carbsG * 4;
    final f = m.fatG * 9;
    if (p >= c && p >= f) return _Macro.protein;
    if (f >= c)             return _Macro.fat;
    return _Macro.carbs;
  }
}

enum _Macro { protein, carbs, fat }

class _DefaultTrailing extends StatelessWidget {
  final double kcalPer100g;
  const _DefaultTrailing({required this.kcalPer100g});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          kcalPer100g.toStringAsFixed(0),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15, color: c.ink),
        ),
        Text(
          'kcal/100g',
          style: TextStyle(fontSize: 10, color: c.ink3, letterSpacing: 0.4),
        ),
      ],
    );
  }
}
