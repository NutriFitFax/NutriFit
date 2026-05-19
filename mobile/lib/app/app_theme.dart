import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorSchemeSeed: Colors.green,
    useMaterial3: true,
  );

  return base.copyWith(
    cardTheme: base.cardTheme.copyWith(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
