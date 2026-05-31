import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../app/settings_prefs.dart';
import 'daily_log.dart';
import 'nutrifit_database.dart';

class SqliteDailyLogStore implements DailyLogStore {
  final Database _db;
  late final ValueNotifier<DailyLog> _notifier;

  SqliteDailyLogStore._(this._db) {
    _notifier = ValueNotifier(_emptyLog());
  }

  static Future<SqliteDailyLogStore> open() async {
    final db = await NutrifitDatabase.open();
    final store = SqliteDailyLogStore._(db);
    await store._refresh();
    return store;
  }

  @override
  ValueListenable<DailyLog> get todayListenable => _notifier;

  @override
  Future<void> logMeal({
    required String name,
    required double caloriesKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final now = DateTime.now();
    await _db.insert('meal_logs', {
      'date':      _dateKey(now),
      'logged_at': now.millisecondsSinceEpoch,
      'name':      name,
      'calories':  caloriesKcal,
      'protein_g': proteinG,
      'carbs_g':   carbsG,
      'fat_g':     fatG,
    });
    await _refresh();
  }

  @override
  Future<void> deleteMeal(int id) async {
    await _db.delete('meal_logs', where: 'id = ?', whereArgs: [id]);
    await _refresh();
  }

  @override
  Future<void> logWater(int amountMl) async {
    final now = DateTime.now();
    await _db.insert('water_logs', {
      'date':      _dateKey(now),
      'logged_at': now.millisecondsSinceEpoch,
      'amount_ml': amountMl,
    });
    await _refresh();
  }

  @override
  Future<void> logWeight(double weightKg) async {
    final now = DateTime.now();
    await _db.insert('weight_logs', {
      'logged_at': now.millisecondsSinceEpoch,
      'weight_kg': weightKg,
    });
    await _refresh();
  }

  @override
  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    final today = _dateKey(DateTime.now());
    final prefs = SettingsPrefs.instance;

    final mealRows = await _db.query(
      'meal_logs',
      where: 'date = ?',
      whereArgs: [today],
      orderBy: 'logged_at ASC',
    );

    final waterRows = await _db.query(
      'water_logs',
      where: 'date = ?',
      whereArgs: [today],
    );

    // Last 8 weight entries, newest first, then reversed for the sparkline.
    final weightRows = await _db.query(
      'weight_logs',
      orderBy: 'logged_at DESC',
      limit: 8,
    );

    final meals = mealRows.map((r) {
      final at = DateTime.fromMillisecondsSinceEpoch(r['logged_at'] as int);
      return LoggedMeal(
        id:       r['id'] as int,
        time:     '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
        name:     r['name'] as String,
        kcal:     (r['calories'] as num).round(),
        proteinG: (r['protein_g'] as num).toDouble(),
        carbsG:   (r['carbs_g'] as num).toDouble(),
        fatG:     (r['fat_g'] as num).toDouble(),
      );
    }).toList();

    final consumedWaterMl = waterRows.fold<int>(
      0, (s, r) => s + (r['amount_ml'] as int),
    );

    final weightTrend = weightRows.reversed
        .map((r) => (r['weight_kg'] as num).toDouble())
        .toList();

    final latestWeightKg =
        weightRows.isEmpty ? null : (weightRows.first['weight_kg'] as num).toDouble();

    _notifier.value = DailyLog(
      goalCalories: prefs.goalCaloriesKcal.toDouble(),
      goalProteinG: prefs.goalProteinG.toDouble(),
      goalCarbsG:   prefs.goalCarbsG.toDouble(),
      goalFatG:     prefs.goalFatG.toDouble(),
      goalWaterMl:  prefs.waterGoalMl,
      consumedCalories: meals.fold(0.0, (s, m) => s + m.kcal),
      consumedProteinG: meals.fold(0.0, (s, m) => s + m.proteinG),
      consumedCarbsG:   meals.fold(0.0, (s, m) => s + m.carbsG),
      consumedFatG:     meals.fold(0.0, (s, m) => s + m.fatG),
      consumedWaterMl:  consumedWaterMl,
      meals:          meals,
      latestWeightKg: latestWeightKg,
      heightCm:       prefs.heightCm,
      weightTrend:    weightTrend,
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DailyLog _emptyLog() {
    final prefs = SettingsPrefs.instance;
    return DailyLog(
      goalCalories: prefs.goalCaloriesKcal.toDouble(),
      goalProteinG: prefs.goalProteinG.toDouble(),
      goalCarbsG:   prefs.goalCarbsG.toDouble(),
      goalFatG:     prefs.goalFatG.toDouble(),
      goalWaterMl:  prefs.waterGoalMl,
      consumedCalories: 0,
      consumedProteinG: 0,
      consumedCarbsG:   0,
      consumedFatG:     0,
      consumedWaterMl:  0,
      meals:          const [],
      latestWeightKg: null,
      heightCm:       prefs.heightCm,
      weightTrend:    const [],
    );
  }
}
