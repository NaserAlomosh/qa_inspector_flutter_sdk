import 'package:flutter/material.dart';

import 'qa_colors.dart';
import 'qa_inspector_theme_mode.dart';
import 'qa_typography.dart';

abstract final class QaTheme {
  /// Resolves an SDK-owned Material theme for [mode].
  static ThemeData resolve(QaInspectorThemeMode mode) =>
      mode == QaInspectorThemeMode.dark ? dark() : light();

  /// Resolves semantic SDK color tokens for [mode].
  static QaColorTokens colors(QaInspectorThemeMode mode) =>
      mode == QaInspectorThemeMode.dark ? QaColors.dark : QaColors.light;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = dark ? QaColors.dark : QaColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      surface: colors.surface,
    ).copyWith(
      primary: colors.accent,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.textSecondary,
      outlineVariant: colors.border,
      surfaceContainerHighest: colors.surfaceMuted,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: QaTypography.textTheme(brightness),
      dividerColor: dark ? QaColors.darkBorder : QaColors.border,
      appBarTheme: AppBarTheme(backgroundColor: dark ? QaColors.darkSurface : Colors.white, surfaceTintColor: Colors.transparent, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: dark ? const Color(0xFF202531) : Colors.white, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      chipTheme: ChipThemeData(side: BorderSide(color: dark ? const Color(0xFF3B4251) : const Color(0xFFD9DEE8)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
      dialogTheme: DialogThemeData(backgroundColor: dark ? QaColors.darkSurface : Colors.white),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      tabBarTheme: TabBarThemeData(
        dividerColor: dark ? QaColors.darkBorder : QaColors.border,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: dark ? QaColors.accentDark : QaColors.accent,
        unselectedLabelColor: dark ? const Color(0xFF9CA5B5) : QaColors.slate,
      ),
    );
  }
}
