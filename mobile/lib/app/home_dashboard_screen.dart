import 'package:flutter/material.dart';

import '../ui/app_page.dart';
import '../ui/barcode_icon.dart';
import '../ui/quick_action_card.dart';
import 'app_tabs.dart';

class HomeDashboardScreen extends StatelessWidget {
  final void Function(AppTabId tabId) onOpenTab;

  const HomeDashboardScreen({
    super.key,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'NutriFit Dashboard',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Quick actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          QuickActionCard(
            icon: const Icon(Icons.search),
            title: 'Search foods',
            subtitle: 'Find foods by name and view nutrition details.',
            onTap: () => onOpenTab(AppTabId.search),
          ),
          const SizedBox(height: 12),
          QuickActionCard(
            icon: const BarcodeIcon(),
            title: 'Scan barcode',
            subtitle: 'Jump to barcode lookup for packaged foods.',
            onTap: () => onOpenTab(AppTabId.barcode),
          ),
          const SizedBox(height: 12),
          QuickActionCard(
            icon: const Icon(Icons.camera_alt),
            title: 'Camera meal estimate',
            subtitle: 'Use a photo to estimate meal calories.',
            onTap: () => onOpenTab(AppTabId.meal),
          ),
          const SizedBox(height: 12),
          QuickActionCard(
            icon: const Icon(Icons.monitor_weight_outlined),
            title: 'Health tracking',
            subtitle: 'Water, weight, and BMI tracking will live here next.',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Health tracking is coming in a later phase.'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          QuickActionCard(
            icon: const Icon(Icons.history),
            title: 'Recent history',
            subtitle: 'Reopen foods you viewed recently.',
            onTap: () => onOpenTab(AppTabId.history),
          ),
          const SizedBox(height: 24),
          Text(
            'Daily summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _PlaceholderCard(
            title: 'Calories',
            value: '0 kcal',
            subtitle: 'Daily food tracking can plug in here later.',
          ),
          const SizedBox(height: 12),
          const _PlaceholderCard(
            title: 'Water',
            value: '0 ml',
            subtitle: 'Hydration logging is planned for a later phase.',
          ),
          const SizedBox(height: 12),
          const _PlaceholderCard(
            title: 'BMI / Weight',
            value: '--',
            subtitle: 'Weight and BMI placeholders for health tracking.',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _PlaceholderCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
