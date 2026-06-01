import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
import 'user_profile.dart';

/// Step 3 of sign-up — "Set Your Goals".
///
/// Takes the profile data collected in earlier steps and lets the user pick a
/// goal (lose / maintain / gain) or enter custom macros. For automatic goals it
/// previews an estimated calorie + macro target computed in the background with
/// the Mifflin–St Jeor BMR formula × an activity multiplier (no AI involved),
/// then returns a finished [UserProfile] via [onComplete].
class GoalsSetupScreen extends StatefulWidget {
  final String name;
  final String email;
  final double weightKg;
  final double heightCm;
  final Gender gender;
  final ActivityLevel activityLevel;

  /// Date of birth from an earlier step; used to compute age. If null we fall
  /// back to [fallbackAge].
  final DateTime? dateOfBirth;
  final int fallbackAge;

  final void Function(UserProfile profile) onComplete;

  const GoalsSetupScreen({
    super.key,
    required this.name,
    required this.email,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.activityLevel,
    required this.onComplete,
    this.dateOfBirth,
    this.fallbackAge = 30,
  });

  @override
  State<GoalsSetupScreen> createState() => _GoalsSetupScreenState();
}

enum GoalType { lose, maintain, gain, custom }

class _GoalsSetupScreenState extends State<GoalsSetupScreen> {
  GoalType _goal = GoalType.maintain;

  // Custom macro controllers (seeded from the maintain estimate).
  late final TextEditingController _calCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;

  @override
  void initState() {
    super.initState();
    final seed = _estimateFor(GoalType.maintain);
    _calCtrl = TextEditingController(text: seed.calories.toString());
    _proteinCtrl = TextEditingController(text: seed.protein.toString());
    _carbsCtrl = TextEditingController(text: seed.carbs.toString());
    _fatCtrl = TextEditingController(text: seed.fat.toString());
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  int get _age {
    final dob = widget.dateOfBirth;
    if (dob == null) return widget.fallbackAge;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age.clamp(13, 100);
  }

  /// Mifflin–St Jeor BMR.
  double get _bmr {
    final base = 10 * widget.weightKg + 6.25 * widget.heightCm - 5 * _age;
    return switch (widget.gender) {
      Gender.male => base + 5,
      Gender.female => base - 161,
      Gender.other => base - 78, // average of +5 / -161
    };
  }

  double get _tdee => _bmr * (activityMultiplier[widget.activityLevel] ?? 1.55);

  /// Estimated targets for an automatic goal.
  _MacroEstimate _estimateFor(GoalType goal) {
    final kg = widget.weightKg;
    // Calorie adjustment per goal.
    final calories = switch (goal) {
      GoalType.lose => _tdee - 500,
      GoalType.gain => _tdee + 300,
      _ => _tdee, // maintain / custom seed
    };
    // Protein & fat per kg, remainder to carbs.
    final proteinPerKg = goal == GoalType.lose ? 2.0 : 1.8;
    const fatPerKg = 0.8;
    final proteinG = (proteinPerKg * kg).round();
    final fatG = (fatPerKg * kg).round();
    final carbKcal = calories - (proteinG * 4) - (fatG * 9);
    final carbsG = (carbKcal / 4).round().clamp(0, 1000);
    return _MacroEstimate(
      calories: (calories / 10).round() * 10, // round to nearest 10
      protein: proteinG,
      carbs: carbsG,
      fat: fatG,
    );
  }

  _MacroEstimate get _current {
    if (_goal == GoalType.custom) {
      return _MacroEstimate(
        calories: int.tryParse(_calCtrl.text) ?? 0,
        protein: int.tryParse(_proteinCtrl.text) ?? 0,
        carbs: int.tryParse(_carbsCtrl.text) ?? 0,
        fat: int.tryParse(_fatCtrl.text) ?? 0,
      );
    }
    return _estimateFor(_goal);
  }

  void _select(GoalType g) {
    HapticFeedback.selectionClick();
    setState(() => _goal = g);
  }

  void _finish() {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    final m = _current;
    widget.onComplete(UserProfile(
      name: widget.name,
      email: widget.email,
      weightKg: widget.weightKg,
      heightCm: widget.heightCm,
      gender: widget.gender,
      activityLevel: widget.activityLevel,
      proteinGoalG: m.protein,
      carbsGoalG: m.carbs,
      fatGoalG: m.fat,
      dateOfBirth: widget.dateOfBirth,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back + progress dots ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 26, 6),
              child: Row(
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.chevron_left, size: 26, color: c.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'STEP 3 OF 3',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: c.ink2),
                  ),
                  const Spacer(),
                  const _ProgressDots(total: 3, current: 3),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 6, 26, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set your goals',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose a goal and we'll estimate your daily calories and macros. You can always edit them later.",
                      style:
                          TextStyle(color: c.ink2, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 22),

                    // ── Goal cards (2×2 grid) ──────────────────────────
                    Row(
                      children: [
                        Expanded(
                            child: _GoalCard(
                          icon: Icons.trending_down,
                          label: 'Lose weight',
                          selected: _goal == GoalType.lose,
                          onTap: () => _select(GoalType.lose),
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _GoalCard(
                          icon: Icons.balance,
                          label: 'Maintain',
                          selected: _goal == GoalType.maintain,
                          onTap: () => _select(GoalType.maintain),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _GoalCard(
                          icon: Icons.fitness_center,
                          label: 'Gain muscle',
                          selected: _goal == GoalType.gain,
                          onTap: () => _select(GoalType.gain),
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _GoalCard(
                          icon: Icons.tune,
                          label: 'Custom',
                          selected: _goal == GoalType.custom,
                          onTap: () => _select(GoalType.custom),
                        )),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Explanation line ───────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: c.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _goalExplanation,
                            style: TextStyle(
                                fontSize: 13, color: c.ink2, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Preview OR custom editor ───────────────────────
                    if (_goal == GoalType.custom)
                      _CustomEditor(
                        calCtrl: _calCtrl,
                        proteinCtrl: _proteinCtrl,
                        carbsCtrl: _carbsCtrl,
                        fatCtrl: _fatCtrl,
                        onChanged: () => setState(() {}),
                      )
                    else
                      _PreviewPanel(estimate: _current),
                  ],
                ),
              ),
            ),

            // ── Bottom action ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 14),
              child: FilledButton(
                onPressed: _finish,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_goal == GoalType.custom
                        ? 'Create account'
                        : 'Create account'),
                    const SizedBox(width: 8),
                    const Icon(Icons.check, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _goalExplanation => switch (_goal) {
        GoalType.lose =>
          'A gentle calorie deficit (~500 kcal/day) with higher protein to keep muscle while you lose fat.',
        GoalType.maintain =>
          'Matches your estimated daily burn so your weight stays steady.',
        GoalType.gain =>
          'A small surplus (~300 kcal/day) with high protein to support muscle growth.',
        GoalType.custom =>
          'Enter your own targets. You can fine-tune these later in settings.',
      };
}

// ─────────────────────────────────────────────────────────────────────────

class _MacroEstimate {
  final int calories, protein, carbs, fat;
  const _MacroEstimate({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class _ProgressDots extends StatelessWidget {
  final int total, current;
  const _ProgressDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Row(
      children: [
        for (var i = 1; i <= total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 5),
            width: i == current ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i <= current ? c.primary : c.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GoalCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? c.primaryTint : c.surface,
            border: Border.all(
              color: selected ? c.primary : c.line,
              width: selected ? 1.8 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? c.primary : c.surfaceSunken,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon,
                    size: 21, color: selected ? Colors.white : c.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? c.primaryDeep : c.ink,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 18, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview of the estimated targets — calories first, then P/C/F.
class _PreviewPanel extends StatelessWidget {
  final _MacroEstimate estimate;
  const _PreviewPanel({required this.estimate});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: c.ink.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ESTIMATED DAILY TARGET',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: c.ink2),
          ),
          const SizedBox(height: 10),
          // Calories — hero number
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                estimate.calories.toString(),
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontSize: 44, height: 1.0),
              ),
              const SizedBox(width: 6),
              Text('kcal',
                  style: TextStyle(
                      fontSize: 16,
                      color: c.ink2,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: c.line, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _MacroStat(
                      value: estimate.protein,
                      label: 'Protein',
                      color: c.protein)),
              Expanded(
                  child: _MacroStat(
                      value: estimate.carbs, label: 'Carbs', color: c.carbs)),
              Expanded(
                  child: _MacroStat(
                      value: estimate.fat, label: 'Fat', color: c.fat)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.auto_graph, size: 14, color: c.ink3),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'These are starting estimates based on your profile.',
                  style: TextStyle(fontSize: 11.5, color: c.ink3, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _MacroStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              '${value}g',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: c.ink2, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Editable macro fields shown when "Custom" is selected.
class _CustomEditor extends StatelessWidget {
  final TextEditingController calCtrl, proteinCtrl, carbsCtrl, fatCtrl;
  final VoidCallback onChanged;
  const _CustomEditor({
    required this.calCtrl,
    required this.proteinCtrl,
    required this.carbsCtrl,
    required this.fatCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CustomField(
            controller: calCtrl,
            label: 'Calories',
            unit: 'kcal',
            accent: c.ink,
            onChanged: onChanged),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _CustomField(
                    controller: proteinCtrl,
                    label: 'Protein',
                    unit: 'g',
                    accent: c.protein,
                    onChanged: onChanged)),
            const SizedBox(width: 10),
            Expanded(
                child: _CustomField(
                    controller: carbsCtrl,
                    label: 'Carbs',
                    unit: 'g',
                    accent: c.carbs,
                    onChanged: onChanged)),
            const SizedBox(width: 10),
            Expanded(
                child: _CustomField(
                    controller: fatCtrl,
                    label: 'Fat',
                    unit: 'g',
                    accent: c.fat,
                    onChanged: onChanged)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'You can fine-tune these later in settings.',
          style: TextStyle(fontSize: 11.5, color: c.ink3),
        ),
      ],
    );
  }
}

class _CustomField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final Color accent;
  final VoidCallback onChanged;
  const _CustomField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: c.ink2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontSize: 22),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              Text(unit,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.ink2)),
            ],
          ),
        ],
      ),
    );
  }
}
