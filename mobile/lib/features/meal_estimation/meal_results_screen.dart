import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../api/api_exception.dart';
import '../../api/models.dart';
import '../../features/history/viewed_food_history_store.dart';
import '../../screens/food_detail_screen.dart';
import '../../ui/food_view_data.dart';
import 'widgets/food_item_card.dart';
import 'widgets/meal_totals_footer.dart';

class MealResultsScreen extends StatefulWidget {
  final Future<MealEstimate> estimateFuture;
  final ViewedFoodHistoryStore history;

  const MealResultsScreen({
    super.key,
    required this.estimateFuture,
    required this.history,
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
      final estimate = await widget.estimateFuture;
      if (mounted) setState(() => _estimate = estimate);
    } on BadRequestException {
      if (mounted) {
        setState(() => _error = 'Image format not supported. Try a JPG or PNG photo.');
      }
    } on NetworkException {
      if (mounted) {
        setState(() => _error = 'No internet connection or server unreachable. Try again.');
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'Taking longer than usual. Go back and try again.');
      }
    } on UpstreamException {
      if (mounted) {
        setState(() => _error = 'Service is having trouble. Go back and try again.');
      }
    } on ApiException {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Go back and try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Analysis')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 56, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_estimate == null) {
      return _buildShimmer(context);
    }

    if (_estimate!.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_food_outlined, size: 56),
              const SizedBox(height: 16),
              const Text(
                'No food detected. Try a clearer, well-lit photo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: _estimate!.items.length,
            itemBuilder: (context, i) {
              final item = _estimate!.items[i];
              return FoodItemCard(
                item: item,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FoodDetailScreen(
                      food: FoodViewData.fromEstimatedFood(item),
                      history: widget.history,
                      sourceLabel: 'Meal Photo',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        MealTotalsFooter(estimate: _estimate!),
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade500 : Colors.grey.shade100;

    return Column(
      children: [
        Expanded(
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: 3,
              itemBuilder: (_, __) => const _SkeletonCard(),
            ),
          ),
        ),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: const _SkeletonFooter(),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  static Widget _box(double w, double h, {double radius = 4}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(160, 16),
                const Spacer(),
                _box(64, 20, radius: 10),
              ],
            ),
            const SizedBox(height: 8),
            _box(56, 12),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (_) => _box(52, 28)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonFooter extends StatelessWidget {
  const _SkeletonFooter();

  static Widget _box(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _box(64, 12),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _box(80, 22),
                _box(56, 18),
                _box(56, 18),
                _box(56, 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
