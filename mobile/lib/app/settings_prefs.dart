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
  }

  static const _kAccent   = 'accent_index';
  static const _kUnit     = 'unit_system';
  static const _kWaterMl  = 'water_goal_ml';

  /// Notifies listeners when the accent changes so the app theme can rebuild.
  late final ValueNotifier<NutriAccent> accentNotifier;

  NutriAccent get accent => accentNotifier.value;
  Future<void> setAccent(NutriAccent a) async {
    accentNotifier.value = a;
    await _p.setInt(_kAccent, a.index);
  }

  UnitSystem get unit =>
      UnitSystem.values[(_p.getInt(_kUnit) ?? 0).clamp(0, UnitSystem.values.length - 1)];
  Future<void> setUnit(UnitSystem u) => _p.setInt(_kUnit, u.index);

  int get waterGoalMl => _p.getInt(_kWaterMl) ?? 2500;
  Future<void> setWaterGoalMl(int ml) => _p.setInt(_kWaterMl, ml);
}
