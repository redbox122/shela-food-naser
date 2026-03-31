/// Grocery Categories Grid Widget
///
/// Displays product categories in a 3-column grid layout matching the grocery store design.
/// Shows category images and names in Arabic.
///
/// File: grocery_categories_grid.dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/screens/grocery_category_detail_screen.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryCategoriesGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final int storeId;

  const GroceryCategoriesGrid({
    super.key,
    required this.categories,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox();
    }

    // Calculate grid dimensions with better spacing
    const crossAxisCount = 2;
    const spacing = 16.0;
    final itemSize =
        (Get.width - (Dimensions.paddingSizeDefault * 2) - spacing) /
            crossAxisCount;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category, itemSize);
      },
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, CategoryModel category, double size) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Check if this is module 7 (grocery) - use specialized screen
          final splashController = Get.find<SplashController>();
          final isGrocery =
              splashController.module?.moduleType.toString() == 'grocery' ||
                  splashController.module?.id == 7;

          if (isGrocery) {
            // Preload subcategories with sample items (non-blocking) for this category.
            // This uses the new backend endpoint but does not change existing navigation behavior.
            try {
              final storeController = Get.find<StoreController>();
              if (category.id != null) {
                storeController.getSubcategoriesWithSamples(
                  storeId: storeId,
                  parentCategoryId: category.id!,
                );
              }
            } catch (_) {
              // Ignore errors here to avoid impacting navigation.
            }

            // Use specialized grocery category detail screen
            final storeController = Get.find<StoreController>();
            Get.to(() => GroceryCategoryDetailScreen(
                  categoryId: category.id,
                  categoryName: category.name ?? '',
                  store: storeController.store,
                ));
          } else {
            // Use standard category item screen for other modules
            Get.toNamed(
              RouteHelper.getCategoryItemRoute(
                category.id,
                category.name ?? '',
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category image with better styling
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: tokens.surfaceSoft,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomImage(
                      image: category.imageFullUrl ?? '',
                      placeholder: Images.placeholder,
                    ),
                  ),
                ),
              ),
              // Category name with better typography
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Text(
                    category.name ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: robotoMedium.copyWith(
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
