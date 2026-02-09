import 'package:flutter/material.dart';
import 'package:sixam_mart/util/styles.dart';

/// Minimal flat expandable section matching Figma design
class FoodOrderExpandableSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final Color? headerColor;

  const FoodOrderExpandableSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
    this.headerColor,
  });

  @override
  State<FoodOrderExpandableSection> createState() =>
      _FoodOrderExpandableSectionState();
}

class _FoodOrderExpandableSectionState
    extends State<FoodOrderExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced header with bigger sizes
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            width: double.infinity,
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title and subtitle on right (RTL) - first in Row for RTL
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.right,
                          style: robotoMedium.copyWith(
                            color: const Color(0xFF2D3633),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle!,
                            textAlign: TextAlign.right,
                            style: robotoRegular.copyWith(
                              color: const Color(0xFFC6C6C6),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Chevron icon on left (RTL) - second in Row for RTL
                  Transform.rotate(
                    angle: _isExpanded ? 1.57 : 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF2D3633),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Content area with better spacing
        if (_isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: widget.child,
          ),
      ],
    );
  }
}
