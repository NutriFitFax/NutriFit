import 'package:flutter/material.dart';

import '../app/haptics.dart';
import '../features/history/viewed_food_history_store.dart';
import '../ui/food_view_data.dart';
import '../ui/app_page.dart';
import '../ui/macro_summary_card.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodViewData food;
  final ViewedFoodHistoryStore history;
  final String sourceLabel;
  final Future<void> Function(double grams)? onLog;

  const FoodDetailScreen({
    super.key,
    required this.food,
    required this.history,
    required this.sourceLabel,
    this.onLog,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late double _grams = widget.food.servingSizeG ?? 100;
  bool _recorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recorded) return;
    _recorded = true;
    widget.history.addViewedFood(
      widget.food,
      sourceLabel: widget.sourceLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final macros = widget.food.macrosPer100g.forGrams(_grams);
    final sliderValue = _grams < 25
        ? 25.0
        : (_grams > 300 ? 300.0 : _grams);

    return AppPage(
      title: 'Food Details',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.food.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (widget.food.brand != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.food.brand!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Viewed from ${widget.sourceLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serving size',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${_grams.toStringAsFixed(0)} g'),
                  Slider(
                    min: 25,
                    max: 300,
                    divisions: 11,
                    value: sliderValue,
                    label: '${_grams.toStringAsFixed(0)} g',
                    onChanged: (value) => setState(() => _grams = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          MacroSummaryCard(
            title: widget.food.name,
            subtitle:
                'Nutrition for ${_grams.toStringAsFixed(0)} g${widget.food.servingSizeG == null ? '' : ' · default serving ${widget.food.servingSizeG!.toStringAsFixed(0)} g'}',
            macros: macros,
          ),
          if (widget.onLog != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                Haptics.lightImpact();
                await widget.onLog!(_grams);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.food.name} logged')),
                  );
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text('Log ${_grams.toStringAsFixed(0)} g to today'),
            ),
          ],
        ],
      ),
    );
  }
}
