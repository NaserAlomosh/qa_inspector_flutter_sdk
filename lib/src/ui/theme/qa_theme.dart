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

  /// Reads the semantic palette installed by the inspector's MaterialApp.
  static QaColorTokens colorsOf(BuildContext context) {
    final colors = Theme.of(context).extension<QaColorTokens>();
    assert(colors != null, 'QA widgets must be below InspectorShell.');
    return colors!;
  }

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
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.background,
      textTheme: QaTypography.textTheme(brightness),
      dividerColor: colors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceMuted,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      dialogTheme: DialogThemeData(backgroundColor: colors.surfaceElevated),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      tabBarTheme: TabBarThemeData(
        dividerColor: colors.border,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colors.accent,
        unselectedLabelColor: colors.textSecondary,
      ),
    );
  }
}
