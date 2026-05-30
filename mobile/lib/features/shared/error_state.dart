import 'package:flutter/material.dart';

import '../../app/haptics.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.buttonLabel = 'Retry',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () { Haptics.selectionClick(); onRetry(); }, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
