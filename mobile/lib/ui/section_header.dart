import 'package:flutter/material.dart';

import '../app/nutri_colors.dart';

/// A small all-caps label used inside cards (e.g. "TODAY'S ENERGY", "WATER").
class NutriOverline extends StatelessWidget {
  final String label;
  final Color? color;
  const NutriOverline(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color ?? context.nutri.ink2,
      ),
    );
  }
}

/// Section header used between cards: a left-aligned serif headline and an
/// optional right-aligned trailing widget (e.g. "See all →").
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(4, 6, 4, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "See all →" link used as a [SectionHeader] trailing.
class SeeAllLink extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const SeeAllLink({super.key, required this.onTap, this.label = 'See all'});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: c.primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.primary),
          ],
        ),
      ),
    );
  }
}
