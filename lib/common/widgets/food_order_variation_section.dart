import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/styles.dart';

/// Non-expandable variation section that always shows choices
class FoodOrderVariationSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Color? headerColor;

  const FoodOrderVariationSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final crossAxisAlignment = isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    // Determine if required based on subtitle
    final bool isRequired = subtitle != null && subtitle!.contains('مطلوب');
    
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        // Header with title on right and badge on left (RTL layout)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Directionality(
            textDirection: textDirection,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: isArabic
                  ? [
                      // RTL: Title on right, Badge on left
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          style: robotoBold.copyWith(
                            color: const Color(0xFF2D3633),
                            fontSize: 23.8,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFB),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isRequired)
                                const Icon(
                                  Icons.info_outline,
                                  size: 21,
                                  color: Color(0xFF4A4A4B),
                                ),
                              if (isRequired) const SizedBox(width: 4),
                              Text(
                                subtitle!,
                                style: robotoRegular.copyWith(
                                  color: const Color(0xFF4A4A4B),
                                  fontSize: 18.4,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ]
                  : [
                      // LTR: Badge on left, Title on right
                      if (subtitle != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFB),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(3),
                              bottomLeft: Radius.circular(3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isRequired)
                                const Icon(
                                  Icons.info_outline,
                                  size: 21,
                                  color: Color(0xFF4A4A4B),
                                ),
                              if (isRequired) const SizedBox(width: 4),
                              Text(
                                subtitle!,
                                style: robotoRegular.copyWith(
                                  color: const Color(0xFF4A4A4B),
                                  fontSize: 18.4,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.left,
                          style: robotoBold.copyWith(
                            color: const Color(0xFF2D3633),
                            fontSize: 23.8,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        ),
        // Content area - always visible
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: child,
        ),
      ],
    );
  }
}










