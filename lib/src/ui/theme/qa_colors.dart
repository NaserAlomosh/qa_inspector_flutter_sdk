import 'package:flutter/material.dart';

abstract final class QaColors {
  // Brand / Accent
  static const accent = Color(0xFF5B5BD6);
  static const accentDark = Color(0xFF8B8CF8);

  // Semantic
  static const success = Color(0xFF15805D);
  static const successDark = Color(0xFF42C99A);

  static const failure = Color(0xFFC43D4F);
  static const failureDark = Color(0xFFFF7185);

  static const cancelled = Color(0xFFA86714);
  static const cancelledDark = Color(0xFFF4B860);

  static const navigation = Color(0xFF3478C7);
  static const navigationDark = Color(0xFF6BA8F2);

  // Neutral
  static const slate = Color(0xFF667085);

  // Light
  static const canvas = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E7EC);

  // Dark
  static const darkCanvas = Color(0xFF0D1017);
  static const darkSurface = Color(0xFF151922);
  static const darkBorder = Color(0xFF2A303C);

  static const light = QaColorTokens(
    background: canvas,
    surface: surface,
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0F2F5),

    border: border,
    borderStrong: Color(0xFFD0D5DD),

    textPrimary: Color(0xFF171A23),
    textSecondary: Color(0xFF667085),

    accent: accent,

    success: success,
    failure: failure,
    warning: cancelled,
    navigation: navigation,

    codeBackground: Color(0xFFF5F6F8),

    buttonForeground: Color(0xFFFFFFFF),
    buttonBorder: Color(0x335B5BD6),

    shadow: Color(0x26000000),
  );

  static const dark = QaColorTokens(
    // Main canvas
    background: Color(0xFF111318),

    // Main cards / panels
    surface: Color(0xFF181B21),

    // Dialogs / elevated content
    surfaceElevated: Color(0xFF20242C),

    // Inputs / chips / secondary surfaces
    surfaceMuted: Color(0xFF252A33),

    // Borders
    border: Color(0xFF2C313B),
    borderStrong: Color(0xFF3A414D),

    // Text
    textPrimary: Color(0xFFE7E9EE),
    textSecondary: Color(0xFF9CA3AF),

    // Main interactive accent
    accent: Color(0xFF8B8CF8),

    // Semantic colors
    success: Color(0xFF5BC99A),
    failure: Color(0xFFF07883),
    warning: Color(0xFFE7AE61),
    navigation: Color(0xFF75A7E8),

    // JSON / request / response
    codeBackground: Color(0xFF14171C),

    // Floating QA button
    buttonForeground: Color(0xFFF7F7FA),
    buttonBorder: Color(0xFF4B4C85),

    // Shadows
    shadow: Color(0x52000000),
  );
}

/// Immutable semantic colors used by QA Inspector presentation.
@immutable
final class QaColorTokens {
  /// Creates a complete QA Inspector color palette.
  const QaColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.success,
    required this.failure,
    required this.warning,
    required this.navigation,
    required this.codeBackground,
    required this.buttonForeground,
    required this.buttonBorder,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;

  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;

  final Color accent;

  final Color success;
  final Color failure;
  final Color warning;
  final Color navigation;

  final Color codeBackground;

  final Color buttonForeground;
  final Color buttonBorder;

  final Color shadow;
}
