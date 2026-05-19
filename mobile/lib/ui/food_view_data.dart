import '../api/models.dart';
import '../features/history/viewed_food_history_store.dart';

class FoodViewData {
  final String id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final double? servingSizeG;
  final Macros macrosPer100g;

  const FoodViewData({
    required this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    this.servingSizeG,
    required this.macrosPer100g,
  });

  factory FoodViewData.fromFood(Food food) => FoodViewData(
        id: food.id,
        name: food.name,
        brand: food.brand,
        imageUrl: food.imageUrl,
        servingSizeG: food.servingSizeG,
        macrosPer100g: food.macrosPer100g,
      );

  factory FoodViewData.fromEstimatedFood(EstimatedFood food) => FoodViewData(
        id: 'estimated:${food.name.toLowerCase()}',
        name: food.name,
        servingSizeG: food.estimatedGrams,
        macrosPer100g: food.macrosPer100g,
      );

  factory FoodViewData.fromHistoryEntry(ViewedFoodEntry entry) => entry.food;
}
