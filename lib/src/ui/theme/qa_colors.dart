import 'package:flutter/material.dart';

abstract final class QaColors {
  static const accent = Color(0xFF5754D8);
  static const accentDark = Color(0xFFAAA7FF);
  static const success = Color(0xFF16845B);
  static const successDark = Color(0xFF55D6A0);
  static const failure = Color(0xFFBF3442);
  static const failureDark = Color(0xFFFF8791);
  static const cancelled = Color(0xFFAA6200);
  static const cancelledDark = Color(0xFFFFB95C);
  static const navigation = Color(0xFF2970C8);
  static const navigationDark = Color(0xFF7BB6FF);
  static const slate = Color(0xFF647184);
  static const canvas = Color(0xFFF3F5F8);
  static const surface = Color(0xFFFCFCFE);
  static const border = Color(0xFFDDE2EA);
  static const darkCanvas = Color(0xFF10131A);
  static const darkSurface = Color(0xFF191D27);
  static const darkBorder = Color(0xFF303644);

  static const light = QaColorTokens(
    background: canvas,
    surface: surface,
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE9EDF3),
    border: border,
    borderStrong: Color(0xFFC4CBD7),
    textPrimary: Color(0xFF1A2030),
    textSecondary: slate,
    accent: accent,
    success: success,
    failure: failure,
    warning: cancelled,
    navigation: navigation,
    codeBackground: Color(0xFFF7F8FA),
    buttonForeground: Color(0xFFFFFFFF),
    buttonBorder: Color(0x335754D8),
    shadow: Color(0x40000000),
  );

  static const dark = QaColorTokens(
    background: darkCanvas,
    surface: darkSurface,
    surfaceElevated: Color(0xFF202531),
    surfaceMuted: Color(0xFF252B37),
    border: darkBorder,
    borderStrong: Color(0xFF485164),
    textPrimary: Color(0xFFF0F2F7),
    textSecondary: Color(0xFF9CA5B5),
    accent: accentDark,
    success: successDark,
    failure: failureDark,
    warning: cancelledDark,
    navigation: navigationDark,
    codeBackground: Color(0xFF141821),
    buttonForeground: Color(0xFFFFFFFF),
    buttonBorder: Color(0x33FFFFFF),
    shadow: Color(0x73000000),
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
  /// Inspector canvas color.
  final Color background;
  /// Default content surface color.
  final Color surface;
  /// Elevated content surface color.
  final Color surfaceElevated;
  /// Muted control surface color.
  final Color surfaceMuted;
  /// Subtle divider color.
  final Color border;
  /// Emphasized border color.
  final Color borderStrong;
  /// Primary readable text color.
  final Color textPrimary;
  /// Secondary readable text color.
  final Color textSecondary;
  /// Interactive accent color.
  final Color accent;
  /// Successful event color.
  final Color success;
  /// Failed event color.
  final Color failure;
  /// Warning and cancellation color.
  final Color warning;
  /// Navigation event color.
  final Color navigation;
  /// Technical content background color.
  final Color codeBackground;
  /// Floating button foreground color.
  final Color buttonForeground;
  /// Floating button border color.
  final Color buttonBorder;
  /// Floating button shadow color.
  final Color shadow;
}
