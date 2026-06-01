import 'package:flutter/foundation.dart';

/// Lightweight on-device user profile collected during sign-up.
@immutable
class UserProfile {
  final String name;
  final String email;

  /// Canonical metric values — convert at the edges for display only.
  final double weightKg;
  final double heightCm;
  final Gender gender;
  final ActivityLevel activityLevel;

  /// Daily macro goals in grams.
  final int proteinGoalG;
  final int carbsGoalG;
  final int fatGoalG;

  final DateTime? dateOfBirth;

  const UserProfile({
    required this.name,
    required this.email,
    required this.weightKg,
    required this.heightCm,
    this.gender = Gender.other,
    this.activityLevel = ActivityLevel.medium,
    this.proteinGoalG = 130,
    this.carbsGoalG = 240,
    this.fatGoalG = 70,
    this.dateOfBirth,
  });

  double get bmi {
    final m = heightCm / 100.0;
    if (m <= 0) return 0;
    return weightKg / (m * m);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  /// Total daily calories implied by the macro goals (4/4/9 kcal per gram).
  int get macroCalories => proteinGoalG * 4 + carbsGoalG * 4 + fatGoalG * 9;

  UserProfile copyWith({
    String? name,
    String? email,
    double? weightKg,
    double? heightCm,
    Gender? gender,
    ActivityLevel? activityLevel,
    int? proteinGoalG,
    int? carbsGoalG,
    int? fatGoalG,
    DateTime? dateOfBirth,
  }) => UserProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    gender: gender ?? this.gender,
    activityLevel: activityLevel ?? this.activityLevel,
    proteinGoalG: proteinGoalG ?? this.proteinGoalG,
    carbsGoalG: carbsGoalG ?? this.carbsGoalG,
    fatGoalG: fatGoalG ?? this.fatGoalG,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'gender': gender.name,
    'activity_level': activityLevel.name,
    'protein_goal_g': proteinGoalG,
    'carbs_goal_g': carbsGoalG,
    'fat_goal_g': fatGoalG,
    if (dateOfBirth != null)
      'date_of_birth': '${dateOfBirth!.year.toString().padLeft(4,'0')}-${dateOfBirth!.month.toString().padLeft(2,'0')}-${dateOfBirth!.day.toString().padLeft(2,'0')}',
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 70,
    heightCm: (json['height_cm'] as num?)?.toDouble() ?? 170,
    gender: Gender.values.firstWhere(
      (g) => g.name == json['gender'],
      orElse: () => Gender.other,
    ),
    activityLevel: ActivityLevel.values.firstWhere(
      (a) => a.name == json['activity_level'],
      orElse: () => ActivityLevel.medium,
    ),
    proteinGoalG: (json['protein_goal_g'] as num?)?.toInt() ?? 130,
    carbsGoalG: (json['carbs_goal_g'] as num?)?.toInt() ?? 240,
    fatGoalG: (json['fat_goal_g'] as num?)?.toInt() ?? 70,
    dateOfBirth: json['date_of_birth'] != null
        ? DateTime.tryParse(json['date_of_birth'] as String)
        : null,
  );
}

/// Biological sex / gender option used for goal estimation.
enum Gender { male, female, other }

const Map<Gender, String> genderLabel = {
  Gender.male: 'Male',
  Gender.female: 'Female',
  Gender.other: 'Other',
};

/// Activity level (drives the activity multiplier in goal calculations).
enum ActivityLevel { sedentary, light, medium, active, veryActive }

const Map<ActivityLevel, String> activityLabel = {
  ActivityLevel.sedentary: 'Sedentary',
  ActivityLevel.light: 'Lightly Active',
  ActivityLevel.medium: 'Moderately Active',
  ActivityLevel.active: 'Very Active',
  ActivityLevel.veryActive: 'Extra Active',
};

const Map<ActivityLevel, String> activityDescription = {
  ActivityLevel.sedentary: 'Little or no exercise',
  ActivityLevel.light: 'Exercise 1–3 days/week',
  ActivityLevel.medium: 'Exercise 3–5 days/week',
  ActivityLevel.active: 'Exercise 6–7 days/week',
  ActivityLevel.veryActive: 'Hard exercise or a physical job',
};

/// Harris–Benedict style activity multipliers.
const Map<ActivityLevel, double> activityMultiplier = {
  ActivityLevel.sedentary: 1.2,
  ActivityLevel.light: 1.375,
  ActivityLevel.medium: 1.55,
  ActivityLevel.active: 1.725,
  ActivityLevel.veryActive: 1.9,
};

enum UnitSystem { metric, imperial }

class UnitConvert {
  static double kgToLb(double kg) => kg * 2.2046226218;
  static double lbToKg(double lb) => lb / 2.2046226218;

  static double cmToTotalInches(double cm) => cm / 2.54;

  static (int, int) cmToFeetInches(double cm) {
    final totalIn = cmToTotalInches(cm).round();
    return (totalIn ~/ 12, totalIn % 12);
  }

  static double feetInchesToCm(int feet, int inches) =>
      (feet * 12 + inches) * 2.54;
}
