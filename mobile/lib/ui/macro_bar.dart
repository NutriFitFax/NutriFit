import 'package:flutter/material.dart';

import '../app/nutri_colors.dart';

/// A single labelled macro progress bar.
///
/// ```
/// PROTEIN              79/130 g
/// ━━━━━━━━━━━━━━━━━━━━░░░░░░░░
/// ```
///
/// Animates from 0 to its target on mount and on value change.
class MacroBar extends StatefulWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  final String unit;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    this.unit = 'g',
  });

  @override
  State<MacroBar> createState() => _MacroBarState();
}

class _MacroBarState extends State<MacroBar> {
  bool _animated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animated = true);
    });
  }

  @override
  void didUpdateWidget(MacroBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.goal != widget.goal) {
      setState(() => _animated = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _animated = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final pct = widget.goal == 0
        ? 0.0
        : (widget.value / widget.goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: c.ink2, letterSpacing: 0.6,
              ),
            ),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 14, color: c.ink,
                    ),
                children: [
                  TextSpan(text: widget.value.round().toString()),
                  TextSpan(
                    text: '/${widget.goal.round()}${widget.unit}',
                    style: TextStyle(color: c.ink3, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 7,
            color: c.line,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                widthFactor: _animated ? pct : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Convenience layout — three [MacroBar]s stacked with consistent spacing.
class MacroStack extends StatelessWidget {
  final double protein, carbs, fat;
  final double proteinGoal, carbsGoal, fatGoal;
  const MacroStack({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacroBar(label: 'Protein', value: protein, goal: proteinGoal, color: c.protein),
        const SizedBox(height: 12),
        MacroBar(label: 'Carbs',   value: carbs,   goal: carbsGoal,   color: c.carbs),
        const SizedBox(height: 12),
        MacroBar(label: 'Fat',     value: fat,     goal: fatGoal,     color: c.fat),
      ],
    );
  }
}
