import 'package:flutter/material.dart';

import '../api/models.dart';

class FoodListTile extends StatelessWidget {
  final String title;
  final String? brand;
  final Macros macros;
  final VoidCallback? onTap;
  final String? trailingText;

  const FoodListTile({
    super.key,
    required this.title,
    this.brand,
    required this.macros,
    this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (brand != null && brand!.isNotEmpty) brand!,
      '${macros.caloriesKcal.toStringAsFixed(0)} kcal / 100g',
    ];

    return ListTile(
      onTap: onTap,
      title: Text(title),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: trailingText == null
          ? null
          : Text(
              trailingText!,
              style: Theme.of(context).textTheme.labelMedium,
            ),
    );
  }
}
