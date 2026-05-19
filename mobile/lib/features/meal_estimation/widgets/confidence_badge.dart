import 'package:flutter/material.dart';

class ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const ConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final high = confidence >= 0.75;
    final color = high
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;
    final textColor = high
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        high ? 'High confidence' : 'Estimate',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
