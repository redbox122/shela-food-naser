/// Modern 3D Design System Tokens
///
/// This file centralizes all design tokens for the modern 3D UI redesign
/// including shadows, elevations, animations, gradients, and spacing.
/// Inspired by Apple's design philosophy with strong visual hierarchy.
library;

import 'package:flutter/material.dart';

/// Design tokens for modern 3D food order UI
class DesignTokens {
  // ==================== COLORS ====================

  /// Primary green color
  static const Color primaryGreen = Color(0xFF31A342);

  /// Secondary orange color
  static const Color secondaryOrange = Color(0xFFFA9D2B);

  /// Dark text color
  static const Color textDark = Color(0xFF2D3633);

  /// Light text color
  static const Color textLight = Color(0xFF7B8280);

  /// Divider color
  static const Color divider = Color(0xFFE9ECEB);

  /// Card background
  static const Color cardBackground = Colors.white;

  // ==================== GRADIENTS ====================

  /// Primary green gradient for selected states
  static const LinearGradient primaryGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3FBF53), // Lighter green
      Color(0xFF31A342), // Primary green
      Color(0xFF2A8F38), // Darker green
    ],
  );

  /// Subtle green gradient for headers
  static const LinearGradient headerGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0F9F2), // Very light green
      Color(0xFFE8F5EA), // Light green tint
    ],
  );

  /// Orange gradient for accents
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBAB3B), // Lighter orange
      Color(0xFFFA9D2B), // Primary orange
      Color(0xFFE88E1A), // Darker orange
    ],
  );

  /// Image overlay gradient (dark at bottom)
  static const LinearGradient imageOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x40000000), // 25% black
    ],
  );

  // ==================== SHADOWS ====================

  /// Subtle shadow for minimal elevation (2dp)
  static List<BoxShadow> get shadowSubtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Medium shadow for cards (4dp)
  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// Strong shadow for elevated cards (8dp)
  static List<BoxShadow> get shadowStrong => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Extra strong shadow for floating elements (12dp)
  static List<BoxShadow> get shadowExtraStrong => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// Glow shadow for selected interactive elements
  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Inset shadow effect (simulated with border)
  static BoxDecoration insetShadow(Color backgroundColor) => BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      );

  // ==================== BORDER RADIUS ====================

  /// Small radius (8px)
  static const double radiusSmall = 8.0;

  /// Medium radius (12px)
  static const double radiusMedium = 12.0;

  /// Default radius (16px)
  static const double radiusDefault = 16.0;

  /// Large radius (20px)
  static const double radiusLarge = 20.0;

  /// Extra large radius (24px)
  static const double radiusExtraLarge = 24.0;

  /// Full circle radius
  static const double radiusFull = 1000.0;

  // ==================== SPACING ====================

  /// Extra small spacing (4px)
  static const double spaceExtraSmall = 4.0;

  /// Small spacing (8px)
  static const double spaceSmall = 8.0;

  /// Medium spacing (12px)
  static const double spaceMedium = 12.0;

  /// Default spacing (16px)
  static const double spaceDefault = 16.0;

  /// Large spacing (20px)
  static const double spaceLarge = 20.0;

  /// Extra large spacing (24px)
  static const double spaceExtraLarge = 24.0;

  /// Huge spacing (32px)
  static const double spaceHuge = 32.0;

  // ==================== ANIMATIONS ====================

  /// Fast animation duration (150ms)
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Default animation duration (200ms)
  static const Duration animationDefault = Duration(milliseconds: 200);

  /// Medium animation duration (300ms)
  static const Duration animationMedium = Duration(milliseconds: 300);

  /// Slow animation duration (400ms)
  static const Duration animationSlow = Duration(milliseconds: 400);

  /// Ease out curve (most common)
  static const Curve curveEaseOut = Curves.easeOut;

  /// Ease in out curve (balanced)
  static const Curve curveEaseInOut = Curves.easeInOut;

  /// Ease out cubic (smooth)
  static const Curve curveEaseOutCubic = Curves.easeOutCubic;

  /// Bounce out curve (playful)
  static const Curve curveBounceOut = Curves.elasticOut;

  // ==================== SIZES ====================

  /// Radio button size (32px)
  static const double radioSize = 32.0;

  /// Checkbox size (28px)
  static const double checkboxSize = 28.0;

  /// Interactive element minimum size (44px)
  static const double minTouchTarget = 44.0;

  /// Button height (56px)
  static const double buttonHeight = 56.0;

  /// Small button height (48px)
  static const double buttonHeightSmall = 48.0;

  // ==================== BORDERS ====================

  /// Thin border width (1px)
  static const double borderThin = 1.0;

  /// Medium border width (2px)
  static const double borderMedium = 2.0;

  /// Thick border width (3px)
  static const double borderThick = 3.0;

  // ==================== ELEVATIONS ====================

  /// Resting elevation (2dp)
  static const double elevationResting = 2.0;

  /// Raised elevation (4dp)
  static const double elevationRaised = 4.0;

  /// Elevated elevation (8dp)
  static const double elevationElevated = 8.0;

  /// Floating elevation (12dp)
  static const double elevationFloating = 12.0;

  /// Modal elevation (16dp)
  static const double elevationModal = 16.0;
}










