import 'package:flutter/foundation.dart';

enum Sex { male, female, other }
enum ActivityLevel { sedentary, light, moderate, veryActive, extraActive }

@immutable
class UserProfile {
  final String name;
  final String email;
  final double weightKg;
  final double heightCm;
  final Sex? sex;
  final ActivityLevel? activityLevel;

  const UserProfile({
    required this.name,
    required this.email,
    required this.weightKg,
    required this.heightCm,
    this.sex,
    this.activityLevel,
  });

  double get bmi {
    final hm = heightCm / 100;
    return weightKg / (hm * hm);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }
}

enum UnitSystem { metric, imperial }

class UnitConvert {
  static double kgToLb(double kg) => kg * 2.20462;
  static double lbToKg(double lb) => lb / 2.20462;

  static (int, int) cmToFeetInches(double cm) {
    final totalInches = (cm / 2.54).round();
    return (totalInches ~/ 12, totalInches % 12);
  }

  static double feetInchesToCm(int feet, int inches) =>
      (feet * 12 + inches) * 2.54;
}
