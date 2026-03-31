/// Grocery Product Grid Widget
/// 
/// Displays products in a 2-column grid with discount pricing,
/// matching the grocery category design.
/// 
/// File: grocery_product_grid.dart
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryProductGrid extends StatelessWidget {
  final List<Item> items;

  const GroceryProductGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryProductGrid] build() - File: grocery_product_grid.dart');
      debugPrint('   Items count: ${items.length}');
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Text(
            'no_category_item_found'.tr,
            style: robotoRegular.copyWith(
              fontSize: 14,
              color: AppColors.gryColor_2,
            ),
          ),
        ),
      );
    }

    // Calculate grid dimensions for 2 columns
    const crossAxisCount = 2;
    const spacing = 16.0;
    final itemWidth =
        (Get.width - (Dimensions.paddingSizeDefault * 2) - spacing) / crossAxisCount;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.68, // Adjusted for product cards
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildProductCard(context, item, itemWidth);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Item item, double width) {
    final hasDiscount = item.discount != null && item.discount! > 0;
    final discountedPrice = hasDiscount
        ? (item.price ?? 0) - (item.discount ?? 0)
        : item.price ?? 0;

    return GestureDetector(
      onTap: () {
        if (kDebugMode) {
          debugPrint(
              '📍 [GroceryProductGrid] Product tapped: ${item.name} (ID: ${item.id})');
        }
        // Use the same navigation method as other grocery modules
        Get.find<ItemController>().navigateToItemPage(
          item,
          context,
          inStore: true, // Items are shown within store context
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9), // Light gray background
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with add to cart button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      border: Border.all(
                        color: const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: CustomImage(
                        image: item.displayImage ?? '',
                        placeholder: Images.placeholder,
                      ),
                    ),
                  ),
                  // Add to cart button (green circle with +)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (kDebugMode) {
                          debugPrint(
                              '📍 [GroceryProductGrid] Add to cart tapped: ${item.name}');
                        }
                        Get.find<ItemController>().navigateToItemPage(
                          item,
                          context,
                          inStore: true,
                        );
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF31A342), // Green
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product name and price
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Product name
                    Text(
                      item.name ?? '',
                      style: robotoRegular.copyWith(
                        fontSize: 10,
                        color: AppColors.textColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price row
                    Row(
                      children: [
                        // Discounted price (orange)
                        Text(
                          PriceConverter.convertPrice(discountedPrice),
                          style: robotoRegular.copyWith(
                            fontSize: 10,
                            color: const Color(0xFFFA9D2B), // Orange
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 8),
                          // Original price (crossed out)
                          Text(
                            PriceConverter.convertPrice(item.price ?? 0),
                            style: robotoRegular.copyWith(
                              fontSize: 10,
                              color: AppColors.gryColor_2,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


