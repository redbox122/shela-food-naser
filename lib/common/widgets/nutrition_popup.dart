import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/styles.dart';

/// Nutrition popup widget that displays all nutrition information
class NutritionPopup extends StatelessWidget {
  final Nutrition nutrition;

  const NutritionPopup({
    super.key,
    required this.nutrition,
  });

  /// Show nutrition popup as a bottom sheet
  static void show(BuildContext context, Nutrition nutrition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NutritionPopup(nutrition: nutrition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = isArabic ? TextAlign.right : TextAlign.left;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Directionality(
        textDirection: textDirection,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'المعلومات الغذائية' : 'Nutrition Details',
                    style: robotoBold.copyWith(
                      fontSize: 20,
                      color: const Color(0xFF2D3633),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: const Color(0xFF2D3633),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEBEBEB)),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Calories (Large, Prominent)
                    if (nutrition.calories != null && nutrition.calories! > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFE5B4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  size: 32,
                                  color: Color(0xFFFF6B35),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${nutrition.calories}',
                                  style: robotoBold.copyWith(
                                    fontSize: 36,
                                    color: const Color(0xFF2D3633),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic ? 'سعرة حرارية' : 'Calories',
                                  style: robotoMedium.copyWith(
                                    fontSize: 18,
                                    color: const Color(0xFF2D3633),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Nutrition Breakdown
                    if ((nutrition.protein != null && nutrition.protein! > 0) ||
                        (nutrition.carbs != null && nutrition.carbs! > 0) ||
                        (nutrition.fat != null && nutrition.fat! > 0) ||
                        (nutrition.fiber != null && nutrition.fiber! > 0)) ...[
                      Text(
                        isArabic ? 'القيمة الغذائية' : 'Nutrition Breakdown',
                        style: robotoBold.copyWith(
                          fontSize: 18,
                          color: const Color(0xFF2D3633),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: textAlign,
                      ),
                      const SizedBox(height: 16),
                      // Nutrition items
                      if (nutrition.protein != null && nutrition.protein! > 0)
                        _buildNutritionItem(
                          context,
                          isArabic ? 'البروتين' : 'Protein',
                          '${nutrition.protein!.toStringAsFixed(1)}g',
                          Icons.fitness_center,
                        ),
                      if (nutrition.carbs != null && nutrition.carbs! > 0)
                        _buildNutritionItem(
                          context,
                          isArabic ? 'الكربوهيدرات' : 'Carbs',
                          '${nutrition.carbs!.toStringAsFixed(1)}g',
                          Icons.grain,
                        ),
                      if (nutrition.fat != null && nutrition.fat! > 0)
                        _buildNutritionItem(
                          context,
                          isArabic ? 'الدهون' : 'Fat',
                          '${nutrition.fat!.toStringAsFixed(1)}g',
                          Icons.opacity,
                        ),
                      if (nutrition.fiber != null && nutrition.fiber! > 0)
                        _buildNutritionItem(
                          context,
                          isArabic ? 'الألياف' : 'Fiber',
                          '${nutrition.fiber!.toStringAsFixed(1)}g',
                          Icons.eco,
                        ),
                      const SizedBox(height: 24),
                    ],
                    // Per 100g indicator
                    if (nutrition.nutritionPer100g == true)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Color(0xFF8A8C8E),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isArabic
                                  ? 'القيم الغذائية لكل 100 جرام'
                                  : 'Nutrition values per 100g',
                              style: robotoRegular.copyWith(
                                fontSize: 14,
                                color: const Color(0xFF8A8C8E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Nutrition source
                    if (nutrition.nutritionSource != null &&
                        nutrition.nutritionSource!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        isArabic ? 'المصدر' : 'Source',
                        style: robotoMedium.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF8A8C8E),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: textAlign,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nutrition.nutritionSource!,
                        style: robotoRegular.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF2D3633),
                        ),
                        textAlign: textAlign,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final textAlign = isArabic ? TextAlign.right : TextAlign.left;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF2D3633),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: robotoMedium.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF2D3633),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: textAlign,
              ),
            ],
          ),
          // Value
          Text(
            value,
            style: robotoBold.copyWith(
              fontSize: 16,
              color: const Color(0xFF2D3633),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

