import 'package:flutter/material.dart';

import '../../../app/nutri_colors.dart';

class ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const ConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final high = confidence >= 0.85;
    final mid  = confidence >= 0.7;
    final (bg, fg, label) = high
        ? (c.primarySoft, c.primaryDeep, 'High confidence')
        : mid
            ? (c.carbsSoft, const Color(0xFF7A5A1C), 'Estimate')
            : (c.proteinSoft, c.protein, 'Low confidence');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label · ${(confidence * 100).round()}%',
            style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
