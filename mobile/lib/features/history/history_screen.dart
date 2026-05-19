import 'package:flutter/material.dart';

import '../../ui/app_page.dart';
import '../../ui/food_list_tile.dart';
import '../../ui/status_views.dart';
import '../../screens/food_detail_screen.dart';
import 'viewed_food_history_store.dart';

class HistoryScreen extends StatelessWidget {
  final ViewedFoodHistoryStore history;

  const HistoryScreen({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'History',
      actions: [
        IconButton(
          onPressed: () => history.clear(),
          tooltip: 'Clear history',
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      child: ValueListenableBuilder<List<ViewedFoodEntry>>(
        valueListenable: history.entriesListenable,
        builder: (context, entries, _) {
          if (entries.isEmpty) {
            return const EmptyStateView(
              icon: Icons.history,
              title: 'No viewed foods yet',
              message: 'Open food details from search, barcode, or meal results to build your recent history.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return FoodListTile(
                title: entry.name,
                brand: entry.brand,
                macros: entry.food.macrosPer100g,
                trailingText: entry.sourceLabel,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FoodDetailScreen(
                        food: entry.food,
                        history: history,
                        sourceLabel: 'history',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
