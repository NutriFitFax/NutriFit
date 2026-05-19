import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../shared/permission_helper.dart';
import 'meal_preview_screen.dart';

class MealEntryScreen extends StatelessWidget {
  final NutriFitApi api;
  const MealEntryScreen({super.key, required this.api});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      final granted = await PermissionHelper.requestCamera(context);
      if (!granted) return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealPreviewScreen(image: file, api: api),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal estimator')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Take a photo of your meal or choose one from your gallery.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => _pick(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take photo'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pick(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from gallery'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
