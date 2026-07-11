// 🎨 Keeta-style in-app payment — shared palette + sizing.
//
// Self-contained styling for the new native payment screens (approved design,
// 2026-07-10). Mirrors the app's existing palette (green #1FA64A / ink #121C19)
// and adapts to light/dark automatically. Purely additive — no existing widget
// depends on this, and this depends on nothing in the app besides Flutter.

import 'package:flutter/material.dart';

class KeetaPayStyle {
  final bool dark;
  const KeetaPayStyle._(this.dark);

  factory KeetaPayStyle.of(BuildContext context) =>
      KeetaPayStyle._(Theme.of(context).brightness == Brightness.dark);

  static const String font = 'Tajawal';

  Color get screen => dark ? const Color(0xFF0F1416) : const Color(0xFFF7F8FA);
  Color get card => dark ? const Color(0xFF161B1D) : Colors.white;
  Color get ink => dark ? const Color(0xFFEAF2EE) : const Color(0xFF121C19);
  Color get muted => dark ? const Color(0xFF8FA09A) : const Color(0xFF8A8A8A);
  Color get border => dark ? const Color(0xFF242B2D) : const Color(0xFFEDEFF1);
  Color get green => dark ? const Color(0xFF35C063) : const Color(0xFF1FA64A);
  Color get greenSoft => green.withValues(alpha: dark ? 0.14 : 0.10);
  Color get amber => const Color(0xFFF1A93B);
  Color get red => dark ? const Color(0xFFF0676B) : const Color(0xFFE5484D);
  Color get payBlack => dark ? const Color(0xFF0A0C0D) : const Color(0xFF111315);
  Color get field => dark ? const Color(0xFF1B2123) : const Color(0xFFF6F7F9);

  TextStyle t(double size,
          {FontWeight weight = FontWeight.w700, Color? color}) =>
      TextStyle(
        fontFamily: font,
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        height: 1.35,
      );
}

/// A brand chip (mada / VISA / MC / AMEX / UnionPay) rendered without external
/// image assets so the screens compile and preview cleanly.
class KeetaBrandChip extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;
  const KeetaBrandChip(this.label, this.color, {super.key, this.fontSize = 9});

  static const Color visa = Color(0xFF1A1F71);
  static const Color mc = Color(0xFFEB001B);
  static const Color mada = Color(0xFF00926F);
  static const Color amex = Color(0xFF2E77BC);
  static const Color unionpay = Color(0xFFE21836);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: KeetaPayStyle.font,
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          height: 1,
        ),
      ),
    );
  }
}
