import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
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
  String? _error;

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _error = null;
    });
    try {
      final bytes = await widget.image.readAsBytes();
      final estimate = await widget.api.estimateMeal(
        bytes,
        filename: widget.image.name,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MealResultsScreen(estimate: estimate, history: widget.history),
        ),
      );
    } on BadRequestException {
      if (mounted) {
        setState(() =>
            _error = 'Image format not supported. Try a JPG or PNG photo.');
      }
    } on NetworkException {
      if (mounted) {
        setState(() =>
            _error = 'No internet connection. Reconnect and tap to retry.');
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'Taking longer than usual. Tap to retry.');
      }
    } on UpstreamException {
      if (mounted) {
        setState(() => _error = 'Service is having trouble. Tap to retry.');
      }
    } on ApiException {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Tap to retry.');
      }
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.image.path),
                  fit: BoxFit.cover,
                ),
                if (_analyzing)
                  Container(
                    color: Colors.black54,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Analysing your meal…',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'This usually takes 3–5 seconds',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
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
