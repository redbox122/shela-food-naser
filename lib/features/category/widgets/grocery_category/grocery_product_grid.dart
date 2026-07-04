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
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryProductGrid extends StatelessWidget {
  final List<Item> items;
  // Added (additive) for the transferred offers screen: an optional list layout
  // and an inStore flag. Defaults keep the existing grid behaviour identical for
  // every current caller (which passes neither).
  final bool isListView;
  final bool inStore;
  // When true, use the offers card design (favourite ♡ + discount badge). Kept
  // off by default so the grocery-category grid card is untouched.
  final bool offersStyle;

  const GroceryProductGrid({
    super.key,
    required this.items,
    this.isListView = false,
    this.inStore = true,
    this.offersStyle = false,
  });

  /// Favourite ♡ toggle used by the offers list/grid cards.
  Widget _favButton(BuildContext context, Item item) {
    return GetBuilder<FavouriteController>(builder: (fav) {
      final bool wished = fav.wishItemIdList.contains(item.id);
      return InkWell(
        onTap: () => wished
            ? fav.removeFromFavouriteList(item.id, false)
            : fav.addToFavouriteList(item, null, false),
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6), shape: BoxShape.circle),
          child: Icon(wished ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: wished ? const Color(0xFFE7557A) : Colors.grey),
        ),
      );
    });
  }

  Widget _addButton(BuildContext context, Item item) {
    return GestureDetector(
      onTap: () => Get.find<ItemController>()
          .navigateToItemPage(item, context, inStore: inStore),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
            color: Color(0xFFCDEFD4), shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Color(0xFF31A342), size: 20),
      ),
    );
  }

  Widget _discountBadge(int pct) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE7EC),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('-$pct%',
            style: robotoMedium.copyWith(
                color: const Color(0xFFE7557A), fontSize: 10)),
      );

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

    // Optional list layout (used by the offers screen). The grid path below is
    // untouched, so callers that don't pass isListView see the exact same grid.
    if (isListView) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) => _buildListItem(context, items[index]),
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
        // Offers screen uses the offers card; everything else keeps its grid card.
        return offersStyle
            ? _buildOffersGridCard(context, item)
            : _buildProductCard(context, item, itemWidth);
      },
    );
  }

  /// List-row layout for the offers screen (matches the design): ♡ + add on the
  /// left, image + discount badge on the right, name + prices in the middle.
  Widget _buildListItem(BuildContext context, Item item) {
    final bool hasDiscount = item.discount != null && item.discount! > 0;
    final double discountedPrice =
        hasDiscount ? (item.price ?? 0) - (item.discount ?? 0) : item.price ?? 0;
    final int pct = (hasDiscount && (item.price ?? 0) > 0)
        ? (((item.discount ?? 0) / (item.price ?? 1)) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => Get.find<ItemController>()
          .navigateToItemPage(item, context, inStore: inStore),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        // RTL: image leads on the right, actions on the left.
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(
                image: item.displayImage ?? '',
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                placeholder: Images.placeholder,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(
                          fontSize: 13, color: AppColors.textColor)),
                  const SizedBox(height: 6),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(PriceConverter.convertPrice(discountedPrice),
                          style: robotoMedium.copyWith(
                              fontSize: 14, color: AppColors.textColor)),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(PriceConverter.convertPrice(item.price ?? 0),
                            style: robotoRegular.copyWith(
                                fontSize: 11,
                                color: AppColors.gryColor_2,
                                decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // ♡ + discount badge + add, stacked on the physical left.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _favButton(context, item),
                if (pct > 0) _discountBadge(pct) else const SizedBox(height: 4),
                _addButton(context, item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Offers grid card (matches the design): image + discount badge, ♡ top-left,
  /// name, prices, add button. Used only when [offersStyle] is on.
  Widget _buildOffersGridCard(BuildContext context, Item item) {
    final bool hasDiscount = item.discount != null && item.discount! > 0;
    final double discountedPrice =
        hasDiscount ? (item.price ?? 0) - (item.discount ?? 0) : item.price ?? 0;
    final int pct = (hasDiscount && (item.price ?? 0) > 0)
        ? (((item.discount ?? 0) / (item.price ?? 1)) * 100).round()
        : 0;
    return GestureDetector(
      onTap: () => Get.find<ItemController>()
          .navigateToItemPage(item, context, inStore: inStore),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: CustomImage(
                      image: item.displayImage ?? '',
                      height: 96,
                      fit: BoxFit.cover,
                      placeholder: Images.placeholder,
                    ),
                  ),
                ),
                Positioned(top: 0, left: 0, child: _favButton(context, item)),
                if (pct > 0)
                  Positioned(top: 2, right: 2, child: _discountBadge(pct)),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.name ?? '',
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(
                    fontSize: 12, color: AppColors.textColor)),
            const SizedBox(height: 6),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _addButton(context, item),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(PriceConverter.convertPrice(discountedPrice),
                          style: robotoMedium.copyWith(
                              fontSize: 13, color: AppColors.textColor)),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                              PriceConverter.convertPrice(item.price ?? 0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(
                                  fontSize: 10,
                                  color: AppColors.gryColor_2,
                                  decoration: TextDecoration.lineThrough)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          inStore: inStore, // configurable (default true)
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
                          inStore: inStore,
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


