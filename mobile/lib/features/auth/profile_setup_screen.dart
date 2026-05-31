import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
import 'user_profile.dart';
import 'auth_widgets.dart';

/// Step 2 of sign-up: collect weight + height (keyboard-editable, with a
/// metric/imperial toggle) and show a live BMI readout. Produces the finished
/// [UserProfile]. Height is clamped to 100–272 cm; weight to 30–300 kg.
class ProfileSetupScreen extends StatefulWidget {
  final String name;
  final String email;
  final void Function(UserProfile profile) onComplete;

  const ProfileSetupScreen({
    super.key,
    required this.name,
    required this.email,
    required this.onComplete,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // Bounds (canonical metric).
  static const _minKg = 30.0,  _maxKg = 300.0;
  static const _minCm = 100.0, _maxCm = 272.0;

  // Canonical values — null until the user types something.
  double? _weightKg;
  double? _heightCm;
  UnitSystem _unit = UnitSystem.metric;

  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.medium;

  // Editable controllers.
  final _weightCtrl = TextEditingController();
  final _heightCmCtrl = TextEditingController();
  final _feetCtrl = TextEditingController();
  final _inchCtrl = TextEditingController();

  // Macro-goal controllers (grams/day).
  final _proteinCtrl = TextEditingController(text: '130');
  final _carbsCtrl = TextEditingController(text: '240');
  final _fatCtrl = TextEditingController(text: '70');

  @override
  void initState() {
    super.initState();
    _fillControllers();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCmCtrl.dispose();
    _feetCtrl.dispose();
    _inchCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  int get _proteinG => int.tryParse(_proteinCtrl.text)?.clamp(0, 600) ?? 0;
  int get _carbsG => int.tryParse(_carbsCtrl.text)?.clamp(0, 800) ?? 0;
  int get _fatG => int.tryParse(_fatCtrl.text)?.clamp(0, 400) ?? 0;
  int get _macroKcal => _proteinG * 4 + _carbsG * 4 + _fatG * 9;

  /// Push canonical values into the controllers (on unit switch / blur).
  void _fillControllers() {
    if (_unit == UnitSystem.metric) {
      if (_weightKg != null) _weightCtrl.text = _weightKg!.toStringAsFixed(1);
      if (_heightCm != null) _heightCmCtrl.text = _heightCm!.round().toString();
    } else {
      if (_weightKg != null) _weightCtrl.text = UnitConvert.kgToLb(_weightKg!).round().toString();
      if (_heightCm != null) {
        final (ft, inch) = UnitConvert.cmToFeetInches(_heightCm!);
        _feetCtrl.text = ft.toString();
        _inchCtrl.text = inch.toString();
      }
    }
  }

  /// Read controllers → canonical (live, while typing). Does not rewrite the
  /// text (so the cursor doesn't jump); just keeps BMI in sync.
  void _readToCanonical() {
    if (_unit == UnitSystem.metric) {
      final kg = double.tryParse(_weightCtrl.text);
      final cm = double.tryParse(_heightCmCtrl.text);
      if (kg != null) _weightKg = kg.clamp(_minKg, _maxKg);
      if (cm != null) _heightCm = cm.clamp(_minCm, _maxCm);
    } else {
      final lb = double.tryParse(_weightCtrl.text);
      final ft = int.tryParse(_feetCtrl.text);
      final inch = double.tryParse(_inchCtrl.text);
      if (lb != null) _weightKg = UnitConvert.lbToKg(lb).clamp(_minKg, _maxKg);
      if (ft != null && inch != null) {
        _heightCm = UnitConvert.feetInchesToCm(ft, inch.round()).clamp(_minCm, _maxCm);
      }
    }
    setState(() {}); // refresh BMI chip
  }

  void _normalize() => setState(_fillControllers);

  void _switchUnit(UnitSystem u) {
    if (u == _unit) return;
    HapticFeedback.selectionClick();
    _readToCanonical();          // commit current entry
    setState(() {
      _unit = u;
      _fillControllers();        // repopulate in the new unit
    });
  }

  void _finish() {
    FocusScope.of(context).unfocus();
    _readToCanonical();
    if (_weightKg == null || _heightCm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your weight and height')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onComplete(UserProfile(
      name: widget.name,
      email: widget.email,
      weightKg: double.parse(_weightKg!.toStringAsFixed(1)),
      heightCm: _heightCm!.roundToDouble(),
      gender: _gender,
      activityLevel: _activity,
      proteinGoalG: _proteinG,
      carbsGoalG: _carbsG,
      fatGoalG: _fatG,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final profile = (_weightKg != null && _heightCm != null)
        ? UserProfile(name: widget.name, email: widget.email, weightKg: _weightKg!, heightCm: _heightCm!)
        : null;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 6, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 40, height: 40,
                        child: Icon(Icons.chevron_left, size: 26, color: c.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'STEP 2 OF 2',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: c.ink2),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Hero banner
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [c.primary, c.primaryDeep],
                  ),
                ),
                padding: const EdgeInsets.all(18),
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('PERSONALISE',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tailors your daily\ncalorie & macro goals.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFFFDFAF0), fontSize: 19, height: 1.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Text('ABOUT YOU',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: c.ink3),
              ),
              const SizedBox(height: 4),
              Text('Your measurements',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 18),

              const FieldLabel('Units'),
              _UnitToggle(value: _unit, onChanged: _switchUnit),
              const SizedBox(height: 18),

              // Weight
              const FieldLabel('Weight'),
              _MeasureField(
                controller: _weightCtrl,
                unit: _unit == UnitSystem.metric ? 'kg' : 'lb',
                hintText: 'weight',
                allowDecimal: true,
                onChanged: (_) => _readToCanonical(),
                onEditingComplete: _normalize,
              ),
              const SizedBox(height: 14),

              // Height
              const FieldLabel('Height'),
              if (_unit == UnitSystem.metric)
                _MeasureField(
                  controller: _heightCmCtrl,
                  unit: 'cm',
                  hintText: 'height',
                  allowDecimal: false,
                  onChanged: (_) => _readToCanonical(),
                  onEditingComplete: _normalize,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _MeasureField(
                        controller: _feetCtrl,
                        unit: 'ft',
                        hintText: 'height',
                        allowDecimal: false,
                        onChanged: (_) => _readToCanonical(),
                        onEditingComplete: _normalize,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MeasureField(
                        controller: _inchCtrl,
                        unit: 'in',
                        hintText: '',
                        allowDecimal: false,
                        onChanged: (_) => _readToCanonical(),
                        onEditingComplete: _normalize,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (profile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: c.primaryTint, borderRadius: BorderRadius.circular(99)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text.rich(TextSpan(
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.primaryDeep),
                            children: [
                              const TextSpan(text: 'BMI '),
                              TextSpan(text: profile.bmi.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800)),
                              TextSpan(text: ' · ${profile.bmiCategory}'),
                            ],
                          )),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Text('Change anytime', style: TextStyle(fontSize: 12, color: c.ink3)),
                ],
              ),
              const SizedBox(height: 22),

              // Gender
              const FieldLabel('Gender'),
              _GenderToggle(
                value: _gender,
                onChanged: (g) { HapticFeedback.selectionClick(); setState(() => _gender = g); },
              ),
              const SizedBox(height: 22),

              // Activity level (slider)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const FieldLabel('Activity level'),
                  Text(
                    activityLabel[_activity]!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.primary),
                  ),
                ],
              ),
              _ActivitySlider(
                value: _activity,
                onChanged: (a) { HapticFeedback.selectionClick(); setState(() => _activity = a); },
              ),
              const SizedBox(height: 6),
              Text(
                activityDescription[_activity]!,
                style: TextStyle(fontSize: 12.5, color: c.ink2),
              ),
              const SizedBox(height: 22),

              // Macro goals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const FieldLabel('Daily macro goals'),
                  Text(
                    '≈ $_macroKcal kcal',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink2),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _MacroField(
                      controller: _proteinCtrl,
                      label: 'Protein',
                      accent: c.protein,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MacroField(
                      controller: _carbsCtrl,
                      label: 'Carbs',
                      accent: c.carbs,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MacroField(
                      controller: _fatCtrl,
                      label: 'Fat',
                      accent: c.fat,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: _finish,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Create account'),
                    SizedBox(width: 8),
                    Icon(Icons.check, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final UnitSystem value;
  final ValueChanged<UnitSystem> onChanged;
  const _UnitToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _seg(context, 'Metric (kg · cm)', UnitSystem.metric),
          _seg(context, 'Imperial (lb · in)', UnitSystem.imperial),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String label, UnitSystem u) {
    final c = context.nutri;
    final on = value == u;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(u),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: on ? [BoxShadow(color: c.ink.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600,
              color: on ? c.ink : c.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cream rounded field holding a large serif number input with a unit suffix.
class _MeasureField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String? hintText;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const _MeasureField({
    required this.controller,
    required this.unit,
    required this.allowDecimal,
    this.hintText,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onEditingComplete: () {
                onEditingComplete?.call();
                FocusScope.of(context).unfocus();
              },
              keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
                ),
              ],
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 26),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 26,
                  color: context.nutri.ink.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(unit, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink2)),
        ],
      ),
    );
  }
}

/// Three-option segmented control for [Gender].
class _GenderToggle extends StatelessWidget {
  final Gender value;
  final ValueChanged<Gender> onChanged;
  const _GenderToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (final g in Gender.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: g == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: g == value
                        ? [BoxShadow(color: c.ink.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    genderLabel[g]!,
                    style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: g == value ? c.ink : c.ink2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Discrete 5-stop slider mapping to [ActivityLevel].
class _ActivitySlider extends StatelessWidget {
  final ActivityLevel value;
  final ValueChanged<ActivityLevel> onChanged;
  const _ActivitySlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final levels = ActivityLevel.values;
    final idx = levels.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 5,
            activeTrackColor: c.primary,
            inactiveTrackColor: c.line,
            thumbColor: c.primary,
            overlayColor: c.primary.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2.5),
            activeTickMarkColor: Colors.white.withValues(alpha: 0.7),
            inactiveTickMarkColor: c.lineStrong,
          ),
          child: Slider(
            value: idx.toDouble(),
            min: 0,
            max: (levels.length - 1).toDouble(),
            divisions: levels.length - 1,
            onChanged: (v) => onChanged(levels[v.round()]),
          ),
        ),
        // Endpoint labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sedentary', style: TextStyle(fontSize: 11, color: c.ink3)),
              Text('Very active', style: TextStyle(fontSize: 11, color: c.ink3)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cream field for a macro goal: large number + "g" suffix and a coloured label.
class _MacroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color accent;
  final ValueChanged<String>? onChanged;

  const _MacroField({
    required this.controller,
    required this.label,
    required this.accent,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
              Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: c.ink2),
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
                  onChanged: onChanged,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 22),
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
              Text('g', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink2)),
            ],
          ),
        ],
      ),
    );
  }
}
