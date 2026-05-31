import 'package:flutter/material.dart';
import 'haptics.dart';

import '../db/daily_log.dart';
import '../features/history/viewed_food_history_store.dart';
import '../features/tracking/water_log_screen.dart';
import '../features/tracking/weight_log_screen.dart';
import '../screens/food_detail_screen.dart';
import 'settings_prefs.dart';
import '../ui/calorie_ring.dart';
import '../ui/food_tile.dart';
import '../ui/macro_bar.dart';
import '../ui/section_header.dart';
import '../ui/warm_card.dart';
import '../ui/water_glasses.dart';
import 'app_shell.dart' show AppTabId;
import 'nutri_colors.dart';

class HomeDashboardScreen extends StatelessWidget {
  final DailyLogStore store;
  final ViewedFoodHistoryStore history;
  final void Function(AppTabId tab) onOpenTab;
  final VoidCallback? onOpenSettings;

  const HomeDashboardScreen({
    super.key,
    required this.store,
    required this.history,
    required this.onOpenTab,
    this.onOpenSettings,
  });

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _dateLabel() {
    final now = DateTime.now();
    const days   = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${days[now.weekday - 1]} · ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final c    = context.nutri;
    final name = SettingsPrefs.instance.displayName;
    final avatarLetter =
        name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

    return Scaffold(
      backgroundColor: c.bg,
      body: ValueListenableBuilder<DailyLog>(
        valueListenable: store.todayListenable,
        builder: (context, log, _) {
          return RefreshIndicator(
            color: c.primary,
            onRefresh: () async {
              Haptics.mediumImpact();
              await store.refresh();
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
                                _dateLabel(),
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
                                    TextSpan(text: '${_greeting()}, '),
                                    TextSpan(
                                      text: name,
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
                        GestureDetector(
                          onTap: onOpenSettings,
                          child: Container(
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
                              avatarLetter,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: c.primaryDeep, fontSize: 18, fontWeight: FontWeight.w600,
                                  ),
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
                    child: _CaloriesCard(c: c, log: log),
                  ),
                ),

                // Card 2 — Water / Weight
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _WaterCard(
                            currentMl: log.consumedWaterMl,
                            goalMl: log.goalWaterMl,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WaterLogScreen(store: store),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _WeightCard(
                            weightKg: log.latestWeightKg,
                            bmi: log.bmi,
                            trend: log.weightTrend,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WeightLogScreen(store: store),
                              ),
                            ),
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
          );
        },
      ),
    );
  }
}

// ───────────────────────── Calories card ────────────────────────────────
class _CaloriesCard extends StatelessWidget {
  final NutriColors c;
  final DailyLog log;
  const _CaloriesCard({required this.c, required this.log});

  @override
  Widget build(BuildContext context) {
    final consumed = log.consumedCalories;
    final goal     = log.goalCalories;
    final status   = log.statusLabel;

    final statusBg = status == 'OVER GOAL'
        ? c.warn.withValues(alpha: 0.15)
        : c.primarySoft;
    final statusFg = status == 'OVER GOAL' ? c.warn : c.primaryDeep;

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
                            TextSpan(text: consumed.toStringAsFixed(0)),
                            TextSpan(
                              text: ' / ${goal.toStringAsFixed(0)} kcal',
                              style: TextStyle(fontSize: 15, color: c.ink3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _Chip(label: status, bg: statusBg, fg: statusFg, icon: Icons.local_fire_department),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
            child: Row(
              children: [
                CalorieRing(
                  value: consumed,
                  goal: goal,
                  size: 148,
                  stroke: 11,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: MacroStack(
                    protein:     log.consumedProteinG,
                    carbs:       log.consumedCarbsG,
                    fat:         log.consumedFatG,
                    proteinGoal: log.goalProteinG,
                    carbsGoal:   log.goalCarbsG,
                    fatGoal:     log.goalFatG,
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
                      '${log.meals.length} logged',
                      style: TextStyle(fontSize: 12, color: c.ink3),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (log.meals.isEmpty)
                  Text(
                    'No meals logged yet. Use Photo, Scan, or Search to add one.',
                    style: TextStyle(fontSize: 13, color: c.ink2, height: 1.5),
                  )
                else
                  for (final m in log.meals)
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
  final int currentMl;
  final int goalMl;
  final VoidCallback onTap;

  const _WaterCard({
    required this.currentMl,
    required this.goalMl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c   = context.nutri;
    final pct = goalMl > 0 ? ((currentMl / goalMl) * 100).round() : 0;

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
                TextSpan(text: (currentMl / 1000).toStringAsFixed(1)),
                TextSpan(
                  text: ' / ${(goalMl / 1000).toStringAsFixed(1)} L',
                  style: TextStyle(fontSize: 12, color: c.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          WaterGlasses(currentMl: currentMl, goalMl: goalMl),
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
  final double? weightKg;
  final double? bmi;
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
          weightKg == null
              ? Text(
                  'Tap to log',
                  style: TextStyle(fontSize: 18, color: c.ink2, fontWeight: FontWeight.w500),
                )
              : Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
                    children: [
                      TextSpan(text: weightKg!.toStringAsFixed(1)),
                      TextSpan(text: ' kg', style: TextStyle(fontSize: 12, color: c.ink2)),
                    ],
                  ),
                ),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: trend.length >= 2
                ? CustomPaint(
                    size: Size.infinite,
                    painter: _SparkPainter(values: trend, color: c.protein),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (bmi != null)
                Text.rich(TextSpan(
                  children: [
                    TextSpan(text: 'BMI ', style: TextStyle(fontSize: 11, color: c.ink2)),
                    TextSpan(
                      text: bmi!.toStringAsFixed(1),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.ink),
                    ),
                  ],
                ))
              else
                Text('+ Log', style: TextStyle(color: c.protein, fontWeight: FontWeight.w700, fontSize: 11)),
              if (bmi != null)
                Text(
                  _bmiLabel(bmi!),
                  style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
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
        ..strokeWidth = 1.8
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round,
    );
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
        onTap: () { Haptics.selectionClick(); onTap(); },
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
