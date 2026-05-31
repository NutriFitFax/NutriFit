import 'package:flutter/foundation.dart';

class LoggedMeal {
  final int id;
  final String time; // "HH:mm"
  final String name;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const LoggedMeal({
    required this.id,
    required this.time,
    required this.name,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class DailyLog {
  final double goalCalories;
  final double goalProteinG;
  final double goalCarbsG;
  final double goalFatG;
  final int goalWaterMl;

  final double consumedCalories;
  final double consumedProteinG;
  final double consumedCarbsG;
  final double consumedFatG;
  final int consumedWaterMl;

  final List<LoggedMeal> meals;

  final double? latestWeightKg;
  final double heightCm;
  final List<double> weightTrend; // chronological, up to 8 entries

  const DailyLog({
    required this.goalCalories,
    required this.goalProteinG,
    required this.goalCarbsG,
    required this.goalFatG,
    required this.goalWaterMl,
    required this.consumedCalories,
    required this.consumedProteinG,
    required this.consumedCarbsG,
    required this.consumedFatG,
    required this.consumedWaterMl,
    required this.meals,
    required this.latestWeightKg,
    required this.heightCm,
    required this.weightTrend,
  });

  double? get bmi {
    if (latestWeightKg == null || heightCm <= 0) return null;
    final h = heightCm / 100;
    return latestWeightKg! / (h * h);
  }

  String get statusLabel {
    if (goalCalories <= 0) return 'ON TRACK';
    final ratio = consumedCalories / goalCalories;
    if (ratio < 0.5) return 'GET GOING';
    if (ratio < 0.95) return 'ON TRACK';
    if (ratio < 1.05) return 'NEARLY FULL';
    return 'OVER GOAL';
  }
}

abstract class DailyLogStore {
  ValueListenable<DailyLog> get todayListenable;

  Future<void> logMeal({
    required String name,
    required double caloriesKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  });

  Future<void> deleteMeal(int id);
  Future<void> logWater(int amountMl);
  Future<void> logWeight(double weightKg);

  /// Re-reads goals from SettingsPrefs and re-queries the DB.
  Future<void> refresh();

  /// Deletes today's water entries so the intake counter resets to 0.
  Future<void> resetTodayWater();

  /// Wipes all local logs (used on account deletion).
  Future<void> clearAllData();
}
