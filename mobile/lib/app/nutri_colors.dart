import 'package:flutter/material.dart';

/// Warm food-forward palette tokens not covered by [ColorScheme].
///
/// Access via `Theme.of(context).extension<NutriColors>()!` or the shortcut
/// `context.nutri`.
@immutable
class NutriColors extends ThemeExtension<NutriColors> {
  // Surfaces
  final Color bg;            // app background (warm cream)
  final Color surface;       // card surface (lighter cream)
  final Color surfaceSunken; // inset/tray surface
  final Color line;          // light divider/border
  final Color lineStrong;    // visible border

  // Ink
  final Color ink;    // primary text
  final Color ink2;   // muted text
  final Color ink3;   // very-muted text

  // Brand
  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color primaryTint;

  // Macros
  final Color protein;     final Color proteinSoft;
  final Color carbs;       final Color carbsSoft;
  final Color fat;         final Color fatSoft;
  final Color water;       final Color waterSoft;

  // Accent
  final Color honey;
  final Color warn;

  const NutriColors({
    required this.bg,
    required this.surface,
    required this.surfaceSunken,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.primaryTint,
    required this.protein,
    required this.proteinSoft,
    required this.carbs,
    required this.carbsSoft,
    required this.fat,
    required this.fatSoft,
    required this.water,
    required this.waterSoft,
    required this.honey,
    required this.warn,
  });

  /// The single source of truth for the redesign's palette.
  static const light = NutriColors(
    bg:            Color(0xFFF5EFDF),
    surface:       Color(0xFFFBF6E9),
    surfaceSunken: Color(0xFFEFE8D4),
    line:          Color(0xFFE6DEC5),
    lineStrong:    Color(0xFFD6CDB1),

    ink:  Color(0xFF1F2A23),
    ink2: Color(0xFF56615A),
    ink3: Color(0xFF8A948C),

    primary:     Color(0xFF2F6A4B),
    primaryDeep: Color(0xFF1A3D2C),
    primarySoft: Color(0xFFDCE7D5),
    primaryTint: Color(0xFFEAF1E3),

    protein:     Color(0xFFC25E3B),
    proteinSoft: Color(0xFFF3DCCD),
    carbs:       Color(0xFFD99A3D),
    carbsSoft:   Color(0xFFF5E5C4),
    fat:         Color(0xFF8B8A3A),
    fatSoft:     Color(0xFFE8E7C8),
    water:       Color(0xFF4F8AA6),
    waterSoft:   Color(0xFFD6E6ED),

    honey: Color(0xFFE6B54E),
    warn:  Color(0xFFB14B3A),
  );

  @override
  NutriColors copyWith({
    Color? bg, Color? surface, Color? surfaceSunken, Color? line, Color? lineStrong,
    Color? ink, Color? ink2, Color? ink3,
    Color? primary, Color? primaryDeep, Color? primarySoft, Color? primaryTint,
    Color? protein, Color? proteinSoft, Color? carbs, Color? carbsSoft,
    Color? fat, Color? fatSoft, Color? water, Color? waterSoft,
    Color? honey, Color? warn,
  }) {
    return NutriColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryTint: primaryTint ?? this.primaryTint,
      protein: protein ?? this.protein,
      proteinSoft: proteinSoft ?? this.proteinSoft,
      carbs: carbs ?? this.carbs,
      carbsSoft: carbsSoft ?? this.carbsSoft,
      fat: fat ?? this.fat,
      fatSoft: fatSoft ?? this.fatSoft,
      water: water ?? this.water,
      waterSoft: waterSoft ?? this.waterSoft,
      honey: honey ?? this.honey,
      warn: warn ?? this.warn,
    );
  }

  @override
  NutriColors lerp(ThemeExtension<NutriColors>? other, double t) {
    if (other is! NutriColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return NutriColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      line: l(line, other.line),
      lineStrong: l(lineStrong, other.lineStrong),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      ink3: l(ink3, other.ink3),
      primary: l(primary, other.primary),
      primaryDeep: l(primaryDeep, other.primaryDeep),
      primarySoft: l(primarySoft, other.primarySoft),
      primaryTint: l(primaryTint, other.primaryTint),
      protein: l(protein, other.protein),
      proteinSoft: l(proteinSoft, other.proteinSoft),
      carbs: l(carbs, other.carbs),
      carbsSoft: l(carbsSoft, other.carbsSoft),
      fat: l(fat, other.fat),
      fatSoft: l(fatSoft, other.fatSoft),
      water: l(water, other.water),
      waterSoft: l(waterSoft, other.waterSoft),
      honey: l(honey, other.honey),
      warn: l(warn, other.warn),
    );
  }
}

extension NutriColorsBuildContext on BuildContext {
  NutriColors get nutri => Theme.of(this).extension<NutriColors>()!;
}
