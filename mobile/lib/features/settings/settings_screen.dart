import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../api/api_client.dart';
import '../../app/haptics.dart';
import '../../api/models.dart';
import '../../app/notification_service.dart';
import '../../app/nutri_colors.dart';
import '../../app/settings_prefs.dart';
import '../auth/user_profile.dart';
import '../history/viewed_food_history_store.dart';
import 'edit_sheets.dart';
import 'widgets/settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final NutriFitApi api;
  final UserProfile? profile;
  final ViewedFoodHistoryStore? history;
  final Future<void> Function()? onLogout;
  final Future<void> Function()? onDeleteAccount;

  const SettingsScreen({
    super.key,
    required this.api,
    this.profile,
    this.history,
    this.onLogout,
    this.onDeleteAccount,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile _profile = widget.profile ??
      const UserProfile(name: 'Bakir H.', email: 'bakir@nutrifit.app', weightKg: 74.2, heightCm: 181);

  int _calorieGoal = 2150;
  MacroGoals _macros = const MacroGoals(130, 240, 70);

  late Gender _gender;
  late ActivityLevel _activity;

  late UnitSystem _unit;
  late NutriAccent _accent;
  late int _waterMl;

  bool _mealReminders = true;
  late MealReminderTimes _mealTimes;

  bool _waterReminders = false;
  late TimeOfDay _waterStart;
  late TimeOfDay _waterEnd;
  late int _waterInterval;

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
  void initState() {
    super.initState();
    final prefs = SettingsPrefs.instance;
    _unit           = prefs.unit;
    _accent         = prefs.accent;
    _waterMl        = prefs.waterGoalMl;
    _mealReminders  = prefs.mealReminders;
    _mealTimes      = _parseMealTimes(prefs.mealReminderTimes);
    _waterReminders = prefs.waterReminders;
    _waterStart     = _parseTime(prefs.waterReminderStart);
    _waterEnd       = _parseTime(prefs.waterReminderEnd);
    _waterInterval  = prefs.waterReminderIntervalMinutes;
    _haptics        = prefs.haptics;
    // Restore locally-persisted goals so they survive without the backend.
    _calorieGoal = prefs.goalCaloriesKcal;
    _macros      = MacroGoals(prefs.goalProteinG, prefs.goalCarbsG, prefs.goalFatG);
    _gender      = prefs.gender;
    _activity    = prefs.activityLevel;
    _profile = UserProfile(
      name:     prefs.displayName == 'friend' ? _profile.name : prefs.displayName,
      email:    prefs.getUserEmail() ?? _profile.email,
      weightKg: prefs.weightKg == 0.0 ? _profile.weightKg : prefs.weightKg,
      heightCm: prefs.heightCm == 0.0 ? _profile.heightCm : prefs.heightCm,
    );
    _loadFromApi();
  }

  // ── Backend ──────────────────────────────────────────────────────────────

  Future<void> _loadFromApi() async {
    try {
      final stored = await widget.api.getStorageProfile();
      if (!mounted) return;
      final name     = stored.displayName?.isNotEmpty == true ? stored.displayName! : _profile.name;
      final heightCm = stored.heightCm ?? _profile.heightCm;
      final cal      = stored.goalCaloriesKcal?.round() ?? _calorieGoal;
      final macros   = MacroGoals(
        stored.goalProteinG?.round() ?? _macros.protein,
        stored.goalCarbsG?.round()   ?? _macros.carbs,
        stored.goalFatG?.round()     ?? _macros.fat,
      );
      // Mirror to local storage so DailyLogStore picks up the latest goals
      // on the next refresh, even when the backend becomes unavailable later.
      await Future.wait([
        SettingsPrefs.instance.setDisplayName(name),
        SettingsPrefs.instance.setHeightCm(heightCm),
        SettingsPrefs.instance.setGoalCaloriesKcal(cal),
        SettingsPrefs.instance.setGoalProteinG(macros.protein),
        SettingsPrefs.instance.setGoalCarbsG(macros.carbs),
        SettingsPrefs.instance.setGoalFatG(macros.fat),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = UserProfile(
          name:     name,
          email:    _profile.email,
          weightKg: _profile.weightKg,
          heightCm: heightCm,
        );
        _calorieGoal = cal;
        _macros      = macros;
      });
    } catch (_) {
      // Keep defaults when the backend is unreachable.
    }
  }

  Future<void> _saveToApi() async {
    try {
      await widget.api.saveStorageProfile(StoredUserProfile(
        displayName:      _profile.name,
        heightCm:         _profile.heightCm,
        goalCaloriesKcal: _calorieGoal.toDouble(),
        goalProteinG:     _macros.protein.toDouble(),
        goalCarbsG:       _macros.carbs.toDouble(),
        goalFatG:         _macros.fat.toDouble(),
      ));
    } catch (_) {}
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
                if (v != null) {
                  setState(() => _calorieGoal = v);
                  SettingsPrefs.instance.setGoalCaloriesKcal(v);
                  _saveToApi();
                }
              },
            ),
            SettingsRow(
              icon: Icons.pie_chart_outline, iconColor: c.carbs, iconBg: c.carbsSoft,
              title: 'Macro targets',
              value: 'P ${_macros.protein} · C ${_macros.carbs} · F ${_macros.fat} g',
              onTap: () async {
                final v = await showEditMacrosSheet(context, _macros);
                if (v != null) {
                  setState(() => _macros = v);
                  SettingsPrefs.instance.setGoalProteinG(v.protein);
                  SettingsPrefs.instance.setGoalCarbsG(v.carbs);
                  SettingsPrefs.instance.setGoalFatG(v.fat);
                  _saveToApi();
                }
              },
            ),
            SettingsRow(
              icon: Icons.water_drop_outlined, iconColor: c.water, iconBg: c.waterSoft,
              title: 'Water goal',
              value: '${(_waterMl / 1000).toStringAsFixed(1)} L',
              onTap: () async {
                final v = await showEditWaterSheet(context, _waterMl);
                if (v != null) {
                  setState(() => _waterMl = v);
                  SettingsPrefs.instance.setWaterGoalMl(v);
                }
              },
            ),
            SettingsSegmentedRow<Gender>(
              icon: Icons.person_outline, iconColor: c.primary, iconBg: c.primaryTint,
              title: 'Sex',
              value: _gender,
              options: const [
                (Gender.male,   'Male'),
                (Gender.female, 'Female'),
                (Gender.other,  'Other'),
              ],
              onChanged: (g) {
                Haptics.selectionClick();
                setState(() => _gender = g);
                SettingsPrefs.instance.setGender(g);
              },
            ),
            SettingsRow(
              icon: Icons.directions_run, iconColor: c.carbs, iconBg: c.carbsSoft,
              title: 'Activity level',
              value: activityLabel[_activity],
              onTap: () async {
                final v = await showEditActivitySheet(context, _activity);
                if (v != null) {
                  setState(() => _activity = v);
                  SettingsPrefs.instance.setActivityLevel(v);
                }
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
              onChanged: (u) {
                Haptics.selectionClick();
                setState(() => _unit = u);
                SettingsPrefs.instance.setUnit(u);
              },
            ),
            SettingsAccentRow(
              icon: Icons.palette_outlined, iconColor: c.primary, iconBg: c.primaryTint,
              value: _accent,
              onChanged: (a) {
                Haptics.selectionClick();
                setState(() => _accent = a);
                SettingsPrefs.instance.setAccent(a);
              },
            ),
            SettingsToggleRow(
              icon: Icons.restaurant_outlined, iconColor: c.protein, iconBg: c.proteinSoft,
              title: 'Meal reminders',
              subtitle: _mealReminders ? _mealTimesDisplay : 'Nudge me to log meals',
              value: _mealReminders,
              onChanged: (v) async {
                setState(() => _mealReminders = v);
                await SettingsPrefs.instance.setMealReminders(v);
                await NotificationService.instance.setMealReminders(v, _mealTimes.asPairs);
                if (mounted) _toast(v ? 'Meal reminders on · $_mealTimesDisplay' : 'Meal reminders turned off');
              },
            ),
            if (_mealReminders)
              SettingsRow(
                icon: Icons.schedule_outlined, iconColor: c.protein, iconBg: c.proteinSoft,
                title: 'Reminder times',
                value: _mealTimesDisplay,
                onTap: _editMealTimes,
              ),
            SettingsToggleRow(
              icon: Icons.water_drop_outlined, iconColor: c.water, iconBg: c.waterSoft,
              title: 'Water reminders',
              subtitle: _waterReminders ? _waterScheduleDisplay : 'Hourly hydration nudges',
              value: _waterReminders,
              onChanged: (v) async {
                setState(() => _waterReminders = v);
                await SettingsPrefs.instance.setWaterReminders(v);
                await NotificationService.instance.setWaterReminders(
                  v,
                  _waterStart.hour, _waterStart.minute,
                  _waterEnd.hour,   _waterEnd.minute,
                  _waterInterval,
                );
                if (mounted) _toast(v ? 'Water reminders on · $_waterScheduleDisplay' : 'Water reminders turned off');
              },
            ),
            if (_waterReminders)
              SettingsRow(
                icon: Icons.schedule_outlined, iconColor: c.water, iconBg: c.waterSoft,
                title: 'Schedule',
                value: _waterScheduleDisplay,
                onTap: _editWaterSchedule,
              ),
            SettingsToggleRow(
              icon: Icons.vibration, iconColor: c.fat, iconBg: c.fatSoft,
              title: 'Haptic feedback',
              value: _haptics,
              onChanged: (v) {
                setState(() => _haptics = v);
                SettingsPrefs.instance.setHaptics(v);
                if (v) Haptics.lightImpact();
              },
            ),
          ]),

          const SettingsHeader('Data & privacy'),
          SettingsGroup(children: [
            SettingsRow(
              icon: Icons.ios_share, iconColor: c.primary, iconBg: c.primaryTint,
              title: 'Export my data',
              subtitle: 'Download a copy of your logs',
              onTap: () => _toast('Export coming soon'),
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

  // ── Avatar picker ─────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    final dir  = await getApplicationDocumentsDirectory();
    final dest = File(p.join(dir.path, 'avatar.jpg'));
    await File(picked.path).copy(dest.path);
    await SettingsPrefs.instance.setAvatarPath(dest.path);
    setState(() {});
  }

  // ── Profile hero card ─────────────────────────────────────────────────────

  Widget _profileHero(NutriColors c) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          final updated = await showEditProfileSheet(context, _profile);
          if (updated != null) {
            setState(() => _profile = updated);
            SettingsPrefs.instance.setDisplayName(updated.name);
            SettingsPrefs.instance.setHeightCm(updated.heightCm);
            SettingsPrefs.instance.setWeightKg(updated.weightKg);
            _saveToApi();
          }
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
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    () {
                      final avatarPath = SettingsPrefs.instance.avatarPath;
                      return Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          gradient: avatarPath == null ? LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [c.primarySoft, c.honey.withValues(alpha: 0.4)],
                          ) : null,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: c.line),
                          image: avatarPath != null ? DecorationImage(
                            image: FileImage(File(avatarPath)),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        alignment: Alignment.center,
                        child: avatarPath == null ? Text(
                          _avatarLetter,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: c.primaryDeep, fontSize: 22, fontWeight: FontWeight.w600,
                              ),
                        ) : null,
                      );
                    }(),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 1.5),
                        ),
                        child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                      ),
                    ),
                  ],
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _miniStat(c, _weightDisplay),
                        _miniStat(c, _heightDisplay),
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

  // ── Actions ───────────────────────────────────────────────────────────────

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
      widget.history?.clear();
      if (mounted) _toast('History cleared');
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await _confirm(
      title: 'Log out?',
      message: 'You can log back in anytime. Your on-device data stays put.',
      confirmLabel: 'Log out',
    );
    if (ok == true) await widget.onLogout?.call();
  }

  Future<void> _confirmDelete() async {
    final ok = await _confirm(
      title: 'Delete account & data?',
      message: 'This permanently deletes your account and all logs from this device and the server. This cannot be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (ok == true) await widget.onDeleteAccount?.call();
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

  // ── Time helpers ──────────────────────────────────────────────────────────

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static MealReminderTimes _parseMealTimes(List<String> list) => MealReminderTimes(
        _parseTime(list[0]),
        _parseTime(list[1]),
        _parseTime(list[2]),
      );

  static String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _mealTimesDisplay =>
      '${_fmtTime(_mealTimes.breakfast)}, ${_fmtTime(_mealTimes.lunch)}, ${_fmtTime(_mealTimes.dinner)}';

  String get _waterScheduleDisplay =>
      '${_fmtTime(_waterStart)} – ${_fmtTime(_waterEnd)}, every ${_fmtInterval(_waterInterval)}';

  static String _fmtInterval(int minutes) {
    if (minutes < 60) return '${minutes}min';
    if (minutes == 60) return '1h';
    if (minutes % 60 == 0) return '${minutes ~/ 60}h';
    return '${minutes ~/ 60}h ${minutes % 60}min';
  }

  Future<void> _editMealTimes() async {
    final result = await showMealTimesSheet(context, _mealTimes);
    if (result == null || !mounted) return;
    setState(() => _mealTimes = result);
    final strings = [
      _fmtTime(result.breakfast),
      _fmtTime(result.lunch),
      _fmtTime(result.dinner),
    ];
    await SettingsPrefs.instance.setMealReminderTimes(strings);
    if (_mealReminders) {
      await NotificationService.instance.setMealReminders(true, result.asPairs);
      if (mounted) _toast('Meal reminder times updated');
    }
  }

  Future<void> _editWaterSchedule() async {
    final result = await showWaterScheduleSheet(
      context,
      WaterSchedule(start: _waterStart, end: _waterEnd, intervalMinutes: _waterInterval),
    );
    if (result == null || !mounted) return;
    setState(() {
      _waterStart    = result.start;
      _waterEnd      = result.end;
      _waterInterval = result.intervalMinutes;
    });
    await SettingsPrefs.instance.setWaterReminderStart(_fmtTime(result.start));
    await SettingsPrefs.instance.setWaterReminderEnd(_fmtTime(result.end));
    await SettingsPrefs.instance.setWaterReminderIntervalMinutes(result.intervalMinutes);
    if (_waterReminders) {
      await NotificationService.instance.setWaterReminders(
        true,
        result.start.hour, result.start.minute,
        result.end.hour,   result.end.minute,
        result.intervalMinutes,
      );
      if (mounted) _toast('Water reminder schedule updated');
    }
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
