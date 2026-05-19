import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/models.dart';

class BarcodeResultSheet extends StatefulWidget {
  final String barcode;
  final NutriFitApi api;
  final VoidCallback onScanAgain;

  const BarcodeResultSheet({
    super.key,
    required this.barcode,
    required this.api,
    required this.onScanAgain,
  });

  @override
  State<BarcodeResultSheet> createState() => _BarcodeResultSheetState();
}

class _BarcodeResultSheetState extends State<BarcodeResultSheet> {
  Food? _food;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    setState(() {
      _food = null;
      _error = null;
    });
    try {
      final food = await widget.api.getByBarcode(widget.barcode);
      if (mounted) setState(() => _food = food);
    } on NotFoundException {
      if (mounted) {
        setState(() => _error =
            'Product not found. Try scanning again or search by name.');
      }
    } on NetworkException {
      if (mounted) {
        setState(
            () => _error = 'No internet connection. Reconnect and tap to retry.');
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'Taking longer than usual. Tap to retry.');
      }
    } on UpstreamException {
      if (mounted) {
        setState(() => _error = 'Service is having trouble. Tap to retry.');
      }
    } on ApiException {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Tap to retry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_food == null && _error == null) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Center(child: Text('Looking up product…')),
          ] else if (_error != null) ...[
            _ErrorView(
              message: _error!,
              onRetry: _lookup,
              onScanAgain: () {
                Navigator.of(context).pop();
                widget.onScanAgain();
              },
            ),
          ] else ...[
            _FoodResult(food: _food!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                // TODO: hand off to Ahmed's food detail screen
                // Navigator.of(context).pushNamed('/food-detail', arguments: _food);
                Navigator.of(context).pop();
              },
              child: const Text('View full nutrition'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onScanAgain();
              },
              child: const Text('Scan another'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FoodResult extends StatelessWidget {
  final Food food;
  const _FoodResult({required this.food});

  @override
  Widget build(BuildContext context) {
    final m = food.macrosPer100g;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(food.name, style: Theme.of(context).textTheme.titleLarge),
        if (food.brand != null)
          Text(food.brand!,
              style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        _MacroRow('Calories', '${m.caloriesKcal.toStringAsFixed(0)} kcal'),
        _MacroRow('Protein', '${m.proteinG.toStringAsFixed(1)} g'),
        _MacroRow('Carbs', '${m.carbsG.toStringAsFixed(1)} g'),
        _MacroRow('Fat', '${m.fatG.toStringAsFixed(1)} g'),
        if (m.fiberG != null)
          _MacroRow('Fiber', '${m.fiberG!.toStringAsFixed(1)} g'),
        Align(
          alignment: Alignment.centerRight,
          child: Text('per 100 g',
              style: Theme.of(context).textTheme.labelSmall),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  const _MacroRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onScanAgain;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline,
            size: 40, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
        OutlinedButton(
            onPressed: onScanAgain, child: const Text('Scan again')),
      ],
    );
  }
}
