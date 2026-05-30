import 'package:flutter/services.dart';

import 'settings_prefs.dart';

/// Drop-in replacement for [HapticFeedback] that respects the user's
/// haptic feedback toggle in Settings.
class Haptics {
  static bool get _on => SettingsPrefs.instance.haptics;

  static void selectionClick() { if (_on) HapticFeedback.selectionClick(); }
  static void lightImpact()    { if (_on) HapticFeedback.lightImpact(); }
  static void mediumImpact()   { if (_on) HapticFeedback.mediumImpact(); }
  static void heavyImpact()    { if (_on) HapticFeedback.heavyImpact(); }
}
