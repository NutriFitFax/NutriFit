import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/models.dart';
import '../features/history/viewed_food_history_store.dart';
import '../ui/food_view_data.dart';
import '../ui/app_page.dart';
import '../ui/macro_summary_card.dart';
import '../ui/status_views.dart';
import 'food_detail_screen.dart';

class MealScreen extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const MealScreen({
    super.key,
    required this.api,
    required this.history,
  });

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  final _picker = ImagePicker();
  MealEstimate? _estimate;
  bool _loading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _submit(bytes, file.name);
  }

  Future<void> _submit(Uint8List bytes, String name) async {
    setState(() {
      _loading = true;
      _error = null;
      _estimate = null;
    });
    try {
      final est = await widget.api.estimateMeal(bytes, filename: name);
      setState(() => _estimate = est);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Meal Estimator',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              InlineErrorText(message: _error!),
            if (_estimate != null)
              Expanded(
                child: SingleChildScrollView(
                  child: _EstimateCard(
                    estimate: _estimate!,
                    history: widget.history,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final MealEstimate estimate;
  final ViewedFoodHistoryStore history;

  const _EstimateCard({
    required this.estimate,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final est = estimate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MacroSummaryCard(
          title: 'Meal Estimate',
          subtitle: est.notes ?? 'Source: ${est.source}',
          trailing: Chip(label: Text(est.source)),
          macros: Macros(
            caloriesKcal: est.totalCaloriesKcal,
            proteinG: est.totalProteinG,
            carbsG: est.totalCarbsG,
            fatG: est.totalFatG,
          ),
        ),
        if (est.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Breakdown', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...est.items.map(
            (item) => Card(
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FoodDetailScreen(
                        food: FoodViewData.fromEstimatedFood(item),
                        history: history,
                        sourceLabel: 'meal',
                      ),
                    ),
                  );
                },
                title: Text(item.name),
                subtitle: Text(
                  '${item.estimatedGrams.toStringAsFixed(0)} g · confidence ${(item.confidence * 100).toStringAsFixed(0)}%',
                ),
                trailing: Text(
                  '${(item.macrosPer100g.caloriesKcal * item.estimatedGrams / 100).toStringAsFixed(0)} kcal',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
