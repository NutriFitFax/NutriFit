import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/haptics.dart';
import '../../app/nutri_colors.dart';
import '../../app/settings_prefs.dart';
import '../../db/daily_log.dart';
import '../../features/auth/user_profile.dart';
import '../../ui/section_header.dart';
import '../../ui/warm_card.dart';

class WeightLogScreen extends StatefulWidget {
  final DailyLogStore store;

  const WeightLogScreen({super.key, required this.store});

  @override
  State<WeightLogScreen> createState() => _WeightLogScreenState();
}

class _WeightLogScreenState extends State<WeightLogScreen> {
  final _controller = TextEditingController();
  bool _logging = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    final unit = SettingsPrefs.instance.unit;
    final raw = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (raw == null || raw <= 0) return;
    final kg = unit == UnitSystem.imperial ? UnitConvert.lbToKg(raw) : raw;

    setState(() => _logging = true);
    Haptics.mediumImpact();
    await widget.store.logWeight(kg);
    await SettingsPrefs.instance.setWeightKg(kg);
    if (mounted) {
      _controller.clear();
      setState(() => _logging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weight logged: ${raw.toStringAsFixed(1)} ${unit == UnitSystem.imperial ? 'lb' : 'kg'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c    = context.nutri;
    final unit = SettingsPrefs.instance.unit;
    final unitLabel = unit == UnitSystem.imperial ? 'lb' : 'kg';

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Weight'),
      ),
      body: ValueListenableBuilder<DailyLog>(
        valueListenable: widget.store.todayListenable,
        builder: (context, log, _) {
          final weightKg   = log.latestWeightKg;
          final bmi        = log.bmi;
          final trend      = log.weightTrend;
          final displayVal = _displayWeight(weightKg, unit);

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              WarmCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        NutriOverline('Current weight'),
                        Icon(Icons.monitor_weight_outlined, color: c.protein, size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    weightKg == null
                        ? Text(
                            'No weight logged yet',
                            style: TextStyle(fontSize: 18, color: c.ink2),
                          )
                        : Text.rich(
                            TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 36, height: 1),
                              children: [
                                TextSpan(text: displayVal),
                                TextSpan(
                                  text: ' $unitLabel',
                                  style: TextStyle(fontSize: 16, color: c.ink2),
                                ),
                              ],
                            ),
                          ),
                    if (bmi != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'BMI ${bmi.toStringAsFixed(1)} · ${_bmiLabel(bmi)}',
                        style: TextStyle(fontSize: 13, color: c.ink2),
                      ),
                    ],
                    if (trend.length >= 2) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 48,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _SparkPainter(values: trend, color: c.protein),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last ${trend.length} entries',
                        style: TextStyle(fontSize: 11, color: c.ink3),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 22),
              NutriOverline('Log today\'s weight'),
              const SizedBox(height: 10),
              WarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      decoration: InputDecoration(
                        hintText: weightKg != null ? displayVal : (unit == UnitSystem.imperial ? '165.0' : '75.0'),
                        suffixText: unitLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _logging ? null : _log,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Log weight'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _displayWeight(double? kg, UnitSystem unit) {
    if (kg == null) return '--';
    if (unit == UnitSystem.imperial) return UnitConvert.kgToLb(kg).toStringAsFixed(1);
    return kg.toStringAsFixed(1);
  }

  static String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV  = values.reduce((a, b) => a < b ? a : b);
    final maxV  = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    final stepX = size.width / (values.length - 1);
    final path  = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color       = color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round,
    );
    final last = Offset(
      (values.length - 1) * stepX,
      size.height - ((values.last - minV) / range) * size.height,
    );
    canvas.drawCircle(last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color;
}
