import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/models.dart';
import '../features/history/viewed_food_history_store.dart';
import '../ui/food_view_data.dart';
import '../ui/app_page.dart';
import '../ui/macro_summary_card.dart';
import '../ui/status_views.dart';
import 'food_detail_screen.dart';

class BarcodeScreen extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const BarcodeScreen({
    super.key,
    required this.api,
    required this.history,
  });

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
    return AppPage(
      title: 'Barcode Lookup',
      child: Padding(
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
                  child: const Text('Look Up'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) InlineErrorText(message: _error!),
            if (_food != null)
              _FoodCard(
                food: _food!,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FoodDetailScreen(
                        food: FoodViewData.fromFood(_food!),
                        history: widget.history,
                        sourceLabel: 'Barcode',
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const _FoodCard({
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: MacroSummaryCard(
        title: food.name,
        subtitle: food.brand == null
            ? 'Tap to open details'
            : '${food.brand!} · tap to open details',
        macros: food.macrosPer100g,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
