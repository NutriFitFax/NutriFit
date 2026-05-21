import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../../app/nutri_colors.dart';
import '../../features/history/viewed_food_history_store.dart';
import 'meal_results_screen.dart';

class MealPreviewScreen extends StatefulWidget {
  final XFile image;
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const MealPreviewScreen({
    super.key,
    required this.image,
    required this.api,
    required this.history,
  });

  @override
  State<MealPreviewScreen> createState() => _MealPreviewScreenState();
}

class _MealPreviewScreenState extends State<MealPreviewScreen> {
  bool _analyzing = false;

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    try {
      final bytes = await widget.image.readAsBytes();
      if (!mounted) return;
      final estimateFuture = widget.api.estimateMeal(bytes, filename: widget.image.name);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MealResultsScreen(
            estimateFuture: estimateFuture,
            history: widget.history,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _analyzing ? null : () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEP 2 OF 3',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.ink2, letterSpacing: 0.8),
            ),
            Text('Confirm photo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24, height: 1.1),
            ),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(widget.image.path), fit: BoxFit.cover),
                      Positioned(
                        bottom: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.ink.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_outlined, color: Colors.white, size: 12),
                              SizedBox(width: 6),
                              Text(
                                'Just now',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Looks good? We'll send this to our AI to identify foods and estimate portion sizes.",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, height: 1.3),
            ),
            const SizedBox(height: 6),
            Text(
              "Takes about 3–5 seconds. Your photo isn't saved to our servers.",
              style: TextStyle(fontSize: 12.5, color: c.ink2),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _analyzing ? null : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _analyzing ? null : _analyze,
                    icon: _analyzing
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_analyzing ? 'Analyzing…' : 'Analyze meal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
