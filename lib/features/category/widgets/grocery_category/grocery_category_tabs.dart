/// Grocery Category Tabs Widget
/// 
/// Displays horizontal scrollable tabs for subcategories with green underline
/// for selected tab, matching the grocery category design.
/// 
/// File: grocery_category_tabs.dart
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryCategoryTabs extends StatelessWidget {
  final List<CategoryModel> subCategories;
  final int? selectedSubCategoryId;
  final Function(int?) onSubCategorySelected;

  const GroceryCategoryTabs({
    super.key,
    required this.subCategories,
    required this.selectedSubCategoryId,
    required this.onSubCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryTabs] build() - File: grocery_category_tabs.dart');
      debugPrint('   SubCategories count: ${subCategories.length}');
    }

    // Create list with "All" option at the beginning
    final List<CategoryModel> allCategories = [
      CategoryModel(
        name: 'الكل', // All in Arabic
      ),
      ...subCategories,
    ];

    return Container(
      height: 48,
      color: const Color(0xFFEBEBEB), // Light gray background
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = category.id == selectedSubCategoryId ||
              (category.id == null && selectedSubCategoryId == null);

          return GestureDetector(
            onTap: () {
              if (kDebugMode) {
                debugPrint(
                    '📍 [GroceryCategoryTabs] Tab tapped: ${category.name} (ID: ${category.id})');
              }
              onSubCategorySelected(category.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFF31A342) // Green underline
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                category.name ?? '',
                style: robotoRegular.copyWith(
                  fontSize: 14,
                  color: isSelected
                      ? AppColors.textColor
                      : AppColors.gryColor_2,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

