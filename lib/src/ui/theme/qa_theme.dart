import 'package:flutter/material.dart';

import 'qa_colors.dart';
import 'qa_typography.dart';

abstract final class QaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: QaColors.accent,
      brightness: brightness,
      surface: dark ? QaColors.darkSurface : QaColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? QaColors.darkCanvas : QaColors.canvas,
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
