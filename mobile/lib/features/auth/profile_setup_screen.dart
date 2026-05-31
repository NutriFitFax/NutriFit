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

  // Canonical values — the single source of truth.
  double _weightKg = 74.2;
  double _heightCm = 181;
  UnitSystem _unit = UnitSystem.metric;

  // Editable controllers.
  final _weightCtrl = TextEditingController();
  final _heightCmCtrl = TextEditingController();
  final _feetCtrl = TextEditingController();
  final _inchCtrl = TextEditingController();

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
    super.dispose();
  }

  /// Push canonical values into the controllers (on unit switch / blur).
  void _fillControllers() {
    if (_unit == UnitSystem.metric) {
      _weightCtrl.text = _weightKg.toStringAsFixed(1);
      _heightCmCtrl.text = _heightCm.round().toString();
    } else {
      _weightCtrl.text = UnitConvert.kgToLb(_weightKg).round().toString();
      final (ft, inch) = UnitConvert.cmToFeetInches(_heightCm);
      _feetCtrl.text = ft.toString();
      _inchCtrl.text = inch.toString();
    }
  }

  /// Read controllers → canonical (live, while typing). Does not rewrite the
  /// text (so the cursor doesn't jump); just keeps BMI in sync.
  void _readToCanonical() {
    if (_unit == UnitSystem.metric) {
      final kg = double.tryParse(_weightCtrl.text) ?? 0;
      final cm = double.tryParse(_heightCmCtrl.text) ?? 0;
      _weightKg = kg.clamp(_minKg, _maxKg);
      _heightCm = cm.clamp(_minCm, _maxCm);
    } else {
      final lb = double.tryParse(_weightCtrl.text) ?? 0;
      final ft = int.tryParse(_feetCtrl.text) ?? 0;
      final inch = double.tryParse(_inchCtrl.text) ?? 0;
      _weightKg = UnitConvert.lbToKg(lb).clamp(_minKg, _maxKg);
      _heightCm = UnitConvert.feetInchesToCm(ft, inch.round()).clamp(_minCm, _maxCm);
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
    HapticFeedback.mediumImpact();
    widget.onComplete(UserProfile(
      name: widget.name,
      email: widget.email,
      weightKg: double.parse(_weightKg.toStringAsFixed(1)),
      heightCm: _heightCm.roundToDouble(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final profile = UserProfile(
      name: widget.name, email: widget.email,
      weightKg: _weightKg, heightCm: _heightCm,
    );

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
                  ),
                  Text('Change anytime', style: TextStyle(fontSize: 12, color: c.ink3)),
                ],
              ),
              const SizedBox(height: 24),

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
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const _MeasureField({
    required this.controller,
    required this.unit,
    required this.allowDecimal,
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
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
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
