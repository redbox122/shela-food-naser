/// Food Restaurant Category Tabs - Premium Apple-Luxury Design
///
/// Elegant, minimalist category pills with smooth interactions
///
/// File: food_restaurant_category_tabs.dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodRestaurantCategoryTabs extends StatefulWidget {
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final Function(int?, String) onCategorySelected;
  final VoidCallback? onMoreTap;

  const FoodRestaurantCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.onMoreTap,
  });

  @override
  State<FoodRestaurantCategoryTabs> createState() =>
      _FoodRestaurantCategoryTabsState();
}

class _FoodRestaurantCategoryTabsState
    extends State<FoodRestaurantCategoryTabs> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final bool isLtr = localizationController.isLtr;
        final theme = Theme.of(context);
        final tokens = theme.extension<AppColorTokens>()!;

        return Directionality(
          textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                left: isLtr ? Dimensions.paddingSizeDefault : 0,
                right: !isLtr ? Dimensions.paddingSizeDefault : 0,
              ),
              itemCount:
                  widget.categories.length + (widget.onMoreTap != null ? 1 : 0),
              itemBuilder: (context, index) {
                // Add "More" button at the FIRST position (index 0)
                if (index == 0 && widget.onMoreTap != null) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: widget.onMoreTap,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tokens.surfaceSoft,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: tokens.outlineSoft,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.list_rounded,
                          size: 22,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  );
                }

                // Adjust index to account for More button at position 0
                final categoryIndex =
                    widget.onMoreTap != null ? index - 1 : index;
                final category = widget.categories[categoryIndex];
                final isSelected = widget.selectedCategoryId == category.id;

                return _buildCategoryChip(
                  context: context,
                  categoryId: category.id,
                  categoryName: category.name ?? '',
                  isSelected: isSelected,
                  isLtr: isLtr,
                  onTap: () => widget.onCategorySelected(
                      category.id, category.name ?? ''),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required int? categoryId,
    required String categoryName,
    required bool isSelected,
    required bool isLtr,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8), // Consistent spacing
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : tokens.surfaceSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? theme.primaryColor : tokens.outlineSoft,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: isSelected ? 0.2 : 0.08),
              blurRadius: isSelected ? 12 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Text(
          categoryName,
          textAlign: TextAlign.center,
          style: robotoMedium.copyWith(
            fontSize: 14,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyLarge?.color,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
