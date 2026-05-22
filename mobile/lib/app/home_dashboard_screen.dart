import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/history/viewed_food_history_store.dart';
import '../screens/food_detail_screen.dart';
import '../ui/calorie_ring.dart';
import '../ui/food_tile.dart';
import '../ui/macro_bar.dart';
import '../ui/section_header.dart';
import '../ui/warm_card.dart';
import '../ui/water_glasses.dart';
import 'app_shell.dart' show AppTabId;
import 'nutri_colors.dart';

// ─────────────────────────────────────────────────────────────────────────
// PLACEHOLDER DAILY TOTALS
//
// TODO: replace these constants with a real DailyLogStore once the
// SQLite layer ships. The widget tree below already isolates every value
// so swapping in real ValueListenable<DailyLog> here is a one-line change.
// ─────────────────────────────────────────────────────────────────────────
class _DailyPlaceholders {
  static const goalCalories = 2150.0;
  static const goalProteinG = 130.0;
  static const goalCarbsG   = 240.0;
  static const goalFatG     = 70.0;
  static const goalWaterMl  = 2500;

  static const consumedCalories = 1292.0;
  static const consumedProteinG = 79.0;
  static const consumedCarbsG   = 140.0;
  static const consumedFatG     = 41.0;
  static const consumedWaterMl  = 1200;

  static const todaysMeals = <_MealLog>[
    _MealLog(time: '07:42', name: 'Greek yogurt, granola & blueberries', kcal: 412),
    _MealLog(time: '10:15', name: 'Organic peanut butter on rye',        kcal: 268),
    _MealLog(time: '13:08', name: 'Grilled chicken, rice & broccoli',    kcal: 612),
  ];

  static const weightKg      = 74.2;
  static const heightCm      = 181.0;
  static const weightTrendKg = <double>[75.1, 74.9, 74.8, 75.0, 74.7, 74.5, 74.4, 74.2];
}

class _MealLog {
  final String time, name;
  final int kcal;
  const _MealLog({required this.time, required this.name, required this.kcal});
}

class HomeDashboardScreen extends StatelessWidget {
  final ViewedFoodHistoryStore history;
  final void Function(AppTabId tab) onOpenTab;

  const HomeDashboardScreen({
    super.key,
    required this.history,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final bmi = _DailyPlaceholders.weightKg /
        ((_DailyPlaceholders.heightCm / 100) * (_DailyPlaceholders.heightCm / 100));

    return Scaffold(
      backgroundColor: c.bg,
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          slivers: [
            // Greeting
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TUESDAY · MAY 21',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: c.ink2, letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26, height: 1.1),
                              children: [
                                const TextSpan(text: 'Good afternoon, '),
                                TextSpan(
                                  text: 'friend',
                                  style: TextStyle(
                                    color: c.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44, height: 44,
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
                        'B',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: c.primaryDeep, fontSize: 18, fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card 1 — Calories + macros + today's meals
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              sliver: SliverToBoxAdapter(
                child: _CaloriesCard(c: c),
              ),
            ),

            // Card 2 — Water / Weight
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(child: _WaterCard(onTap: () {})),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WeightCard(
                        weightKg: _DailyPlaceholders.weightKg,
                        bmi: bmi,
                        trend: _DailyPlaceholders.weightTrendKg,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card 3 — Quick log
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              sliver: SliverToBoxAdapter(
                child: WarmCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NutriOverline('Log a meal'),
                            Text('Pick a way', style: TextStyle(fontSize: 11, color: c.ink3)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Row(
                          children: [
                            Expanded(child: _QuickAction(
                              icon: Icons.camera_alt_outlined,
                              label: 'Photo',
                              bg: c.primarySoft,
                              fg: c.primaryDeep,
                              onTap: () => onOpenTab(AppTabId.meal),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _QuickAction(
                              icon: Icons.qr_code_scanner,
                              label: 'Scan',
                              bg: c.proteinSoft,
                              fg: c.protein,
                              onTap: () => onOpenTab(AppTabId.barcode),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _QuickAction(
                              icon: Icons.search,
                              label: 'Search',
                              bg: c.carbsSoft,
                              fg: const Color(0xFF7A5A1C),
                              onTap: () => onOpenTab(AppTabId.search),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Recent header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Recent',
                  trailing: SeeAllLink(onTap: () => onOpenTab(AppTabId.history)),
                ),
              ),
            ),

            // Recent list (from history store, take first 3)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              sliver: ValueListenableBuilder<List<ViewedFoodEntry>>(
                valueListenable: history.entriesListenable,
                builder: (context, entries, _) {
                  if (entries.isEmpty) {
                    return SliverToBoxAdapter(
                      child: WarmCard(
                        child: Text(
                          'Foods you view will show up here.',
                          style: TextStyle(color: c.ink2, fontSize: 13),
                        ),
                      ),
                    );
                  }
                  final shown = entries.take(3).toList(growable: false);
                  return SliverList.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final entry = shown[i];
                      return FoodTile(
                        name: entry.name,
                        subtitle: entry.brand,
                        macrosPer100g: entry.food.macrosPer100g,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FoodDetailScreen(
                                food: entry.food,
                                history: history,
                                sourceLabel: 'home',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Calories card ────────────────────────────────
class _CaloriesCard extends StatelessWidget {
  final NutriColors c;
  const _CaloriesCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final p = _DailyPlaceholders.consumedCalories;
    return WarmCard(
      padding: EdgeInsets.zero,
      elevated: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NutriOverline("Today's energy"),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.titleLarge,
                          children: [
                            TextSpan(text: p.toStringAsFixed(0)),
                            TextSpan(
                              text: ' / ${_DailyPlaceholders.goalCalories.toStringAsFixed(0)} kcal',
                              style: TextStyle(fontSize: 15, color: c.ink3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _Chip(label: 'ON TRACK', bg: c.primarySoft, fg: c.primaryDeep, icon: Icons.local_fire_department),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
            child: Row(
              children: [
                CalorieRing(
                  value: p,
                  goal: _DailyPlaceholders.goalCalories,
                  size: 148,
                  stroke: 11,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: MacroStack(
                    protein: _DailyPlaceholders.consumedProteinG,
                    carbs:   _DailyPlaceholders.consumedCarbsG,
                    fat:     _DailyPlaceholders.consumedFatG,
                    proteinGoal: _DailyPlaceholders.goalProteinG,
                    carbsGoal:   _DailyPlaceholders.goalCarbsG,
                    fatGoal:     _DailyPlaceholders.goalFatG,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line, width: 1)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NutriOverline("Today's meals"),
                    Text(
                      '${_DailyPlaceholders.todaysMeals.length} logged',
                      style: TextStyle(fontSize: 12, color: c.ink3),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final m in _DailyPlaceholders.todaysMeals)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 42,
                          child: Text(
                            m.time,
                            style: TextStyle(fontSize: 12, color: c.ink2),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${m.kcal}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: ' kcal', style: TextStyle(fontSize: 11, color: c.ink3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Water card ─────────────────────────────────
class _WaterCard extends StatelessWidget {
  final VoidCallback onTap;
  const _WaterCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final cur = _DailyPlaceholders.consumedWaterMl;
    final goal = _DailyPlaceholders.goalWaterMl;
    final pct = ((cur / goal) * 100).round();

    return WarmCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NutriOverline('Water'),
              Icon(Icons.water_drop_outlined, color: c.water, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
              children: [
                TextSpan(text: (cur / 1000).toStringAsFixed(1)),
                TextSpan(
                  text: ' / ${(goal / 1000).toStringAsFixed(1)} L',
                  style: TextStyle(fontSize: 12, color: c.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          WaterGlasses(currentMl: cur, goalMl: goal),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('+ Log', style: TextStyle(color: c.water, fontWeight: FontWeight.w700, fontSize: 11)),
              const SizedBox(width: 6),
              Text('· $pct% of goal', style: TextStyle(fontSize: 11, color: c.ink2)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Weight card ────────────────────────────────
class _WeightCard extends StatelessWidget {
  final double weightKg;
  final double bmi;
  final List<double> trend;
  final VoidCallback onTap;
  const _WeightCard({
    required this.weightKg,
    required this.bmi,
    required this.trend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return WarmCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NutriOverline('Weight'),
              Icon(Icons.monitor_weight_outlined, color: c.protein, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
              children: [
                TextSpan(text: weightKg.toStringAsFixed(1)),
                TextSpan(text: ' kg', style: TextStyle(fontSize: 12, color: c.ink2)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparkPainter(values: trend, color: c.protein),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(
                children: [
                  TextSpan(text: 'BMI ', style: TextStyle(fontSize: 11, color: c.ink2)),
                  TextSpan(
                    text: bmi.toStringAsFixed(1),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                ],
              )),
              Text('Normal',
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1 : (maxV - minV);

    final stepX = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    final last = Offset(
      (values.length - 1) * stepX,
      size.height - ((values.last - minV) / range) * size.height,
    );
    canvas.drawCircle(last, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
}

// ────────────────────────── Quick action button ─────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────── Chip ────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const _Chip({required this.label, required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}
