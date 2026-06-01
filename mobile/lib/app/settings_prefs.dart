import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/user_profile.dart';
import '../features/settings/widgets/settings_widgets.dart';

/// Singleton wrapper around SharedPreferences for settings that live
/// on-device only (accent, units, water goal).
///
/// Initialise once before runApp:
///   await SettingsPrefs.init();
///
/// Then read/write anywhere via SettingsPrefs.instance.
class SettingsPrefs {
  static SettingsPrefs? _instance;
  static SettingsPrefs get instance => _instance!;

  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _instance = SettingsPrefs._(p);
  }

  final SharedPreferences _p;

  SettingsPrefs._(this._p) {
    accentNotifier = ValueNotifier(
      NutriAccent.values[(_p.getInt(_kAccent) ?? 0).clamp(0, NutriAccent.values.length - 1)],
    );
    displayNameNotifier = ValueNotifier(_p.getString(_kDisplayName) ?? 'friend');
    avatarPathNotifier  = ValueNotifier(_p.getString(_kAvatarPath));
  }

  static const _kAccent   = 'accent_index';
  static const _kUnit     = 'unit_system';
  static const _kWaterMl  = 'water_goal_ml';

  /// Notifies listeners when the accent changes so the app theme can rebuild.
  late final ValueNotifier<NutriAccent> accentNotifier;

  /// Notifies listeners when the display name changes.
  late final ValueNotifier<String> displayNameNotifier;

  /// Notifies listeners when the avatar image path changes.
  late final ValueNotifier<String?> avatarPathNotifier;

  NutriAccent get accent => accentNotifier.value;
  Future<void> setAccent(NutriAccent a) async {
    accentNotifier.value = a;
    await _p.setInt(_kAccent, a.index);
  }

  Future<void> clearAccent() async {
    accentNotifier.value = NutriAccent.values[0];
    await _p.remove(_kAccent);
  }

  UnitSystem get unit =>
      UnitSystem.values[(_p.getInt(_kUnit) ?? 0).clamp(0, UnitSystem.values.length - 1)];
  Future<void> setUnit(UnitSystem u) => _p.setInt(_kUnit, u.index);

  int get waterGoalMl => _p.getInt(_kWaterMl) ?? 2000;
  Future<void> setWaterGoalMl(int ml) => _p.setInt(_kWaterMl, ml);

  static const _kMealReminders  = 'meal_reminders';
  static const _kWaterReminders = 'water_reminders';

  bool get mealReminders => _p.getBool(_kMealReminders) ?? true;
  Future<void> setMealReminders(bool v) => _p.setBool(_kMealReminders, v);

  static const _kMealTimes = 'meal_reminder_times';
  static const _defaultMealTimes = ['08:00', '12:30', '18:30'];

  List<String> get mealReminderTimes =>
      _p.getStringList(_kMealTimes) ?? _defaultMealTimes;
  Future<void> setMealReminderTimes(List<String> t) =>
      _p.setStringList(_kMealTimes, t);

  bool get waterReminders => _p.getBool(_kWaterReminders) ?? false;
  Future<void> setWaterReminders(bool v) => _p.setBool(_kWaterReminders, v);

  static const _kWaterStart       = 'water_reminder_start';
  static const _kWaterEnd         = 'water_reminder_end';
  // New key (minutes) — avoids colliding with old key that stored hours.
  static const _kWaterIntervalMin = 'water_reminder_interval_min';

  String get waterReminderStart => _p.getString(_kWaterStart) ?? '08:00';
  Future<void> setWaterReminderStart(String t) => _p.setString(_kWaterStart, t);

  String get waterReminderEnd => _p.getString(_kWaterEnd) ?? '22:00';
  Future<void> setWaterReminderEnd(String t) => _p.setString(_kWaterEnd, t);

  int get waterReminderIntervalMinutes => _p.getInt(_kWaterIntervalMin) ?? 60;
  Future<void> setWaterReminderIntervalMinutes(int minutes) =>
      _p.setInt(_kWaterIntervalMin, minutes);

  static const _kHaptics = 'haptics';

  bool get haptics => _p.getBool(_kHaptics) ?? true;
  Future<void> setHaptics(bool v) => _p.setBool(_kHaptics, v);

  // ── Goal fields (persisted locally so DailyLogStore can read them) ────────

  static const _kGoalCalories = 'goal_calories_kcal';
  static const _kGoalProtein  = 'goal_protein_g';
  static const _kGoalCarbs    = 'goal_carbs_g';
  static const _kGoalFat      = 'goal_fat_g';
  static const _kHeightCm     = 'height_cm';
  static const _kWeightKg     = 'weight_kg';
  static const _kDisplayName  = 'display_name';
  static const _kAvatarPath   = 'avatar_path';

  int get goalCaloriesKcal => _p.getInt(_kGoalCalories) ?? 2150;
  Future<void> setGoalCaloriesKcal(int v) => _p.setInt(_kGoalCalories, v);

  int get goalProteinG => _p.getInt(_kGoalProtein) ?? 130;
  Future<void> setGoalProteinG(int v) => _p.setInt(_kGoalProtein, v);

  int get goalCarbsG => _p.getInt(_kGoalCarbs) ?? 240;
  Future<void> setGoalCarbsG(int v) => _p.setInt(_kGoalCarbs, v);

  int get goalFatG => _p.getInt(_kGoalFat) ?? 70;
  Future<void> setGoalFatG(int v) => _p.setInt(_kGoalFat, v);

  double get heightCm => _p.getDouble(_kHeightCm) ?? 0.0;
  Future<void> setHeightCm(double v) => _p.setDouble(_kHeightCm, v);

  double get weightKg => _p.getDouble(_kWeightKg) ?? 0.0;
  Future<void> setWeightKg(double v) => _p.setDouble(_kWeightKg, v);

  String get displayName => _p.getString(_kDisplayName) ?? 'friend';
  Future<void> setDisplayName(String v) async {
    displayNameNotifier.value = v;
    await _p.setString(_kDisplayName, v);
  }

  String? get avatarPath => _p.getString(_kAvatarPath);
  Future<void> setAvatarPath(String path) async {
    avatarPathNotifier.value = path;
    await _p.setString(_kAvatarPath, path);
  }
  Future<void> clearAvatarPath() async {
    avatarPathNotifier.value = null;
    await _p.remove(_kAvatarPath);
  }

  static const _kGender        = 'gender';
  static const _kActivityLevel = 'activity_level';
  static const _kDateOfBirth   = 'date_of_birth';

  Gender get gender => Gender.values.firstWhere(
    // Fall back to the pre-rename 'sex' key so existing users keep their value.
    (g) => g.name == (_p.getString(_kGender) ?? _p.getString('sex') ?? ''),
    orElse: () => Gender.male,
  );
  Future<void> setGender(Gender g) => _p.setString(_kGender, g.name);

  /// Parses an activity level string that may come from the old build (which
  /// stored snake_case keys via `_activityLevelKey`) or the current build
  /// (which stores the Dart enum `.name`, i.e. camelCase).
  static ActivityLevel parseActivityLevel(String? s,
      {ActivityLevel fallback = ActivityLevel.medium}) {
    if (s == null || s.isEmpty) return fallback;
    switch (s) {
      case 'moderate':     return ActivityLevel.medium;
      case 'very_active':  return ActivityLevel.active;
      case 'extra_active': return ActivityLevel.veryActive;
    }
    return ActivityLevel.values.firstWhere((a) => a.name == s,
        orElse: () => fallback);
  }

  ActivityLevel get activityLevel =>
      parseActivityLevel(_p.getString(_kActivityLevel));
  Future<void> setActivityLevel(ActivityLevel a) =>
      _p.setString(_kActivityLevel, a.name);

  DateTime? get dateOfBirth {
    final s = _p.getString(_kDateOfBirth);
    return s != null ? DateTime.tryParse(s) : null;
  }
  Future<void> setDateOfBirth(DateTime d) =>
      _p.setString(_kDateOfBirth, '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');

  static const _kUserEmail = 'user_email';

  String? getUserEmail() => _p.getString(_kUserEmail);
  Future<void> setUserEmail(String email) => _p.setString(_kUserEmail, email);
  Future<void> clearUserEmail() => _p.remove(_kUserEmail);
}
