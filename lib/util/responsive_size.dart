import 'package:flutter/widgets.dart';

/// Proportional sizing relative to a base design width (the profile screens
/// were designed against a ~375pt-wide canvas). Multiplies a value by
/// `screenWidth / baseWidth`, clamped so text/spacing never shrinks or grows
/// too aggressively on very small or very large devices.
///
/// Usage:
///   fontSize: 16.r(context)
///   height: 145.r(context)
class ScreenScale {
  ScreenScale._();

  static const double baseWidth = 375.0;
  static const double minFactor = 0.85;
  static const double maxFactor = 1.30;

  static double factor(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return (width / baseWidth).clamp(minFactor, maxFactor);
  }

  static double scale(BuildContext context, double value) =>
      value * factor(context);
}

extension ResponsiveSizeX on num {
  /// Returns this value scaled proportionally to the screen width.
  double r(BuildContext context) => ScreenScale.scale(context, toDouble());
}
