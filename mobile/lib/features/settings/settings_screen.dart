import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
import '../auth/user_profile.dart';
import '../history/viewed_food_history_store.dart';
import 'edit_sheets.dart';
import 'widgets/settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile? profile;
  final ViewedFoodHistoryStore? history;
  final ValueChanged<NutriAccent>? onAccentChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onDeleteAccount;
  final NutriAccent initialAccent;
  final UnitSystem initialUnit;

  const SettingsScreen({
    super.key,
    this.profile,
    this.history,
    this.onAccentChanged,
    this.onLogout,
    this.onDeleteAccount,
    this.initialAccent = NutriAccent.forest,
    this.initialUnit = UnitSystem.metric,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile _profile = widget.profile ??
      const UserProfile(name: 'Bakir H.', email: 'bakir@nutrifit.app', weightKg: 74.2, heightCm: 181);

  // Goals — TODO: load/save via your daily-log / preferences store.
  int _calorieGoal = 2150;
  MacroGoals _macros = const MacroGoals(130, 240, 70);
  int _waterMl = 2500;

  late UnitSystem _unit = widget.initialUnit;
  late NutriAccent _accent = widget.initialAccent;

  bool _mealReminders = true;
  bool _waterReminders = false;
  bool _haptics = true;

  String get _avatarLetter =>
      _profile.name.trim().isEmpty ? 'U' : _profile.name.trim()[0].toUpperCase();

  String get _weightDisplay {
    if (_unit == UnitSystem.metric) return '${_profile.weightKg.toStringAsFixed(1)} kg';
    return '${UnitConvert.kgToLb(_profile.weightKg).round()} lb';
  }

  String get _heightDisplay {
    if (_unit == UnitSystem.metric) return '${_profile.heightCm.round()} cm';
    final (ft, inch) = UnitConvert.cmToFeetInches(_profile.heightCm);
    return "$ft'$inch\"";
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: [
          _profileHero(c),

          const SettingsHeader('Goals'),
          SettingsGroup(children: [
            SettingsRow(
              icon: Icons.local_fire_department_outlined, iconColor: c.primary, iconBg: c.primaryTint,
              title: 'Daily calories',
              value: '${_thousands(_calorieGoal)} kcal',
              onTap: () async {
                final v = await showEditCalorieGoalSheet(context, _calorieGoal);
                if (v != null) setState(() => _calorieGoal = v); // TODO: persist
              },
            ),
            SettingsRow(
              icon: Icons.pie_chart_outline, iconColor: c.carbs, iconBg: c.carbsSoft,
              title: 'Macro targets',
              value: 'P ${_macros.protein} · C ${_macros.carbs} · F ${_macros.fat} g',
              onTap: () async {
                final v = await showEditMacrosSheet(context, _macros);
                if (v != null) setState(() => _macros = v); // TODO: persist
              },
            ),
            SettingsRow(
              icon: Icons.water_drop_outlined, iconColor: c.water, iconBg: c.waterSoft,
              title: 'Water goal',
              value: '${(_waterMl / 1000).toStringAsFixed(1)} L',
              onTap: () async {
                final v = await showEditWaterSheet(context, _waterMl);
                if (v != null) setState(() => _waterMl = v); // TODO: persist
              },
            ),
          ]),

          const SettingsHeader('Preferences'),
          SettingsGroup(children: [
            SettingsSegmentedRow<UnitSystem>(
              icon: Icons.straighten, iconColor: c.fat, iconBg: c.fatSoft,
              title: 'Units',
              value: _unit,
              options: const [
                (UnitSystem.metric, 'Metric'),
                (UnitSystem.imperial, 'Imperial'),
              ],
              onChanged: (u) { HapticFeedback.selectionClick(); setState(() => _unit = u); }, // TODO: persist
            ),
            SettingsAccentRow(
              icon: Icons.palette_outlined, iconColor: c.primary, iconBg: c.primaryTint,
              value: _accent,
              onChanged: (a) {
                HapticFeedback.selectionClick();
                setState(() => _accent = a);
                widget.onAccentChanged?.call(a);
              },
            ),
            SettingsToggleRow(
              icon: Icons.restaurant_outlined, iconColor: c.protein, iconBg: c.proteinSoft,
              title: 'Meal reminders',
              subtitle: 'Nudge me to log meals',
              value: _mealReminders,
              onChanged: (v) => setState(() => _mealReminders = v), // TODO: schedule notifications
            ),
            SettingsToggleRow(
              icon: Icons.water_drop_outlined, iconColor: c.water, iconBg: c.waterSoft,
              title: 'Water reminders',
              subtitle: 'Hourly hydration nudges',
              value: _waterReminders,
              onChanged: (v) => setState(() => _waterReminders = v),
            ),
            SettingsToggleRow(
              icon: Icons.vibration, iconColor: c.fat, iconBg: c.fatSoft,
              title: 'Haptic feedback',
              value: _haptics,
              onChanged: (v) { setState(() => _haptics = v); if (v) HapticFeedback.lightImpact(); },
            ),
          ]),

          const SettingsHeader('Data & privacy'),
          SettingsGroup(children: [
            SettingsRow(
              icon: Icons.ios_share, iconColor: c.primary, iconBg: c.primaryTint,
              title: 'Export my data',
              subtitle: 'Download a copy of your logs',
              onTap: () => _toast('Export coming soon'), // TODO: export to JSON/CSV
            ),
            SettingsRow(
              icon: Icons.delete_sweep_outlined, iconColor: c.warn, iconBg: c.proteinSoft,
              title: 'Clear food history',
              onTap: _confirmClearHistory,
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 14, color: c.ink3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All your data is stored on this device. NutriFit never uploads your logs.',
                    style: TextStyle(fontSize: 12, color: c.ink3, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SettingsHeader('About'),
          SettingsGroup(children: [
            SettingsRow(
              icon: Icons.eco_outlined, iconColor: c.primary, iconBg: c.primaryTint,
              title: 'About NutriFit',
              subtitle: 'Built by 5 students at IUS',
              onTap: () => _showAbout(c),
            ),
            SettingsRow(
              icon: Icons.help_outline, iconColor: c.carbs, iconBg: c.carbsSoft,
              title: 'Help & feedback',
              onTap: () => _toast('Opens support — wire your link'),
            ),
            const SettingsRow(
              icon: Icons.info_outline, iconColor: Color(0xFF8A948C), iconBg: Color(0xFFEFE8D4),
              title: 'App version',
              value: '1.0.0 (1)',
            ),
          ]),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _confirmDelete,
            style: TextButton.styleFrom(foregroundColor: c.warn),
            child: const Text('Delete account & data'),
          ),
        ],
      ),
    );
  }

  // ── Profile hero card ─────────────────────────────────────────────────
  Widget _profileHero(NutriColors c) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          final updated = await showEditProfileSheet(context, _profile);
          if (updated != null) setState(() => _profile = updated); // TODO: persist
        },
        child: Ink(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: c.ink.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -8),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [c.primarySoft, c.honey.withValues(alpha: 0.4)],
                  ),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: c.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  _avatarLetter,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: c.primaryDeep, fontSize: 22, fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_profile.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 19)),
                    const SizedBox(height: 2),
                    Text(_profile.email, style: TextStyle(fontSize: 13, color: c.ink2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniStat(c, _weightDisplay),
                        const SizedBox(width: 8),
                        _miniStat(c, _heightDisplay),
                        const SizedBox(width: 8),
                        _miniStat(c, 'BMI ${_profile.bmi.toStringAsFixed(1)}'),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: c.ink3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(NutriColors c, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.ink2)),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmClearHistory() async {
    final ok = await _confirm(
      title: 'Clear food history?',
      message: 'This removes every viewed food from this device. It cannot be undone.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (ok == true) {
      widget.history?.clear(); // TODO: also clear daily logs if desired
      if (mounted) _toast('History cleared');
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await _confirm(
      title: 'Log out?',
      message: 'You can log back in anytime. Your on-device data stays put.',
      confirmLabel: 'Log out',
    );
    if (ok == true) widget.onLogout?.call();
  }

  Future<void> _confirmDelete() async {
    final ok = await _confirm(
      title: 'Delete account & data?',
      message: 'This permanently erases your profile and all logs on this device. This cannot be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (ok == true) widget.onDeleteAccount?.call();
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final c = context.nutri;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
        content: Text(message, style: TextStyle(color: c.ink2, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: c.warn) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showAbout(NutriColors c) {
    showAboutDialog(
      context: context,
      applicationName: 'NutriFit',
      applicationVersion: '1.0.0 (1)',
      applicationIcon: Icon(Icons.eco, color: c.primary, size: 36),
      children: [
        const SizedBox(height: 8),
        const Text(
          'A nutrition tracker built by a 5-person student team at the '
          'International University of Sarajevo. All data stays on your device.',
        ),
      ],
    );
  }

  static String _thousands(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
