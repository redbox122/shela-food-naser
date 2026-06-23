import 'package:flutter/material.dart';

/// Top-bar category tab: the active one is solid white with a white rounded
/// indicator that bridges to the sub-category strip below; idle tabs are dim
/// white with no indicator.
class CaretTab extends StatelessWidget {
  final String label;
  final bool selected;
  const CaretTab({
    super.key,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    // IntrinsicWidth + stretch makes the indicator span the full label width.
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.0,
              color: selected ? Color(0xff9CFAA2) : Colors.white,
            ),
          ),
          const SizedBox(height: 7),
          // Full-width white indicator under the active category, bridging to
          // the sub-category strip; transparent (same height) when idle.
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: selected ? Color(0xff9CFAA2) : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Borderless pill: active = pale-accent fill + accent text, idle = light-grey
/// fill + grey text.
class PillTab extends StatelessWidget {
  final String label;
  final bool selected;

  /// Brand accent (border + text when active) and its pale fill.
  final Color accent;
  final Color accentFill;
  const PillTab({
    super.key,
    required this.label,
    required this.selected,
    this.accent = const Color(0xFF3B984A),
    this.accentFill = const Color(0xFFEBFEEB),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? Color(0xffEBFEEB) : const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
          height: 1.0,
          color: selected ? accent : const Color(0xFF717885),
        ),
      ),
    );
  }
}
