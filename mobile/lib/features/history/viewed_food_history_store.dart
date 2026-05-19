import 'package:flutter/foundation.dart';

import '../../ui/food_view_data.dart';

class ViewedFoodEntry {
  final String id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final DateTime viewedAt;
  final FoodViewData food;
  final String sourceLabel;

  const ViewedFoodEntry({
    required this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.viewedAt,
    required this.food,
    required this.sourceLabel,
  });
}

abstract class ViewedFoodHistoryStore {
  ValueListenable<List<ViewedFoodEntry>> get entriesListenable;

  Future<void> addViewedFood(FoodViewData food, {required String sourceLabel});

  Future<void> clear();
}

class InMemoryViewedFoodHistoryStore implements ViewedFoodHistoryStore {
  final ValueNotifier<List<ViewedFoodEntry>> _entries =
      ValueNotifier<List<ViewedFoodEntry>>(<ViewedFoodEntry>[]);

  @override
  ValueListenable<List<ViewedFoodEntry>> get entriesListenable => _entries;

  @override
  Future<void> addViewedFood(
    FoodViewData food, {
    required String sourceLabel,
  }) async {
    final nextEntry = ViewedFoodEntry(
      id: food.id,
      name: food.name,
      brand: food.brand,
      imageUrl: food.imageUrl,
      viewedAt: DateTime.now(),
      food: food,
      sourceLabel: sourceLabel,
    );

    final nextItems = [
      nextEntry,
      ..._entries.value.where((entry) => entry.id != food.id),
    ];

    _entries.value = nextItems.take(20).toList(growable: false);
  }

  @override
  Future<void> clear() async {
    _entries.value = const <ViewedFoodEntry>[];
  }
}
