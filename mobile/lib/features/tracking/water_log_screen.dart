import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/haptics.dart';
import '../../app/nutri_colors.dart';
import '../../db/daily_log.dart';
import '../../ui/section_header.dart';
import '../../ui/warm_card.dart';
import '../../ui/water_glasses.dart';

class WaterLogScreen extends StatefulWidget {
  final DailyLogStore store;

  const WaterLogScreen({super.key, required this.store});

  @override
  State<WaterLogScreen> createState() => _WaterLogScreenState();
}

class _WaterLogScreenState extends State<WaterLogScreen> {
  bool _logging = false;

  Future<void> _log(int ml) async {
    if (_logging) return;
    setState(() => _logging = true);
    Haptics.mediumImpact();
    await widget.store.logWater(ml);
    if (mounted) setState(() => _logging = false);
  }

  Future<void> _logCustom(DailyLog log) async {
    final c = context.nutri;
    final controller = TextEditingController();
    final ml = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Custom amount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            suffixText: 'ml',
            hintText: '350',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
    if (ml != null) await _log(ml);
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
        title: const Text('Water'),
      ),
      body: ValueListenableBuilder<DailyLog>(
        valueListenable: widget.store.todayListenable,
        builder: (context, log, _) {
          final cur  = log.consumedWaterMl;
          final goal = log.goalWaterMl;
          final pct  = goal > 0 ? ((cur / goal) * 100).clamp(0, 100).round() : 0;

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
                        NutriOverline("Today's intake"),
                        Icon(Icons.water_drop, color: c.water, size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 36, height: 1),
                        children: [
                          TextSpan(text: (cur / 1000).toStringAsFixed(2)),
                          TextSpan(
                            text: ' / ${(goal / 1000).toStringAsFixed(1)} L',
                            style: TextStyle(fontSize: 16, color: c.ink2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    WaterGlasses(currentMl: cur, goalMl: goal),
                    const SizedBox(height: 8),
                    Text(
                      '$pct% of daily goal',
                      style: TextStyle(fontSize: 12, color: c.ink2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              NutriOverline('Quick add'),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final ml in [250, 500, 750, 1000]) ...[
                    Expanded(
                      child: _QuickAddButton(
                        ml: ml,
                        color: c.water,
                        bg: c.waterSoft,
                        loading: _logging,
                        onTap: () => _log(ml),
                      ),
                    ),
                    if (ml != 1000) const SizedBox(width: 10),
                  ],
                ],
              ),

              const SizedBox(height: 14),
              NutriOverline('Quick remove'),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final ml in [250, 500, 750, 1000]) ...[
                    Expanded(
                      child: _QuickAddButton(
                        ml: ml,
                        color: c.water,
                        bg: c.waterSoft,
                        loading: _logging,
                        subtract: true,
                        disabled: cur <= 0,
                        onTap: () => _log(-ml),
                      ),
                    ),
                    if (ml != 1000) const SizedBox(width: 10),
                  ],
                ],
              ),

              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _logging ? null : () => _logCustom(log),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Custom amount'),
              ),

              if (cur == 0) ...[
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'No water logged today yet.\nTap a button above to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.ink2, height: 1.6),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final int ml;
  final Color color;
  final Color bg;
  final bool loading;
  final bool subtract;
  final bool disabled;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.ml,
    required this.color,
    required this.bg,
    required this.loading,
    required this.onTap,
    this.subtract = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final blocked = loading || disabled;
    final label = ml >= 1000 ? '${ml ~/ 1000}L' : '${ml}ml';
    return Opacity(
      opacity: disabled ? 0.35 : 1.0,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: blocked ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(subtract ? Icons.remove : Icons.water_drop, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  subtract ? '−$label' : label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
