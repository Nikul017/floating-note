import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppTypography {
  // Display styles
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      );

  // Headings
  static TextStyle get headingLarge => const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  // Body Text
  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get bodySemibold => const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // Captions / Meta
  static TextStyle get caption => const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get captionSemibold => const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );
}

extension AppTypographyExtension on BuildContext {
  AppTypographyData get typography => const AppTypographyData();
}

class AppTypographyData {
  const AppTypographyData();

  TextStyle get displayLarge => AppTypography.displayLarge;
  TextStyle get displayMedium => AppTypography.displayMedium;
  TextStyle get headingLarge => AppTypography.headingLarge;
  TextStyle get headingMedium => AppTypography.headingMedium;
  TextStyle get bodyLarge => AppTypography.bodyLarge;
  TextStyle get bodyMedium => AppTypography.bodyMedium;
  TextStyle get bodySemibold => AppTypography.bodySemibold;
  TextStyle get caption => AppTypography.caption;
  TextStyle get captionSemibold => AppTypography.captionSemibold;
}
