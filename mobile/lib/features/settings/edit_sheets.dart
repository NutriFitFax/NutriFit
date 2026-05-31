import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/haptics.dart';
import '../../app/nutri_colors.dart';
import '../../app/settings_prefs.dart';
import '../auth/user_profile.dart';

/// Bottom sheets used by the Settings screen to edit values. Each returns the
/// new value via Navigator.pop, or null if dismissed.

Future<T?> _showSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).extension<NutriColors>()!.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: child,
    ),
  );
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback onSave;

  const _SheetScaffold({
    required this.title,
    this.subtitle,
    required this.children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(color: c.ink2, fontSize: 13.5)),
            ],
            const SizedBox(height: 18),
            ...children,
            const SizedBox(height: 20),
            FilledButton(onPressed: onSave, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

// ── Field helpers ─────────────────────────────────────────────────────────
class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7, left: 2),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: context.nutri.ink2),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

TextField _numField(TextEditingController ctrl, {String suffix = '', bool decimal = false}) {
  return TextField(
    controller: ctrl,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')),
    ],
    decoration: InputDecoration(suffixText: suffix),
  );
}

// ── Edit profile ───────────────────────────────────────────────────────────
Future<UserProfile?> showEditProfileSheet(BuildContext context, UserProfile p) =>
    _showSheet<UserProfile>(context, _EditProfileSheet(profile: p));

class _EditProfileSheet extends StatefulWidget {
  final UserProfile profile;
  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final bool _isImperial;
  late final TextEditingController _name;
  late final TextEditingController _weight;
  late final TextEditingController _height;    // cm — metric only
  late final TextEditingController _heightFt;  // ft  — imperial only
  late final TextEditingController _heightIn;  // in  — imperial only
  late double _bmi;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _isImperial = SettingsPrefs.instance.unit == UnitSystem.imperial;
    _name = TextEditingController(text: p.name);
    _bmi  = p.bmi;

    if (_isImperial) {
      _weight   = TextEditingController(text: UnitConvert.kgToLb(p.weightKg).round().toString());
      _height   = TextEditingController();
      final (ft, inch) = UnitConvert.cmToFeetInches(p.heightCm);
      _heightFt = TextEditingController(text: ft.toString());
      _heightIn = TextEditingController(text: inch.toString());
      _heightFt.addListener(_recompute);
      _heightIn.addListener(_recompute);
    } else {
      _weight   = TextEditingController(text: p.weightKg.toStringAsFixed(1));
      _height   = TextEditingController(text: p.heightCm.round().toString());
      _heightFt = TextEditingController();
      _heightIn = TextEditingController();
      _height.addListener(_recompute);
    }
    _weight.addListener(_recompute);
  }

  void _recompute() {
    double wk;
    double hc;
    if (_isImperial) {
      final lb = double.tryParse(_weight.text);
      final ft = int.tryParse(_heightFt.text);
      final inch = int.tryParse(_heightIn.text);
      if (lb == null || ft == null || inch == null) return;
      wk = UnitConvert.lbToKg(lb);
      hc = UnitConvert.feetInchesToCm(ft, inch);
    } else {
      final parsedWk = double.tryParse(_weight.text);
      final parsedHc = double.tryParse(_height.text);
      if (parsedWk == null || parsedHc == null || parsedHc <= 0) return;
      wk = parsedWk;
      hc = parsedHc;
    }
    final hm = hc / 100;
    if (hm > 0) setState(() => _bmi = wk / (hm * hm));
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _height.dispose();
    _heightFt.dispose();
    _heightIn.dispose();
    super.dispose();
  }

  String get _bmiCategory {
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi < 25.0) return 'Normal';
    if (_bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final c = context.nutri;
    return _SheetScaffold(
      title: 'Edit profile',
      onSave: () {
        double wk;
        double hc;
        if (_isImperial) {
          final lb = (double.tryParse(_weight.text) ?? UnitConvert.kgToLb(p.weightKg)).clamp(66.0, 661.0);
          wk = UnitConvert.lbToKg(lb);
          final ft   = int.tryParse(_heightFt.text) ?? UnitConvert.cmToFeetInches(p.heightCm).$1;
          final inch = int.tryParse(_heightIn.text) ?? UnitConvert.cmToFeetInches(p.heightCm).$2;
          hc = UnitConvert.feetInchesToCm(ft, inch).clamp(100.0, 272.0);
        } else {
          wk = (double.tryParse(_weight.text) ?? p.weightKg).clamp(30.0, 300.0);
          hc = (double.tryParse(_height.text) ?? p.heightCm).clamp(100.0, 272.0);
        }
        Navigator.of(context).pop(UserProfile(
          name: _name.text.trim(),
          email: p.email,
          weightKg: double.parse(wk.toStringAsFixed(1)),
          heightCm: hc.roundToDouble(),
        ));
      },
      children: [
        _Labeled(label: 'Username', child: TextField(controller: _name, maxLength: 24, maxLengthEnforcement: MaxLengthEnforcement.enforced)),
        if (_isImperial)
          Row(
            children: [
              Expanded(child: _Labeled(label: 'Weight', child: _numField(_weight, suffix: 'lb'))),
              const SizedBox(width: 12),
              Expanded(
                child: _Labeled(
                  label: 'Height',
                  child: Row(
                    children: [
                      Expanded(child: _numField(_heightFt, suffix: 'ft')),
                      const SizedBox(width: 6),
                      Expanded(child: _numField(_heightIn, suffix: 'in')),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _Labeled(label: 'Weight', child: _numField(_weight, suffix: 'kg', decimal: true))),
              const SizedBox(width: 12),
              Expanded(child: _Labeled(label: 'Height', child: _numField(_height, suffix: 'cm'))),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.surfaceSunken,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'BMI ${_bmi.toStringAsFixed(1)} · $_bmiCategory',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Edit calorie goal ────────────────────────────────────────────────────
Future<int?> showEditCalorieGoalSheet(BuildContext context, int current) {
  final ctrl = TextEditingController(text: current.toString());
  return _showSheet<int>(
    context,
    _SheetScaffold(
      title: 'Daily calorie goal',
      subtitle: 'Used for the ring on your home dashboard.',
      onSave: () {
        final v = (int.tryParse(ctrl.text) ?? current).clamp(800, 6000);
        Navigator.of(context).pop(v);
      },
      children: [
        _Labeled(label: 'Calories', child: _numField(ctrl, suffix: 'kcal')),
        Wrap(
          spacing: 8,
          children: [1800, 2000, 2150, 2400, 2800].map((v) {
            return ActionChip(
              label: Text('$v'),
              onPressed: () => ctrl.text = v.toString(),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// ── Edit macros ────────────────────────────────────────────────────────────
class MacroGoals {
  final int protein, carbs, fat;
  const MacroGoals(this.protein, this.carbs, this.fat);
}

Future<MacroGoals?> showEditMacrosSheet(BuildContext context, MacroGoals g) {
  final p = TextEditingController(text: g.protein.toString());
  final c = TextEditingController(text: g.carbs.toString());
  final f = TextEditingController(text: g.fat.toString());
  return _showSheet<MacroGoals>(
    context,
    _SheetScaffold(
      title: 'Macro targets',
      subtitle: 'Grams per day for protein, carbs and fat.',
      onSave: () {
        Navigator.of(context).pop(MacroGoals(
          (int.tryParse(p.text) ?? g.protein).clamp(0, 600),
          (int.tryParse(c.text) ?? g.carbs).clamp(0, 800),
          (int.tryParse(f.text) ?? g.fat).clamp(0, 400),
        ));
      },
      children: [
        Row(
          children: [
            Expanded(child: _Labeled(label: 'Protein', child: _numField(p, suffix: 'g'))),
            const SizedBox(width: 10),
            Expanded(child: _Labeled(label: 'Carbs', child: _numField(c, suffix: 'g'))),
            const SizedBox(width: 10),
            Expanded(child: _Labeled(label: 'Fat', child: _numField(f, suffix: 'g'))),
          ],
        ),
      ],
    ),
  );
}

// ── Edit water goal ──────────────────────────────────────────────────────
Future<int?> showEditWaterSheet(BuildContext context, int currentMl) {
  int ml = currentMl;
  return _showSheet<int>(
    context,
    StatefulBuilder(
      builder: (context, setSheet) {
        final c = context.nutri;
        return _SheetScaffold(
          title: 'Water goal',
          subtitle: 'Your daily hydration target.',
          onSave: () => Navigator.of(context).pop(ml),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  _round(context, Icons.remove, () => setSheet(() => ml = (ml - 250).clamp(500, 6000))),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${(ml / 1000).toStringAsFixed(2)} L',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
                        ),
                        Text('$ml ml', style: TextStyle(fontSize: 12, color: c.ink2)),
                      ],
                    ),
                  ),
                  _round(context, Icons.add, () => setSheet(() => ml = (ml + 250).clamp(500, 6000))),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget _round(BuildContext context, IconData icon, VoidCallback onTap) {
  final c = context.nutri;
  return Material(
    color: Colors.white,
    shape: CircleBorder(side: BorderSide(color: c.line)),
    child: InkWell(
      onTap: () { Haptics.selectionClick(); onTap(); },
      customBorder: const CircleBorder(),
      child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20, color: c.ink)),
    ),
  );
}

// ── Meal reminder times ──────────────────────────────────────────────────

/// Holds the three meal reminder times.
class MealReminderTimes {
  final TimeOfDay breakfast;
  final TimeOfDay lunch;
  final TimeOfDay dinner;
  const MealReminderTimes(this.breakfast, this.lunch, this.dinner);

  List<(int, int)> get asPairs =>
      [(breakfast.hour, breakfast.minute),
       (lunch.hour, lunch.minute),
       (dinner.hour, dinner.minute)];
}

Future<MealReminderTimes?> showMealTimesSheet(
    BuildContext context, MealReminderTimes current) {
  return _showSheet<MealReminderTimes>(
    context,
    _MealTimesSheet(current: current),
  );
}

class _MealTimesSheet extends StatefulWidget {
  final MealReminderTimes current;
  const _MealTimesSheet({required this.current});

  @override
  State<_MealTimesSheet> createState() => _MealTimesSheetState();
}

class _MealTimesSheetState extends State<_MealTimesSheet> {
  late TimeOfDay _breakfast;
  late TimeOfDay _lunch;
  late TimeOfDay _dinner;
  String? _error;

  @override
  void initState() {
    super.initState();
    _breakfast = widget.current.breakfast;
    _lunch     = widget.current.lunch;
    _dinner    = widget.current.dinner;
  }

  static int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pick(TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    // No MediaQuery override — clock respects the device's 12h/24h setting.
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) { onPicked(picked); setState(() => _error = null); }
  }

  void _trySave() {
    final b = _toMin(_breakfast), l = _toMin(_lunch), d = _toMin(_dinner);
    if (b >= l) {
      setState(() => _error = 'Breakfast must be earlier than Lunch.');
      return;
    }
    if (l >= d) {
      setState(() => _error = 'Lunch must be earlier than Dinner.');
      return;
    }
    Navigator.of(context).pop(MealReminderTimes(_breakfast, _lunch, _dinner));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Meal reminder times',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text('Tap a meal to change its time.',
                style: TextStyle(color: c.ink2, fontSize: 13.5)),
            const SizedBox(height: 16),
            _TimePickerRow('Breakfast', _breakfast,
                () => _pick(_breakfast, (t) => setState(() => _breakfast = t))),
            Divider(height: 1, color: c.line),
            _TimePickerRow('Lunch', _lunch,
                () => _pick(_lunch, (t) => setState(() => _lunch = t))),
            Divider(height: 1, color: c.line),
            _TimePickerRow('Dinner', _dinner,
                () => _pick(_dinner, (t) => setState(() => _dinner = t))),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: c.warn, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _trySave, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

// ── Water reminder schedule ──────────────────────────────────────────────

/// Interval is stored in minutes.
class WaterSchedule {
  final TimeOfDay start;
  final TimeOfDay end;
  final int intervalMinutes;
  const WaterSchedule({required this.start, required this.end, required this.intervalMinutes});
}

/// Available interval options (minutes → display label).
const _intervalOptions = [
  (30,  '30 min'),
  (60,  '1 hour'),
  (90,  '1.5 h'),
  (120, '2 hours'),
  (180, '3 hours'),
];

Future<WaterSchedule?> showWaterScheduleSheet(
    BuildContext context, WaterSchedule current) {
  return _showSheet<WaterSchedule>(
    context,
    _WaterScheduleSheet(current: current),
  );
}

class _WaterScheduleSheet extends StatefulWidget {
  final WaterSchedule current;
  const _WaterScheduleSheet({required this.current});

  @override
  State<_WaterScheduleSheet> createState() => _WaterScheduleSheetState();
}

class _WaterScheduleSheetState extends State<_WaterScheduleSheet> {
  late TimeOfDay _start;
  late TimeOfDay _end;
  late int _interval;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start    = widget.current.start;
    _end      = widget.current.end;
    _interval = widget.current.intervalMinutes;
  }

  static int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pick(TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) { onPicked(picked); setState(() => _error = null); }
  }

  void _trySave() {
    if (_toMin(_start) >= _toMin(_end)) {
      setState(() => _error = 'Start time must be earlier than end time.');
      return;
    }
    Navigator.of(context).pop(
        WaterSchedule(start: _start, end: _end, intervalMinutes: _interval));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Water reminder schedule',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text('Remind me to drink water between these times.',
                style: TextStyle(color: c.ink2, fontSize: 13.5)),
            const SizedBox(height: 16),
            _TimePickerRow('From', _start,
                () => _pick(_start, (t) => setState(() => _start = t))),
            Divider(height: 1, color: c.line),
            _TimePickerRow('Until', _end,
                () => _pick(_end, (t) => setState(() => _end = t))),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: c.warn, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            Text('EVERY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: c.ink2, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (min, label) in _intervalOptions)
                  GestureDetector(
                    onTap: () { Haptics.selectionClick(); setState(() => _interval = min); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: _interval == min ? c.primary : c.surfaceSunken,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: _interval == min ? c.primary : c.line,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600,
                          color: _interval == min ? Colors.white : c.ink2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _trySave, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

// ── Shared time picker row ───────────────────────────────────────────────

class _TimePickerRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimePickerRow(this.label, this.time, this.onTap);

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return InkWell(
      onTap: () { Haptics.selectionClick(); onTap(); },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            // time.format(context) respects the device's 12h/24h preference.
            Text(time.format(context),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: c.primary)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: c.ink3),
          ],
        ),
      ),
    );
  }
}
