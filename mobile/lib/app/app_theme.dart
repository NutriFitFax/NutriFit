import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nutri_colors.dart';

/// Warm, food-forward Material 3 theme for NutriFit.
///
/// - Display / numerals: Newsreader (warm serif)
/// - UI body / labels:   Manrope (clean geometric sans)
/// - Color tokens live in [NutriColors] (ThemeExtension); see [nutri_colors.dart].
ThemeData buildAppTheme() {
  const c = NutriColors.light;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: c.primary,
    brightness: Brightness.light,
    primary: c.primary,
    onPrimary: const Color(0xFFFDFAF0),
    primaryContainer: c.primarySoft,
    onPrimaryContainer: c.primaryDeep,
    secondary: c.honey,
    surface: c.bg,
    onSurface: c.ink,
    outline: c.lineStrong,
    outlineVariant: c.line,
    error: c.warn,
  );

  final manrope  = GoogleFonts.manropeTextTheme();
  final newsread = GoogleFonts.newsreaderTextTheme();

  final textTheme = manrope.copyWith(
    displayLarge:  newsread.displayLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w500),
    displayMedium: newsread.displayMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w500),
    displaySmall:  newsread.displaySmall?.copyWith(color: c.ink, fontWeight: FontWeight.w500),
    headlineLarge:  newsread.headlineLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w500, letterSpacing: -0.2),
    headlineMedium: newsread.headlineMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w500, letterSpacing: -0.2),
    headlineSmall:  newsread.headlineSmall?.copyWith(color: c.ink, fontWeight: FontWeight.w500, letterSpacing: -0.1),
    titleLarge:    newsread.titleLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w500, fontSize: 22),
    titleMedium: manrope.titleMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w600),
    titleSmall:  manrope.titleSmall?.copyWith(color: c.ink, fontWeight: FontWeight.w600),
    bodyLarge:   manrope.bodyLarge?.copyWith(color: c.ink),
    bodyMedium:  manrope.bodyMedium?.copyWith(color: c.ink),
    bodySmall:   manrope.bodySmall?.copyWith(color: c.ink2),
    labelLarge:  manrope.labelLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w600),
    labelMedium: manrope.labelMedium?.copyWith(color: c.ink2, fontWeight: FontWeight.w600, letterSpacing: 0.6),
    labelSmall:  manrope.labelSmall?.copyWith(color: c.ink3, fontWeight: FontWeight.w600, letterSpacing: 0.6),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.bg,
    textTheme: textTheme,
    extensions: const [NutriColors.light],

    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: c.ink),
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall?.copyWith(fontSize: 24),
    ),

    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: c.line),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.primaryTint,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: textTheme.labelSmall?.fontFamily,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? c.primary : c.ink2,
          letterSpacing: -0.1,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? c.primary : c.ink2,
          size: 22,
        );
      }),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: const Color(0xFFFDFAF0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.lineStrong),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: c.ink3, fontFamily: textTheme.bodyMedium?.fontFamily),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.surface,
      modalBarrierColor: c.ink.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      dragHandleColor: c.lineStrong,
    ),

    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: c.ink, size: 22),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      side: BorderSide(color: c.line),
      labelStyle: TextStyle(color: c.ink, fontWeight: FontWeight.w500, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: const StadiumBorder(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.primary,
      linearTrackColor: c.line,
      circularTrackColor: c.line,
    ),
  );
}
