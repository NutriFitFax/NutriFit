import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/models.dart';
import '../features/history/viewed_food_history_store.dart';
import '../ui/food_view_data.dart';
import '../ui/app_page.dart';
import '../ui/food_list_tile.dart';
import '../ui/status_views.dart';
import 'food_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const SearchScreen({
    super.key,
    required this.api,
    required this.history,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Food> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.search(q);
      setState(() => _results = result.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Food Search',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Search Food…',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: const Text('Go'),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: InlineErrorText(message: _error!),
            ),
          Expanded(
            child: _results.isEmpty
                ? const CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyStateView(
                          icon: Icons.search,
                          title: 'No foods yet',
                          message: 'Run a search to view matching foods here.',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final food = _results[i];
                      return FoodListTile(
                        title: food.name,
                        brand: food.brand,
                        macros: food.macrosPer100g,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FoodDetailScreen(
                                food: FoodViewData.fromFood(food),
                                history: widget.history,
                                sourceLabel: 'Search',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
