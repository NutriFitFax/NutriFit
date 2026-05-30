import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
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
Future<UserProfile?> showEditProfileSheet(BuildContext context, UserProfile p) {
  final name = TextEditingController(text: p.name);
  final email = TextEditingController(text: p.email);
  final weight = TextEditingController(text: p.weightKg.toStringAsFixed(1));
  final height = TextEditingController(text: p.heightCm.round().toString());

  return _showSheet<UserProfile>(
    context,
    _SheetScaffold(
      title: 'Edit profile',
      onSave: () {
        final wk = (double.tryParse(weight.text) ?? p.weightKg).clamp(30.0, 300.0);
        final hc = (double.tryParse(height.text) ?? p.heightCm).clamp(100.0, 272.0);
        Navigator.of(context).pop(UserProfile(
          name: name.text.trim(),
          email: email.text.trim(),
          weightKg: double.parse(wk.toStringAsFixed(1)),
          heightCm: hc.roundToDouble(),
        ));
      },
      children: [
        _Labeled(label: 'Full name', child: TextField(controller: name)),
        _Labeled(label: 'Email', child: TextField(controller: email, keyboardType: TextInputType.emailAddress)),
        Row(
          children: [
            Expanded(child: _Labeled(label: 'Weight', child: _numField(weight, suffix: 'kg', decimal: true))),
            const SizedBox(width: 12),
            Expanded(child: _Labeled(label: 'Height', child: _numField(height, suffix: 'cm'))),
          ],
        ),
      ],
    ),
  );
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
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      customBorder: const CircleBorder(),
      child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20, color: c.ink)),
    ),
  );
}
