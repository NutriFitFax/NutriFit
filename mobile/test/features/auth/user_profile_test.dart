import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/features/auth/user_profile.dart';

void main() {
  group('UserProfile.bmi', () {
    test('calculates correctly', () {
      final profile = UserProfile(
        name: 'Alice',
        email: 'alice@example.com',
        weightKg: 70.0,
        heightCm: 175.0,
      );
      expect(profile.bmi, closeTo(22.86, 0.01));
    });

    test('returns 0 when height is zero', () {
      final profile = UserProfile(
        name: 'Alice',
        email: 'alice@example.com',
        weightKg: 70.0,
        heightCm: 0.0,
      );
      expect(profile.bmi, 0.0);
    });
  });

  group('UserProfile.bmiCategory', () {
    test('underweight below 18.5', () {
      final p = UserProfile(name: 'A', email: 'a@a.com', weightKg: 45.0, heightCm: 170.0);
      expect(p.bmiCategory, 'Underweight'); // bmi ≈ 15.6
    });

    test('normal between 18.5 and 25', () {
      final p = UserProfile(name: 'A', email: 'a@a.com', weightKg: 65.0, heightCm: 175.0);
      expect(p.bmiCategory, 'Normal'); // bmi ≈ 21.2
    });

    test('overweight between 25 and 30', () {
      final p = UserProfile(name: 'A', email: 'a@a.com', weightKg: 85.0, heightCm: 175.0);
      expect(p.bmiCategory, 'Overweight'); // bmi ≈ 27.8
    });

    test('obese at 30 and above', () {
      final p = UserProfile(name: 'A', email: 'a@a.com', weightKg: 100.0, heightCm: 170.0);
      expect(p.bmiCategory, 'Obese'); // bmi ≈ 34.6
    });
  });

  group('UserProfile.macroCalories', () {
    test('calculates protein*4 + carbs*4 + fat*9', () {
      final p = UserProfile(
        name: 'A', email: 'a@a.com', weightKg: 70.0, heightCm: 170.0,
        proteinGoalG: 130, carbsGoalG: 240, fatGoalG: 70,
      );
      expect(p.macroCalories, 130 * 4 + 240 * 4 + 70 * 9); // 520+960+630 = 2110
    });
  });

  group('UserProfile.toJson / fromJson', () {
    test('round-trip preserves all fields', () {
      final original = UserProfile(
        name: 'Bob',
        email: 'bob@example.com',
        weightKg: 80.0,
        heightCm: 180.0,
        gender: Gender.male,
        activityLevel: ActivityLevel.active,
        proteinGoalG: 150,
        carbsGoalG: 300,
        fatGoalG: 80,
        dateOfBirth: DateTime(1990, 6, 15),
      );

      final restored = UserProfile.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.weightKg, original.weightKg);
      expect(restored.heightCm, original.heightCm);
      expect(restored.gender, original.gender);
      expect(restored.activityLevel, original.activityLevel);
      expect(restored.proteinGoalG, original.proteinGoalG);
      expect(restored.carbsGoalG, original.carbsGoalG);
      expect(restored.fatGoalG, original.fatGoalG);
      expect(restored.dateOfBirth, original.dateOfBirth);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final p = UserProfile.fromJson({
        'name': 'Carol',
        'email': 'carol@example.com',
      });
      expect(p.weightKg, 70.0);
      expect(p.heightCm, 170.0);
      expect(p.gender, Gender.male);
      expect(p.activityLevel, ActivityLevel.medium);
      expect(p.dateOfBirth, isNull);
    });
  });

  group('UserProfile.copyWith', () {
    test('overrides only specified fields', () {
      final original = UserProfile(
        name: 'Dave', email: 'dave@example.com', weightKg: 75.0, heightCm: 178.0,
      );
      final updated = original.copyWith(weightKg: 80.0);
      expect(updated.weightKg, 80.0);
      expect(updated.name, original.name);
      expect(updated.heightCm, original.heightCm);
    });
  });

  group('UnitConvert', () {
    test('kgToLb', () {
      expect(UnitConvert.kgToLb(1.0), closeTo(2.2046, 0.001));
      expect(UnitConvert.kgToLb(0.0), 0.0);
    });

    test('lbToKg', () {
      expect(UnitConvert.lbToKg(2.2046226218), closeTo(1.0, 0.0001));
    });

    test('kgToLb and lbToKg are inverse', () {
      expect(UnitConvert.lbToKg(UnitConvert.kgToLb(70.0)), closeTo(70.0, 0.0001));
    });

    test('cmToFeetInches', () {
      final (feet, inches) = UnitConvert.cmToFeetInches(180.34); // ≈ 5'11"
      expect(feet, 5);
      expect(inches, 11);
    });

    test('feetInchesToCm', () {
      expect(UnitConvert.feetInchesToCm(6, 0), closeTo(182.88, 0.01));
    });

    test('feetInchesToCm and cmToFeetInches are inverse', () {
      final cm = UnitConvert.feetInchesToCm(5, 10);
      final (feet, inches) = UnitConvert.cmToFeetInches(cm);
      expect(feet, 5);
      expect(inches, 10);
    });
  });
}
