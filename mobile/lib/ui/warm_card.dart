import 'package:flutter/material.dart';

import '../app/haptics.dart';
import '../app/nutri_colors.dart';

/// A warm, cream-surface card with a soft border. Tap-aware (ripple) when
/// [onTap] is provided. Use [padded] = false to lay out custom child padding.
class WarmCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool elevated;

  const WarmCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.elevated = false,
  });

  const WarmCard.flat({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 24,
    this.elevated = false,
  }) : padding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final radii = BorderRadius.circular(radius);
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: radii,
          border: Border.all(color: c.line),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: c.ink.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap == null ? null : () { Haptics.selectionClick(); onTap!(); },
          borderRadius: radii,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
