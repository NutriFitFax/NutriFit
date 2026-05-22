/// Data models mirroring `nutrifit-backend/src/main/java/com/nutrifit/backend/model/`.
///
/// Keep these in lockstep with the Java response models. If a field is added on the
/// backend, add it here too; if a field is removed, mark it deprecated for
/// one release before deleting.
library;

class Macros {
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? saltG;

  const Macros({
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.sugarG,
    this.saltG,
  });

  factory Macros.fromJson(Map<String, dynamic> json) => Macros(
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        fiberG: (json['fiber_g'] as num?)?.toDouble(),
        sugarG: (json['sugar_g'] as num?)?.toDouble(),
        saltG: (json['salt_g'] as num?)?.toDouble(),
      );

  /// Scale macros from per-100g basis to a given gram amount.
  Macros forGrams(double grams) {
    final factor = grams / 100.0;
    return Macros(
      caloriesKcal: caloriesKcal * factor,
      proteinG: proteinG * factor,
      carbsG: carbsG * factor,
      fatG: fatG * factor,
      fiberG: fiberG == null ? null : fiberG! * factor,
      sugarG: sugarG == null ? null : sugarG! * factor,
      saltG: saltG == null ? null : saltG! * factor,
    );
  }
}

class Food {
  final String id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final double? servingSizeG;
  final Macros macrosPer100g;

  const Food({
    required this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    this.servingSizeG,
    required this.macrosPer100g,
  });

  factory Food.fromJson(Map<String, dynamic> json) => Food(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        imageUrl: json['image_url'] as String?,
        servingSizeG: (json['serving_size_g'] as num?)?.toDouble(),
        macrosPer100g:
            Macros.fromJson(json['macros_per_100g'] as Map<String, dynamic>),
      );
}

class SearchResult {
  final String query;
  final int page;
  final int pageSize;
  final int total;
  final List<Food> items;

  const SearchResult({
    required this.query,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        query: json['query'] as String,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
        total: json['total'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => Food.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class EstimatedFood {
  final String name;
  final double estimatedGrams;
  final double confidence;
  final Macros macrosPer100g;

  const EstimatedFood({
    required this.name,
    required this.estimatedGrams,
    required this.confidence,
    required this.macrosPer100g,
  });

  factory EstimatedFood.fromJson(Map<String, dynamic> json) => EstimatedFood(
        name: json['name'] as String,
        estimatedGrams: (json['estimated_grams'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        macrosPer100g:
            Macros.fromJson(json['macros_per_100g'] as Map<String, dynamic>),
      );
}

class MealEstimate {
  final List<EstimatedFood> items;
  final double totalCaloriesKcal;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final String source; // 'ai'
  final String? notes;

  const MealEstimate({
    required this.items,
    required this.totalCaloriesKcal,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.source,
    this.notes,
  });

  factory MealEstimate.fromJson(Map<String, dynamic> json) => MealEstimate(
        items: (json['items'] as List<dynamic>)
            .map((e) => EstimatedFood.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        totalCaloriesKcal: (json['total_calories_kcal'] as num).toDouble(),
        totalProteinG: (json['total_protein_g'] as num).toDouble(),
        totalCarbsG: (json['total_carbs_g'] as num).toDouble(),
        totalFatG: (json['total_fat_g'] as num).toDouble(),
        source: json['source'] as String,
        notes: json['notes'] as String?,
      );
}

class RecipeNutrients {
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const RecipeNutrients({
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory RecipeNutrients.fromJson(Map<String, dynamic> json) =>
      RecipeNutrients(
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
      );
}

class PlannedMeal {
  final String id;
  final String title;
  final String? imageUrl;
  final int? readyInMinutes;
  final int? servings;
  final String? sourceUrl;

  const PlannedMeal({
    required this.id,
    required this.title,
    this.imageUrl,
    this.readyInMinutes,
    this.servings,
    this.sourceUrl,
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
        id: json['id'] as String,
        title: json['title'] as String,
        imageUrl: json['image_url'] as String?,
        readyInMinutes: (json['ready_in_minutes'] as num?)?.toInt(),
        servings: (json['servings'] as num?)?.toInt(),
        sourceUrl: json['source_url'] as String?,
      );
}

class MealPlanResponse {
  final String timeFrame;
  final int? targetCalories;
  final String? diet;
  final List<PlannedMeal> meals;
  final RecipeNutrients nutrients;
  final String source;

  const MealPlanResponse({
    required this.timeFrame,
    this.targetCalories,
    this.diet,
    required this.meals,
    required this.nutrients,
    required this.source,
  });

  factory MealPlanResponse.fromJson(Map<String, dynamic> json) =>
      MealPlanResponse(
        timeFrame: json['time_frame'] as String,
        targetCalories: (json['target_calories'] as num?)?.toInt(),
        diet: json['diet'] as String?,
        meals: (json['meals'] as List<dynamic>)
            .map((e) => PlannedMeal.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        nutrients:
            RecipeNutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
        source: json['source'] as String,
      );
}

class RecipeDetails {
  final String id;
  final String title;
  final String? imageUrl;
  final int? readyInMinutes;
  final int? servings;
  final String? sourceUrl;
  final List<String> ingredients;
  final RecipeNutrients nutrients;

  const RecipeDetails({
    required this.id,
    required this.title,
    this.imageUrl,
    this.readyInMinutes,
    this.servings,
    this.sourceUrl,
    required this.ingredients,
    required this.nutrients,
  });

  factory RecipeDetails.fromJson(Map<String, dynamic> json) => RecipeDetails(
        id: json['id'] as String,
        title: json['title'] as String,
        imageUrl: json['image_url'] as String?,
        readyInMinutes: (json['ready_in_minutes'] as num?)?.toInt(),
        servings: (json['servings'] as num?)?.toInt(),
        sourceUrl: json['source_url'] as String?,
        ingredients: (json['ingredients'] as List<dynamic>)
            .map((e) => e as String)
            .toList(growable: false),
        nutrients:
            RecipeNutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
      );
}
