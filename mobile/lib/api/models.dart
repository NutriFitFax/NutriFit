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

String? _dateTimeToJson(DateTime? value) => value?.toUtc().toIso8601String();

DateTime? _dateTimeFromJson(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

class StoredUserProfile {
  final String? userId;
  final String? displayName;
  final double? heightCm;
  final double? goalCaloriesKcal;
  final double? goalProteinG;
  final double? goalCarbsG;
  final double? goalFatG;
  final DateTime? updatedAt;

  const StoredUserProfile({
    this.userId,
    this.displayName,
    this.heightCm,
    this.goalCaloriesKcal,
    this.goalProteinG,
    this.goalCarbsG,
    this.goalFatG,
    this.updatedAt,
  });

  factory StoredUserProfile.fromJson(Map<String, dynamic> json) =>
      StoredUserProfile(
        userId: json['user_id'] as String?,
        displayName: json['display_name'] as String?,
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        goalCaloriesKcal: (json['goal_calories_kcal'] as num?)?.toDouble(),
        goalProteinG: (json['goal_protein_g'] as num?)?.toDouble(),
        goalCarbsG: (json['goal_carbs_g'] as num?)?.toDouble(),
        goalFatG: (json['goal_fat_g'] as num?)?.toDouble(),
        updatedAt: _dateTimeFromJson(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        if (displayName != null) 'display_name': displayName,
        if (heightCm != null) 'height_cm': heightCm,
        if (goalCaloriesKcal != null) 'goal_calories_kcal': goalCaloriesKcal,
        if (goalProteinG != null) 'goal_protein_g': goalProteinG,
        if (goalCarbsG != null) 'goal_carbs_g': goalCarbsG,
        if (goalFatG != null) 'goal_fat_g': goalFatG,
      };
}

class MealLogEntry {
  final String? id;
  final String? userId;
  final DateTime? loggedAt;
  final String name;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? source;

  const MealLogEntry({
    this.id,
    this.userId,
    this.loggedAt,
    required this.name,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.source,
  });

  factory MealLogEntry.fromJson(Map<String, dynamic> json) => MealLogEntry(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        loggedAt: _dateTimeFromJson(json['logged_at']),
        name: json['name'] as String,
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        source: json['source'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (loggedAt != null) 'logged_at': _dateTimeToJson(loggedAt),
        'name': name,
        'calories_kcal': caloriesKcal,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        if (source != null) 'source': source,
      };
}

class WaterLogEntry {
  final String? id;
  final String? userId;
  final DateTime? loggedAt;
  final int amountMl;

  const WaterLogEntry({
    this.id,
    this.userId,
    this.loggedAt,
    required this.amountMl,
  });

  factory WaterLogEntry.fromJson(Map<String, dynamic> json) => WaterLogEntry(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        loggedAt: _dateTimeFromJson(json['logged_at']),
        amountMl: json['amount_ml'] as int,
      );

  Map<String, dynamic> toJson() => {
        if (loggedAt != null) 'logged_at': _dateTimeToJson(loggedAt),
        'amount_ml': amountMl,
      };
}

class WeightLogEntry {
  final String? id;
  final String? userId;
  final DateTime? loggedAt;
  final double weightKg;

  const WeightLogEntry({
    this.id,
    this.userId,
    this.loggedAt,
    required this.weightKg,
  });

  factory WeightLogEntry.fromJson(Map<String, dynamic> json) => WeightLogEntry(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        loggedAt: _dateTimeFromJson(json['logged_at']),
        weightKg: (json['weight_kg'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (loggedAt != null) 'logged_at': _dateTimeToJson(loggedAt),
        'weight_kg': weightKg,
      };
}

class ActivityLogEntry {
  final String? id;
  final String? userId;
  final DateTime? loggedAt;
  final String name;
  final double met;
  final double durationMinutes;
  final double caloriesBurnedKcal;

  const ActivityLogEntry({
    this.id,
    this.userId,
    this.loggedAt,
    required this.name,
    required this.met,
    required this.durationMinutes,
    required this.caloriesBurnedKcal,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) =>
      ActivityLogEntry(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        loggedAt: _dateTimeFromJson(json['logged_at']),
        name: json['name'] as String,
        met: (json['met'] as num).toDouble(),
        durationMinutes: (json['duration_minutes'] as num).toDouble(),
        caloriesBurnedKcal:
            (json['calories_burned_kcal'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (loggedAt != null) 'logged_at': _dateTimeToJson(loggedAt),
        'name': name,
        'met': met,
        'duration_minutes': durationMinutes,
        'calories_burned_kcal': caloriesBurnedKcal,
      };
}

class DailyTotals {
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int waterMl;
  final double activityCaloriesKcal;

  const DailyTotals({
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
    required this.activityCaloriesKcal,
  });

  factory DailyTotals.fromJson(Map<String, dynamic> json) => DailyTotals(
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        waterMl: json['water_ml'] as int,
        activityCaloriesKcal:
            (json['activity_calories_kcal'] as num).toDouble(),
      );
}

class DailyStorageSummary {
  final String userId;
  final String date;
  final StoredUserProfile? profile;
  final DailyTotals totals;
  final List<MealLogEntry> meals;
  final List<WaterLogEntry> waterLogs;
  final List<WeightLogEntry> weightLogs;
  final List<ActivityLogEntry> activityLogs;

  const DailyStorageSummary({
    required this.userId,
    required this.date,
    this.profile,
    required this.totals,
    required this.meals,
    required this.waterLogs,
    required this.weightLogs,
    required this.activityLogs,
  });

  factory DailyStorageSummary.fromJson(Map<String, dynamic> json) =>
      DailyStorageSummary(
        userId: json['user_id'] as String,
        date: json['date'] as String,
        profile: json['profile'] == null
            ? null
            : StoredUserProfile.fromJson(
                json['profile'] as Map<String, dynamic>,
              ),
        totals: DailyTotals.fromJson(json['totals'] as Map<String, dynamic>),
        meals: (json['meals'] as List<dynamic>)
            .map((e) => MealLogEntry.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        waterLogs: (json['water_logs'] as List<dynamic>)
            .map((e) => WaterLogEntry.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        weightLogs: (json['weight_logs'] as List<dynamic>)
            .map((e) => WeightLogEntry.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        activityLogs: (json['activity_logs'] as List<dynamic>)
            .map((e) => ActivityLogEntry.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}
