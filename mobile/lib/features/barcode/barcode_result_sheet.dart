import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/models.dart';
import '../../app/haptics.dart';
import '../../app/nutri_colors.dart';
import '../../features/history/viewed_food_history_store.dart';
import '../../screens/food_detail_screen.dart';
import '../../ui/food_view_data.dart';

class BarcodeResultSheet extends StatefulWidget {
  final String barcode;
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;
  final VoidCallback onScanAgain;
  final VoidCallback? onEnterManually;

  const BarcodeResultSheet({
    super.key,
    required this.barcode,
    required this.api,
    required this.history,
    required this.onScanAgain,
    this.onEnterManually,
  });

  @override
  State<BarcodeResultSheet> createState() => _BarcodeResultSheetState();
}

class _BarcodeResultSheetState extends State<BarcodeResultSheet> {
  Food? _food;
  String? _error;
  bool _isNotFound = false;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    setState(() { _food = null; _error = null; _isNotFound = false; });
    try {
      final food = await widget.api.getByBarcode(widget.barcode);
      if (mounted) setState(() => _food = food);
    } on NotFoundException {
      if (mounted) setState(() { _error = 'Product not found. Try scanning again or search by name.'; _isNotFound = true; });
    } on NetworkException {
      if (mounted) setState(() => _error = 'No internet connection or server unreachable. Tap to retry.');
    } on TimeoutException {
      if (mounted) setState(() => _error = 'Taking longer than usual. Tap to retry.');
    } on UpstreamException {
      if (mounted) setState(() => _error = 'Service is having trouble. Tap to retry.');
    } on ApiException {
      if (mounted) setState(() => _error = 'Something went wrong. Tap to retry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22, 6, 22, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          if (_food == null && _error == null)
            _LoadingView()
          else if (_error != null)
            _ErrorView(
              message: _error!,
              onRetry: _lookup,
              onScanAgain: () { Navigator.of(context).pop(); widget.onScanAgain(); },
              onEnterManually: _isNotFound && widget.onEnterManually != null
                  ? () { Navigator.of(context).pop(); widget.onEnterManually!(); }
                  : null,
            )
          else
            _FoodResult(food: _food!, barcode: widget.barcode),
          if (_food != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Haptics.selectionClick();
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FoodDetailScreen(
                            food: FoodViewData.fromFood(_food!),
                            history: widget.history,
                            sourceLabel: 'Barcode scan',
                          ),
                        ),
                      );
                    },
                    child: const Text('View details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      Haptics.lightImpact();
                      // TODO(Davud): persist to daily log.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${_food!.name} logged')),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Log to today'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          if (_food != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(TextSpan(
                    children: [
                      TextSpan(text: 'Barcode ', style: TextStyle(color: c.ink2, fontSize: 12)),
                      TextSpan(
                        text: widget.barcode,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  )),
                  Text('Per 100 g serving', style: TextStyle(fontSize: 12, color: c.ink2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
          ),
          const SizedBox(height: 14),
          Text('Looking up product…', style: TextStyle(color: c.ink2, fontSize: 13.5)),
        ],
      ),
    );
  }
}

class _FoodResult extends StatelessWidget {
  final Food food;
  final String barcode;
  const _FoodResult({required this.food, required this.barcode});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final m = food.macrosPer100g;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: c.fatSoft, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Text(
                'F',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: c.fat, fontSize: 22, fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, height: 1.15),
                  ),
                  if (food.brand != null) ...[
                    const SizedBox(height: 2),
                    Text(food.brand!, style: TextStyle(fontSize: 12, color: c.ink2)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'MATCHED',
                style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: c.primaryDeep, letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _MacroPill(label: 'Calories', value: m.caloriesKcal.toStringAsFixed(0), color: c.ink)),
            const SizedBox(width: 8),
            Expanded(child: _MacroPill(label: 'Protein',  value: m.proteinG.toStringAsFixed(0), color: c.protein)),
            const SizedBox(width: 8),
            Expanded(child: _MacroPill(label: 'Carbs',    value: m.carbsG.toStringAsFixed(0),   color: c.carbs)),
            const SizedBox(width: 8),
            Expanded(child: _MacroPill(label: 'Fat',      value: m.fatG.toStringAsFixed(0),     color: c.fat)),
          ],
        ),
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text('$label / 100g', style: TextStyle(fontSize: 10, color: c.ink2)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onScanAgain;
  final VoidCallback? onEnterManually;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onScanAgain,
    this.onEnterManually,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 40, color: c.warn),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: () { Haptics.selectionClick(); onRetry(); }, child: const Text('Retry')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () { Haptics.selectionClick(); onScanAgain(); }, child: const Text('Scan again')),
        if (onEnterManually != null)
          TextButton(onPressed: () { Haptics.selectionClick(); onEnterManually!(); }, child: const Text('Search by name')),
      ],
    );
  }
}
