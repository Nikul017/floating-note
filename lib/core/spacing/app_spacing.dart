import 'package:flutter/material.dart';

class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double giant = 64.0;

  // Constant heights
  static const SizedBox h4 = SizedBox(height: xxs);
  static const SizedBox h8 = SizedBox(height: xs);
  static const SizedBox h12 = SizedBox(height: sm);
  static const SizedBox h16 = SizedBox(height: md);
  static const SizedBox h20 = SizedBox(height: lg);
  static const SizedBox h24 = SizedBox(height: xl);
  static const SizedBox h32 = SizedBox(height: xxl);
  static const SizedBox h40 = SizedBox(height: xxxl);
  static const SizedBox h48 = SizedBox(height: huge);
  static const SizedBox h64 = SizedBox(height: giant);

  // Constant widths
  static const SizedBox w4 = SizedBox(width: xxs);
  static const SizedBox w8 = SizedBox(width: xs);
  static const SizedBox w12 = SizedBox(width: sm);
  static const SizedBox w16 = SizedBox(width: md);
  static const SizedBox w20 = SizedBox(width: lg);
  static const SizedBox w24 = SizedBox(width: xl);
  static const SizedBox w32 = SizedBox(width: xxl);
  static const SizedBox w40 = SizedBox(width: xxxl);
  static const SizedBox w48 = SizedBox(width: huge);
  static const SizedBox w64 = SizedBox(width: giant);
}

extension AppSpacingExtension on BuildContext {
  AppSpacingData get space => const AppSpacingData();
}

class AppSpacingData {
  const AppSpacingData();

  double get xxs => AppSpacing.xxs;
  double get xs => AppSpacing.xs;
  double get sm => AppSpacing.sm;
  double get md => AppSpacing.md;
  double get lg => AppSpacing.lg;
  double get xl => AppSpacing.xl;
  double get xxl => AppSpacing.xxl;
  double get xxxl => AppSpacing.xxxl;
  double get huge => AppSpacing.huge;
  double get giant => AppSpacing.giant;
}
