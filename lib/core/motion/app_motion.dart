import 'package:flutter/material.dart';

class AppMotion {
  // Animation Durations
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration micro = Duration(milliseconds: 200);
  static const Duration page = Duration(milliseconds: 350);
  static const Duration cinematic = Duration(milliseconds: 600);

  // Animation Curves
  static const Curve curveFast = Curves.easeOutCubic;
  static const Curve curveMicro = Curves.easeInOutCubic;
  static const Curve curvePage = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;
}
