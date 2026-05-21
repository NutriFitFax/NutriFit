import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../../features/history/viewed_food_history_store.dart';
import 'meal_results_screen.dart';

class MealPreviewScreen extends StatefulWidget {
  final XFile image;
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;

  const MealPreviewScreen({super.key, required this.image, required this.api, required this.history});

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
      final estimateFuture = widget.api.estimateMeal(
        bytes,
        filename: widget.image.name,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MealResultsScreen(estimateFuture: estimateFuture, history: widget.history),
        ),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.file(
              File(widget.image.path),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _analyzing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _analyzing ? null : _analyze,
                    child: const Text('Analyse'),
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
