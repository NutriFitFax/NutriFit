import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
import '../../screens/food_detail_screen.dart';
import '../../ui/section_header.dart';
import '../../ui/status_views.dart';
import 'viewed_food_history_store.dart';

/// History list, day-grouped, with optional source-label filtering.
class HistoryScreen extends StatefulWidget {
  final ViewedFoodHistoryStore history;
  const HistoryScreen({super.key, required this.history});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// `null` = All. Otherwise matches against `entry.sourceLabel` substring.
  String? _filter;

  static const _filters = <_FilterDef>[
    _FilterDef(id: null,        label: 'All'),
    _FilterDef(id: 'meal',      label: 'Photo'),
    _FilterDef(id: 'barcode',   label: 'Scanned'),
    _FilterDef(id: 'search',    label: 'Searched'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: ValueListenableBuilder<List<ViewedFoodEntry>>(
          valueListenable: widget.history.entriesListenable,
          builder: (context, entries, _) {
            final filtered = _filter == null
                ? entries
                : entries
                    .where((e) => e.sourceLabel
                        .toLowerCase()
                        .contains(_filter!.toLowerCase()))
                    .toList(growable: false);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Title row
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entries.length} ITEMS',
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: c.ink2, letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'History',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Clear history',
                          onPressed: entries.isEmpty ? null : () => widget.history.clear(),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter chips
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final f = _filters[i];
                          final active = _filter == f.id;
                          return ChoiceChip(
                            label: Text(f.label),
                            selected: active,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _filter = f.id);
                            },
                            selectedColor: c.primary,
                            backgroundColor: c.surface,
                            side: BorderSide(color: active ? c.primary : c.line),
                            labelStyle: TextStyle(
                              color: active ? const Color(0xFFFDFAF0) : c.ink,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.history,
                      title: 'No viewed foods yet',
                      message: 'Foods you open from search, scans, or meals appear here.',
                    ),
                  )
                else
                  ..._buildGroups(filtered, c, context),

                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildGroups(
      List<ViewedFoodEntry> entries, NutriColors c, BuildContext context) {
    final groups = <String, List<ViewedFoodEntry>>{};
    for (final e in entries) {
      groups.putIfAbsent(_dayLabel(e.viewedAt), () => []).add(e);
    }

    final widgets = <Widget>[];
    groups.forEach((day, items) {
      final totalKcal = items.fold<double>(0, (a, b) => a + b.food.macrosPer100g.caloriesKcal);
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: day,
              trailing: Text(
                '${totalKcal.toStringAsFixed(0)} kcal · ${items.length} items',
                style: TextStyle(fontSize: 12, color: c.ink3),
              ),
            ),
          ),
        ),
      );
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(color: c.line, height: 1),
            itemBuilder: (_, i) => _HistoryRow(
              entry: items[i],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FoodDetailScreen(
                      food: items[i].food,
                      history: widget.history,
                      sourceLabel: 'history',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
    return widgets;
  }

  static String _dayLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(t.year, t.month, t.day);
    final diff  = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return '$diff days ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

class _FilterDef {
  final String? id;
  final String label;
  const _FilterDef({required this.id, required this.label});
}

class _HistoryRow extends StatelessWidget {
  final ViewedFoodEntry entry;
  final VoidCallback onTap;
  const _HistoryRow({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final kcalPer100 = entry.food.macrosPer100g.caloriesKcal;
    final source = entry.sourceLabel.toLowerCase();
    final IconData icon;
    final Color iconColor;
    if (source.contains('barcode')) {
      icon = Icons.qr_code_scanner;
      iconColor = c.protein;
    } else if (source.contains('meal') || source.contains('photo') || source.contains('image')) {
      icon = Icons.camera_alt_outlined;
      iconColor = c.primary;
    } else {
      icon = Icons.search;
      iconColor = c.carbs;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_timeLabel(entry.viewedAt)} · ${entry.sourceLabel}',
                    style: TextStyle(fontSize: 11.5, color: c.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  kcalPer100.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14.5),
                ),
                Text('kcal/100g', style: TextStyle(fontSize: 10, color: c.ink3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _timeLabel(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
