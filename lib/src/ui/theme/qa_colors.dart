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
    pending: Color(0xFFB7791F),
    cancelled: cancelled,
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
    pending: Color(0xFFE7AE61),
    cancelled: Color(0xFFD89A55),
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
final class QaColorTokens extends ThemeExtension<QaColorTokens> {
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
    required this.pending,
    required this.cancelled,
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
  final Color pending;
  final Color cancelled;
  final Color navigation;

  final Color codeBackground;

  final Color buttonForeground;
  final Color buttonBorder;

  final Color shadow;

  @override
  QaColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? success,
    Color? failure,
    Color? pending,
    Color? cancelled,
    Color? navigation,
    Color? codeBackground,
    Color? buttonForeground,
    Color? buttonBorder,
    Color? shadow,
  }) => QaColorTokens(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    accent: accent ?? this.accent,
    success: success ?? this.success,
    failure: failure ?? this.failure,
    pending: pending ?? this.pending,
    cancelled: cancelled ?? this.cancelled,
    navigation: navigation ?? this.navigation,
    codeBackground: codeBackground ?? this.codeBackground,
    buttonForeground: buttonForeground ?? this.buttonForeground,
    buttonBorder: buttonBorder ?? this.buttonBorder,
    shadow: shadow ?? this.shadow,
  );

  @override
  QaColorTokens lerp(covariant QaColorTokens? other, double t) {
    if (other == null) return this;
    return QaColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      failure: Color.lerp(failure, other.failure, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      cancelled: Color.lerp(cancelled, other.cancelled, t)!,
      navigation: Color.lerp(navigation, other.navigation, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      buttonForeground: Color.lerp(
        buttonForeground,
        other.buttonForeground,
        t,
      )!,
      buttonBorder: Color.lerp(buttonBorder, other.buttonBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
