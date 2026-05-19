import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/models.dart';

class MealScreen extends StatefulWidget {
  final NutriFitApi api;
  const MealScreen({super.key, required this.api});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Estimator')),
      body: Padding(
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
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_estimate != null) _EstimateCard(estimate: _estimate!),
          ],
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final MealEstimate estimate;
  const _EstimateCard({required this.estimate});

  @override
  Widget build(BuildContext context) {
    final est = estimate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Meal Estimate', style: Theme.of(context).textTheme.titleLarge),
                Chip(label: Text(est.source)),
              ],
            ),
            const Divider(height: 24),
            _Row('Calories', '${est.totalCaloriesKcal.toStringAsFixed(0)} kcal'),
            _Row('Protein', '${est.totalProteinG.toStringAsFixed(1)} g'),
            _Row('Carbs', '${est.totalCarbsG.toStringAsFixed(1)} g'),
            _Row('Fat', '${est.totalFatG.toStringAsFixed(1)} g'),
            if (est.notes != null) ...[
              const SizedBox(height: 8),
              Text(est.notes!, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (est.items.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Breakdown', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...est.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.name} (${item.estimatedGrams.toStringAsFixed(0)}g)'),
                      Text(
                        '${(item.macrosPer100g.caloriesKcal * item.estimatedGrams / 100).toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
