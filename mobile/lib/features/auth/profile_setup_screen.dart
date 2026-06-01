import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
import 'goals_setup_screen.dart';
import 'user_profile.dart';
import 'auth_widgets.dart';

/// Step 2 of sign-up: collect weight, height, gender and activity level.
class ProfileSetupScreen extends StatefulWidget {
  final String name;
  final String email;
  final Future<void> Function(UserProfile profile) onComplete;

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
  static const _minKg = 30.0, _maxKg = 300.0;
  static const _minCm = 100.0, _maxCm = 272.0;

  double? _weightKg;
  double? _heightCm;
  String? _weightError;
  String? _heightError;
  UnitSystem _unit = UnitSystem.metric;
  Gender? _gender;
  ActivityLevel? _activityLevel;
  DateTime? _dob;

  final _weightCtrl   = TextEditingController();
  final _heightCmCtrl = TextEditingController();
  final _feetCtrl     = TextEditingController();
  final _inchCtrl     = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCmCtrl.dispose();
    _feetCtrl.dispose();
    _inchCtrl.dispose();
    super.dispose();
  }

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

  void _readToCanonical() {
    if (_unit == UnitSystem.metric) {
      final kg = double.tryParse(_weightCtrl.text);
      final cm = double.tryParse(_heightCmCtrl.text);
      if (kg != null) {
        _weightKg = kg.clamp(_minKg, _maxKg);
        _weightError = (kg < _minKg || kg > _maxKg)
            ? 'Must be ${_minKg.round()}–${_maxKg.round()} kg'
            : null;
      }
      if (cm != null) {
        _heightCm = cm.clamp(_minCm, _maxCm);
        _heightError = (cm < _minCm || cm > _maxCm)
            ? 'Must be ${_minCm.round()}–${_maxCm.round()} cm'
            : null;
      }
    } else {
      final lb   = double.tryParse(_weightCtrl.text);
      final ft   = int.tryParse(_feetCtrl.text);
      final inch = double.tryParse(_inchCtrl.text);
      if (lb != null) {
        final minLb = UnitConvert.kgToLb(_minKg).roundToDouble();
        final maxLb = UnitConvert.kgToLb(_maxKg).roundToDouble();
        _weightKg = UnitConvert.lbToKg(lb).clamp(_minKg, _maxKg);
        _weightError = (lb < minLb || lb > maxLb)
            ? 'Must be ${minLb.round()}–${maxLb.round()} lb'
            : null;
      }
      if (ft != null && inch != null) {
        final cm = UnitConvert.feetInchesToCm(ft, inch.round());
        _heightCm = cm.clamp(_minCm, _maxCm);
        _heightError = (cm < _minCm || cm > _maxCm)
            ? "Must be 3'3\"–8'11\""
            : null;
      }
    }
    setState(() {});
  }

  void _normalize() => setState(_fillControllers);

  void _switchUnit(UnitSystem u) {
    if (u == _unit) return;
    HapticFeedback.selectionClick();
    _readToCanonical();
    setState(() { _unit = u; _fillControllers(); });
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
    if (_weightError != null || _heightError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields')),
      );
      return;
    }
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }
    if (_activityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your activity level')),
      );
      return;
    }
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your date of birth')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalsSetupScreen(
          name: widget.name,
          email: widget.email,
          weightKg: double.parse(_weightKg!.toStringAsFixed(1)),
          heightCm: _heightCm!.roundToDouble(),
          gender: _gender!,
          activityLevel: _activityLevel!,
          dateOfBirth: _dob,
          onComplete: widget.onComplete,
        ),
      ),
    );
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
                      child: SizedBox(width: 40, height: 40,
                        child: Icon(Icons.chevron_left, size: 26, color: c.ink)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('STEP 2 OF 3',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.8, color: c.ink2)),
                  const Spacer(),
                  const SignUpProgressDots(total: 3, current: 2),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(begin: Alignment.topLeft,
                    end: Alignment.bottomRight, colors: [c.primary, c.primaryDeep]),
                ),
                padding: const EdgeInsets.all(18),
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('PERSONALISE',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text('Tailors your calorie & macro goals.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFFFDFAF0), fontSize: 17, height: 1.25)),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Units ──────────────────────────────────────────────────
              const FieldLabel('Units'),
              _UnitToggle(value: _unit, onChanged: _switchUnit),
              const SizedBox(height: 18),

              // ── Weight ─────────────────────────────────────────────────
              const FieldLabel('Weight'),
              _MeasureField(
                controller: _weightCtrl,
                unit: _unit == UnitSystem.metric ? 'kg' : 'lb',
                hintText: 'weight', allowDecimal: true,
                errorText: _weightError,
                onChanged: (_) => _readToCanonical(), onEditingComplete: _normalize,
              ),
              const SizedBox(height: 14),

              // ── Height ─────────────────────────────────────────────────
              const FieldLabel('Height'),
              if (_unit == UnitSystem.metric)
                _MeasureField(
                  controller: _heightCmCtrl, unit: 'cm', hintText: 'height',
                  allowDecimal: false,
                  errorText: _heightError,
                  onChanged: (_) => _readToCanonical(), onEditingComplete: _normalize,
                )
              else
                Row(children: [
                  Expanded(child: _MeasureField(controller: _feetCtrl, unit: 'ft',
                    hintText: 'height', allowDecimal: false,
                    errorText: _heightError,
                    onChanged: (_) => _readToCanonical(), onEditingComplete: _normalize)),
                  const SizedBox(width: 10),
                  Expanded(child: _MeasureField(controller: _inchCtrl, unit: 'in',
                    hintText: 'height', allowDecimal: false,
                    onChanged: (_) => _readToCanonical(), onEditingComplete: _normalize)),
                ]),

              if (profile != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: c.primaryTint,
                    borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 7, height: 7,
                      decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text.rich(TextSpan(
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: c.primaryDeep),
                      children: [
                        const TextSpan(text: 'BMI '),
                        TextSpan(text: profile.bmi.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: ' · ${profile.bmiCategory}'),
                      ],
                    )),
                  ]),
                ),
              ],
              const SizedBox(height: 22),

              // ── Date of birth ──────────────────────────────────────────
              const FieldLabel('Date of birth'),
              _DobField(
                value: _dob,
                onPicked: (d) => setState(() => _dob = d),
              ),
              const SizedBox(height: 22),

              // ── Gender ─────────────────────────────────────────────────
              const FieldLabel('Gender'),
              Row(
                children: Gender.values.map((g) {
                  final selected = _gender == g;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _gender = g);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: selected ? c.primary : c.surfaceSunken,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? c.primary : c.line,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            genderLabel[g]!,
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : c.ink2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // ── Activity level ─────────────────────────────────────────
              const FieldLabel('Activity level'),
              ...ActivityLevel.values.map((level) {
                final selected = _activityLevel == level;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activityLevel = level);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? c.primarySoft : c.surfaceSunken,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? c.primary : c.line,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? c.primary : Colors.transparent,
                          border: Border.all(
                            color: selected ? c.primary : c.ink3, width: 2),
                        ),
                        child: selected
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activityLabel[level]!,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                color: selected ? c.primaryDeep : c.ink)),
                            Text(activityDescription[level]!,
                              style: TextStyle(fontSize: 12,
                                color: selected ? c.primaryDeep : c.ink2)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 26),

              FilledButton(
                onPressed: _finish,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
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

class _DobField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  const _DobField({required this.value, required this.onPicked});

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final now = DateTime.now();
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 25, now.month, now.day),
          firstDate: DateTime(now.year - 120),
          lastDate: DateTime(now.year - 13, now.month, now.day),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? _format(value!) : 'date of birth',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 22,
                  color: value != null ? c.ink : c.ink.withValues(alpha: 0.25),
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 18, color: c.ink2),
          ],
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
      child: Row(children: [
        _seg(context, 'Metric (kg · cm)', UnitSystem.metric),
        _seg(context, 'Imperial (lb · in)', UnitSystem.imperial),
      ]),
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
            boxShadow: on ? [BoxShadow(color: c.ink.withValues(alpha: 0.08),
              blurRadius: 3, offset: const Offset(0, 1))] : null,
          ),
          alignment: Alignment.center,
          child: Text(label,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
              color: on ? c.ink : c.ink2)),
        ),
      ),
    );
  }
}

class _MeasureField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String? hintText;
  final String? errorText;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const _MeasureField({
    required this.controller, required this.unit, required this.allowDecimal,
    this.hintText, this.errorText, this.onChanged, this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: hasError ? c.warn : c.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onEditingComplete: () {
                  onEditingComplete?.call();
                  FocusScope.of(context).unfocus();
                },
                keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
                inputFormatters: [FilteringTextInputFormatter.allow(
                  allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'))],
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 26),
                decoration: InputDecoration(
                  isDense: true, filled: false,
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: hintText,
                  hintStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 26, color: c.ink.withValues(alpha: 0.25)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(unit, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink2)),
          ]),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(errorText!, style: TextStyle(fontSize: 12, color: c.warn)),
          ),
        ],
      ],
    );
  }
}
