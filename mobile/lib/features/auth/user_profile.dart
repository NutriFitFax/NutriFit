import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String name;
  final String email;
  final double weightKg;
  final double heightCm;

  const UserProfile({
    required this.name,
    required this.email,
    required this.weightKg,
    required this.heightCm,
  });

  double get bmi {
    final hm = heightCm / 100;
    return weightKg / (hm * hm);
  }
}

enum UnitSystem { metric, imperial }

class UnitConvert {
  static double kgToLb(double kg) => kg * 2.20462;

  static (int, int) cmToFeetInches(double cm) {
    final totalInches = (cm / 2.54).round();
    return (totalInches ~/ 12, totalInches % 12);
  }
}
