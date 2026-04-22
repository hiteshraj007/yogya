import 'package:flutter/material.dart';

class ThemeColors extends ThemeExtension<ThemeColors> {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final Color bgDark;
  final Color bgCard;
  final Color bgCardLight;
  final Color bgWhite;
  final Color bgSurface;
  final Color textPrimary;
  final Color textDark;
  final Color textSecondary;
  final Color textHint;
  final Color textGrey;
  final Color eligible;
  final Color ineligible;
  final Color partial;
  final Color info;
  final Color glassBorder;
  final Color glassWhite;
  final Color urgencyHigh;
  final Color urgencyMedium;
  final Color urgencyLow;
  
  // Gradients
  final LinearGradient primaryGradient;
  final LinearGradient darkCardGradient;
  final LinearGradient eligibleGradient;
  final LinearGradient ineligibleGradient;
  final LinearGradient amberGradient;
  final LinearGradient splashGradient;
  final LinearGradient loginGradient;

  const ThemeColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.bgDark,
    required this.bgCard,
    required this.bgCardLight,
    required this.bgWhite,
    required this.bgSurface,
    required this.textPrimary,
    required this.textDark,
    required this.textSecondary,
    required this.textHint,
    required this.textGrey,
    required this.eligible,
    required this.ineligible,
    required this.partial,
    required this.info,
    required this.glassBorder,
    required this.glassWhite,
    required this.urgencyHigh,
    required this.urgencyMedium,
    required this.urgencyLow,
    required this.primaryGradient,
    required this.darkCardGradient,
    required this.eligibleGradient,
    required this.ineligibleGradient,
    required this.amberGradient,
    required this.splashGradient,
    required this.loginGradient,
  });

  @override
  ThemeExtension<ThemeColors> copyWith() => this;

  @override
  ThemeExtension<ThemeColors> lerp(ThemeExtension<ThemeColors>? other, double t) => this;

  static const dark = ThemeColors(
    primary: Color(0xFF3B5BDB),
    primaryDark: Color(0xFF1A1A2E),
    primaryLight: Color(0xFF748FFC),
    accent: Color(0xFF5C7CFA),
    bgDark: Color(0xFF0F1123),
    bgCard: Color(0xFF1A1D3A),
    bgCardLight: Color(0xFF252A4A),
    bgWhite: Color(0xFFFFFFFF),
    bgSurface: Color(0xFF15172F),
    textPrimary: Color(0xFFFFFFFF),
    textDark: Color(0xFF1A1A2E),
    textSecondary: Color(0xFFB0B0C3),
    textHint: Color(0xFF6B6B80),
    textGrey: Color(0xFF757575),
    eligible: Color(0xFF2ECC71),
    ineligible: Color(0xFFE74C3C),
    partial: Color(0xFFF39C12),
    info: Color(0xFF3498DB),
    glassBorder: Color(0x1FFFFFFF),
    glassWhite: Color(0x14FFFFFF),
    urgencyHigh: Color(0xFFFF4757),
    urgencyMedium: Color(0xFFFFA502),
    urgencyLow: Color(0xFF2ED573),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF3B5BDB), Color(0xFF748FFC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    darkCardGradient: LinearGradient(
      colors: [Color(0xFF1A1D3A), Color(0xFF252A4A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    eligibleGradient: LinearGradient(
      colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    ineligibleGradient: LinearGradient(
      colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    amberGradient: LinearGradient(
      colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    splashGradient: LinearGradient(
      colors: [Color(0xFF0F1123), Color(0xFF1A1A2E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    loginGradient: LinearGradient(
      colors: [Color(0xFF0F1123), Color(0xFF1A1D3A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const light = ThemeColors(
    primary: Color(0xFF3B5BDB),
    primaryDark: Color(0xFFE8EEF8),
    primaryLight: Color(0xFF748FFC),
    accent: Color(0xFF5C7CFA),
    bgDark: Color(0xFFF4F6FB),
    bgCard: Color(0xFFFFFFFF),
    bgCardLight: Color(0xFFF0F3FA),
    bgWhite: Color(0xFFFFFFFF),
    bgSurface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E213A),
    textDark: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF6B7280),
    textHint: Color(0xFF9CA3AF),
    textGrey: Color(0xFF4B5563),
    eligible: Color(0xFF2ECC71),
    ineligible: Color(0xFFE74C3C),
    partial: Color(0xFFF39C12),
    info: Color(0xFF3498DB),
    glassBorder: Color(0x14000000),
    glassWhite: Color(0x0A000000),
    urgencyHigh: Color(0xFFCC3B47),
    urgencyMedium: Color(0xFFE69500),
    urgencyLow: Color(0xFF24A65A),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF3B5BDB), Color(0xFF748FFC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    darkCardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF0F3FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    eligibleGradient: LinearGradient(
      colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    ineligibleGradient: LinearGradient(
      colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    amberGradient: LinearGradient(
      colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    splashGradient: LinearGradient(
      colors: [Color(0xFFF4F6FB), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    loginGradient: LinearGradient(
      colors: [Color(0xFFF4F6FB), Color(0xFFE8EEF8)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}

extension ThemeColorsExt on BuildContext {
  ThemeColors get colors => Theme.of(this).extension<ThemeColors>() ?? ThemeColors.dark;
}
