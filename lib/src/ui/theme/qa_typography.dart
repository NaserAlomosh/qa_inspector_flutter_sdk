import 'package:flutter/material.dart';

abstract final class QaTypography {
  static TextTheme textTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? const Color(0xFFF0F2F7)
        : const Color(0xFF1A2030);
    return TextTheme(
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: color),
      bodyMedium: TextStyle(fontSize: 13, height: 1.4, color: color),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
