import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/db/daily_log.dart';

DailyLog _log({
  double goalCalories = 2000,
  double consumed = 0,
  double? latestWeightKg,
  double heightCm = 170,
}) =>
    DailyLog(
      goalCalories: goalCalories,
      goalProteinG: 130,
      goalCarbsG: 240,
      goalFatG: 70,
      goalWaterMl: 2000,
      consumedCalories: consumed,
      consumedProteinG: 0,
      consumedCarbsG: 0,
      consumedFatG: 0,
      consumedWaterMl: 0,
      meals: const [],
      latestWeightKg: latestWeightKg,
      heightCm: heightCm,
      weightTrend: const [],
    );

void main() {
  group('DailyLog.statusLabel', () {
    test('GET GOING when under 50%', () {
      expect(_log(consumed: 900).statusLabel, 'GET GOING');
    });

    test('ON TRACK between 50% and 95%', () {
      expect(_log(consumed: 1200).statusLabel, 'ON TRACK');
    });

    test('NEARLY FULL between 95% and 105%', () {
      expect(_log(consumed: 1950).statusLabel, 'NEARLY FULL');
    });

    test('OVER GOAL above 105%', () {
      expect(_log(consumed: 2200).statusLabel, 'OVER GOAL');
    });

    test('ON TRACK when goal is zero', () {
      expect(_log(goalCalories: 0, consumed: 0).statusLabel, 'ON TRACK');
    });

    test('GET GOING when consumed is zero', () {
      expect(_log(consumed: 0).statusLabel, 'GET GOING');
    });
  });

  group('DailyLog.bmi', () {
    test('calculates correctly when weight is set', () {
      final bmi = _log(latestWeightKg: 70.0, heightCm: 175.0).bmi;
      expect(bmi, isNotNull);
      expect(bmi!, closeTo(22.86, 0.01));
    });

    test('returns null when weight is null', () {
      expect(_log(latestWeightKg: null).bmi, isNull);
    });

    test('returns null when height is zero', () {
      expect(_log(latestWeightKg: 70.0, heightCm: 0.0).bmi, isNull);
    });
  });
}
