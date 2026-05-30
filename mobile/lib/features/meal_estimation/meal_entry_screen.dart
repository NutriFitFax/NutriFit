import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/haptics.dart';

import '../../api/api_client.dart';
import '../../app/nutri_colors.dart';
import '../../features/history/viewed_food_history_store.dart';
import '../shared/permission_helper.dart';
import 'meal_preview_screen.dart';

class MealEntryScreen extends StatelessWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;
  const MealEntryScreen({super.key, required this.api, required this.history});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    Haptics.selectionClick();
    if (source == ImageSource.camera) {
      final granted = await PermissionHelper.requestCamera(context);
      if (!granted) return;
    }
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MealPreviewScreen(image: file, api: api, history: history),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          // Heading
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-POWERED ESTIMATE',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: c.ink2, letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Meal photo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
                ),
              ],
            ),
          ),

          // Hero "how it works"
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [c.primary, c.primaryDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: c.ink.withValues(alpha: 0.06),
                  blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            alignment: Alignment.bottomLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'HOW IT WORKS',
                  style: TextStyle(
                    color: Color(0xCCFDFAF0),
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Snap your plate. We'll identify foods, estimate portions, and total your macros.",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFFFDFAF0), fontSize: 22, height: 1.2,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _ActionRow(
            icon: Icons.camera_alt_outlined,
            iconBg: c.primarySoft,
            iconFg: c.primaryDeep,
            title: 'Take a photo',
            subtitle: 'Use your camera now',
            onTap: () => _pick(context, ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _ActionRow(
            icon: Icons.photo_library_outlined,
            iconBg: c.carbsSoft,
            iconFg: const Color(0xFF7A5A1C),
            title: 'Choose from gallery',
            subtitle: 'Use an existing photo',
            onTap: () => _pick(context, ImageSource.gallery),
          ),

          const SizedBox(height: 14),
          _TipsCard(),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconFg;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: c.ink.withValues(alpha: 0.03),
                blurRadius: 6, offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: iconFg, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12.5, color: c.ink2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: c.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: c.primaryTint, borderRadius: BorderRadius.circular(99)),
            child: Icon(Icons.eco_outlined, color: c.primary, size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips for accuracy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                SizedBox(height: 6),
                _Bullet('Top-down angle, all items visible'),
                _Bullet('Even lighting, no harsh shadows'),
                _Bullet('Place a fork or coin for scale (optional)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 8),
            child: Container(width: 4, height: 4, decoration: BoxDecoration(color: c.ink3, shape: BoxShape.circle)),
          ),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: c.ink2, height: 1.5))),
        ],
      ),
    );
  }
}
