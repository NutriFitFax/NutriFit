import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../app/haptics.dart';
import '../../api/models.dart';
import '../../app/nutri_colors.dart';
import '../../db/daily_log.dart';
import '../../features/history/viewed_food_history_store.dart';
import '../../screens/food_detail_screen.dart';
import '../../ui/food_view_data.dart';
import 'widgets/food_item_card.dart';
import 'widgets/meal_totals_footer.dart';

class MealResultsScreen extends StatefulWidget {
  final Future<MealEstimate> estimateFuture;
  final ViewedFoodHistoryStore history;
  final DailyLogStore store;

  const MealResultsScreen({
    super.key,
    required this.estimateFuture,
    required this.history,
    required this.store,
  });

  @override
  State<MealResultsScreen> createState() => _MealResultsScreenState();
}

class _MealResultsScreenState extends State<MealResultsScreen> {
  MealEstimate? _estimate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await widget.estimateFuture;
      if (mounted) setState(() => _estimate = r);
    } on BadRequestException {
      _setError('Image format not supported. Try a JPG or PNG photo.');
    } on NetworkException {
      _setError('No internet connection or server unreachable. Try again.');
    } on TimeoutException {
      _setError('Taking longer than usual. Go back and try again.');
    } on UpstreamException {
      _setError('Service is having trouble. Go back and try again.');
    } on ApiException {
      _setError('Something went wrong. Go back and try again.');
    }
  }

  void _setError(String m) {
    if (mounted) setState(() => _error = m);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _estimate == null && _error == null ? 'STEP 3 OF 3' : 'RESULT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.ink2, letterSpacing: 0.8),
            ),
            Text(
              _estimate == null && _error == null
                  ? 'Analyzing…'
                  : (_error != null ? 'Couldn\'t analyze' : 'Identified foods'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24, height: 1.1),
            ),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) return _ErrorView(message: _error!);
    if (_estimate == null) return const _AnalyzingView();
    if (_estimate!.items.isEmpty) return const _NoFoodView();

    final e = _estimate!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            children: [
              for (var i = 0; i < e.items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FoodItemCard(
                    item: e.items[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(
                          food: FoodViewData.fromEstimatedFood(e.items[i]),
                          history: widget.history,
                          sourceLabel: 'Meal Photo',
                          onLog: (grams) {
                            final item = e.items[i];
                            final m = item.macrosPer100g.forGrams(grams);
                            return widget.store.logMeal(
                              name: item.name,
                              caloriesKcal: m.caloriesKcal,
                              proteinG: m.proteinG,
                              carbsG: m.carbsG,
                              fatG: m.fatG,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        MealTotalsFooter(estimate: e, store: widget.store),
      ],
    );
  }
}

// ───────────────────────── "Reading your plate" view ────────────────────
class _AnalyzingView extends StatefulWidget {
  const _AnalyzingView();
  @override
  State<_AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends State<_AnalyzingView> {
  static const _steps = <String>[
    'Uploading photo…',
    'Identifying foods…',
    'Estimating portions…',
    'Matching to USDA database…',
  ];
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1).clamp(0, _steps.length - 1));
    });
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Center(
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(color: c.primaryTint, shape: BoxShape.circle),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 152, height: 152,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                    backgroundColor: c.primary.withValues(alpha: 0.15),
                  ),
                ),
                Icon(Icons.auto_awesome, color: c.primary, size: 48),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            'Reading your plate',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: i == _i ? c.primaryTint : c.surface,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _StepIcon(state: i < _i ? _StepState.done : (i == _i ? _StepState.active : _StepState.pending)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _steps[i],
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: i == _i ? FontWeight.w600 : FontWeight.w500,
                        color: i > _i ? c.ink2 : c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

enum _StepState { pending, active, done }

class _StepIcon extends StatelessWidget {
  final _StepState state;
  const _StepIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    const size = 22.0;
    switch (state) {
      case _StepState.done:
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      case _StepState.active:
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
          ),
        );
      case _StepState.pending:
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(color: c.line, shape: BoxShape.circle),
        );
    }
  }
}

// ──────────────────────────────── Error / empty ─────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: c.warn),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.ink, fontSize: 15)),
            const SizedBox(height: 24),
            FilledButton(onPressed: () { Haptics.selectionClick(); Navigator.of(context).pop(); }, child: const Text('Go back')),
          ],
        ),
      ),
    );
  }
}

class _NoFoodView extends StatelessWidget {
  const _NoFoodView();

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_food_outlined, size: 56, color: c.ink2),
            const SizedBox(height: 16),
            const Text(
              'No food detected. Try a clearer, well-lit photo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () { Haptics.selectionClick(); Navigator.of(context).pop(); }, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
