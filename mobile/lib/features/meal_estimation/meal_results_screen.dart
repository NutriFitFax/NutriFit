import 'package:flutter/material.dart';

import '../../api/models.dart';
import 'widgets/food_item_card.dart';
import 'widgets/meal_totals_footer.dart';

class MealResultsScreen extends StatelessWidget {
  final MealEstimate estimate;

  const MealResultsScreen({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    if (estimate.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meal analysis')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_food_outlined, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'No food detected. Try a clearer, well-lit photo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meal analysis')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: estimate.items.length,
              itemBuilder: (context, i) {
                final item = estimate.items[i];
                return FoodItemCard(
                  item: item,
                  onTap: () {
                    // TODO: navigate to Ahmed's food detail screen
                    // Navigator.of(context).pushNamed('/food-detail', arguments: item);
                  },
                );
              },
            ),
          ),
          MealTotalsFooter(estimate: estimate),
        ],
      ),
    );
  }
}
