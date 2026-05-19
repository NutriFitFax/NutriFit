import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/models.dart';

class BarcodeScreen extends StatefulWidget {
  final NutriFitApi api;
  const BarcodeScreen({super.key, required this.api});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final _controller = TextEditingController();
  Food? _food;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final barcode = _controller.text.trim();
    if (barcode.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _food = null;
    });
    try {
      final food = await widget.api.getByBarcode(barcode);
      setState(() => _food = food);
    } on NotFoundException {
      setState(() => _error = 'No product found for that barcode.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Lookup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter barcode (EAN / UPC)…',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _lookup,
                  child: const Text('Look up'),
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
            if (_food != null) _FoodCard(food: _food!),
          ],
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Food food;
  const _FoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final m = food.macrosPer100g;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(food.name, style: Theme.of(context).textTheme.titleLarge),
            if (food.brand != null)
              Text(food.brand!, style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 24),
            _Row('Calories', '${m.caloriesKcal.toStringAsFixed(0)} kcal'),
            _Row('Protein', '${m.proteinG.toStringAsFixed(1)} g'),
            _Row('Carbs', '${m.carbsG.toStringAsFixed(1)} g'),
            _Row('Fat', '${m.fatG.toStringAsFixed(1)} g'),
            if (m.fiberG != null) _Row('Fiber', '${m.fiberG!.toStringAsFixed(1)} g'),
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
