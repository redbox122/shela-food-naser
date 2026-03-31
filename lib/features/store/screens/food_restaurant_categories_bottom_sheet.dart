/// Food Restaurant Categories Bottom Sheet
/// 
/// Displays all categories in a list format
/// Shows category name and item count
/// 
/// File: food_restaurant_categories_bottom_sheet.dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodRestaurantCategoriesBottomSheet extends StatelessWidget {
  final List<CategoryModel> categories;
  final Map<int?, int> categoryItemCounts;
  final int? selectedCategoryId;
  final Function(int?, String) onCategorySelected;
  
  const FoodRestaurantCategoriesBottomSheet({
    super.key,
    required this.categories,
    required this.categoryItemCounts,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final bool isLtr = localizationController.isLtr;
        final theme = Theme.of(context);
        final tokens = theme.extension<AppColorTokens>()!;
        
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.outlineSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Text(
                  'categories'.tr,
                  style: robotoBold.copyWith(
                    fontSize: 20,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Divider(height: 1, color: tokens.outlineSoft),
              // Categories List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategoryId == category.id;
                    final itemCount = categoryItemCounts[category.id] ?? 0;
                    
                    return GestureDetector(
                      onTap: () {
                        onCategorySelected(category.id, category.name ?? '');
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? theme.primaryColor.withValues(alpha: 0.12)
                              : tokens.surfaceSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? theme.primaryColor
                                : tokens.outlineSoft,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category Name
                            Expanded(
                              child: Text(
                                category.name ?? '',
                                textAlign: isLtr ? TextAlign.left : TextAlign.right,
                                style: robotoBold.copyWith(
                                  fontSize: 16,
                                  color: isSelected 
                                      ? theme.primaryColor
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            // Item Count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? theme.primaryColor
                                    : tokens.outlineSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$itemCount',
                                style: robotoBold.copyWith(
                                  fontSize: 14,
                                  color: isSelected 
                                      ? theme.colorScheme.onPrimary
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}





