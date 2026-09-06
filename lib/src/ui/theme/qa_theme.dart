import 'package:flutter/material.dart';

import 'qa_colors.dart';
import 'qa_typography.dart';

abstract final class QaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: QaColors.accent, brightness: brightness, surface: dark ? QaColors.darkSurface : const Color(0xFFF8F9FC));
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? QaColors.darkCanvas : const Color(0xFFF3F5F9),
      textTheme: QaTypography.textTheme(brightness),
      dividerColor: dark ? const Color(0xFF303644) : const Color(0xFFDDE1E9),
      appBarTheme: AppBarTheme(backgroundColor: dark ? QaColors.darkSurface : Colors.white, surfaceTintColor: Colors.transparent, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: dark ? const Color(0xFF202531) : Colors.white, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      chipTheme: ChipThemeData(side: BorderSide(color: dark ? const Color(0xFF3B4251) : const Color(0xFFD9DEE8)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
      dialogTheme: DialogThemeData(backgroundColor: dark ? QaColors.darkSurface : Colors.white),
    );
  }
}
