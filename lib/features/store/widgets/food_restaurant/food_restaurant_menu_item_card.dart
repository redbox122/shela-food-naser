/// Food Restaurant Menu Item Card - Premium Apple-Luxury Design
///
/// Supports both grid and list view modes
/// Uses standard app button styles from other modules
///
/// File: food_restaurant_menu_item_card.dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodRestaurantMenuItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final bool isTemporarilyHighlighted;

  const FoodRestaurantMenuItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isTemporarilyHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        final bool isGridView = storeController.isVertical;

        // Grid view: Vertical card
        if (isGridView) {
          return _buildGridCard(context);
        }
        // List view: Horizontal card (like old screen)
        else {
          return _buildListCard(context);
        }
      },
    );
  }

  /// Grid View Card - Vertical layout
  Widget _buildGridCard(BuildContext context) {
    final itemController = Get.find<ItemController>();
    final finalPrice = itemController.getStartingPrice(item);
    final hasDiscount = item.discount != null && item.discount! > 0;
    final isOutOfStock = _isOutOfStock(item);

    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        return GestureDetector(
          onTap: isOutOfStock ? null : onTap,
          child: AbsorbPointer(
            absorbing: isOutOfStock,
            child: Stack(
              children: [
                Opacity(
                  opacity: isOutOfStock ? 0.75 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gryColor_3,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            // Image Container with White Padding/Edge
                            Container(
                              height: 140,
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.backgroundColor,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CustomImage(
                                  image: item.displayImage ?? '',
                                  height: 116,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  cacheWidth: 420,
                                  cacheHeight: 280,
                                ),
                              ),
                            ),
                            // Discount Badge - Always TOP RIGHT
                            if (hasDiscount)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.redColor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.redColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${item.discount}% ${'off'.tr}',
                                    style: robotoBold.copyWith(
                                      fontSize: 11,
                                      color: AppColors.backgroundColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            // Favorite Button - Always TOP LEFT
                            Positioned(
                              top: 8,
                              left: 8,
                              child: GetBuilder<FavouriteController>(
                                builder: (favouriteController) {
                                  final bool isWished = favouriteController
                                      .wishItemIdList
                                      .contains(item.id);
                                  return CustomFavouriteWidget(
                                    isWished: isWished,
                                    item: item,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        // Content Section
                        Padding(
                          padding: const EdgeInsets.all(11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Item name - always on RIGHT
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  item.name ?? '',
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: robotoBold.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textColor,
                                    height: 1.2,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Description - always on RIGHT
                              if (item.description != null &&
                                  item.description!.isNotEmpty)
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    item.description!,
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: robotoRegular.copyWith(
                                      fontSize: 11,
                                      color: AppColors.gryColor_2,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Price row - price on LEFT, cart button on RIGHT
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Price on LEFT with currency
                                  Text(
                                    '${PriceConverter.convertPrice(finalPrice)} ${'currency'.tr}',
                                    style: robotoBold.copyWith(
                                      fontSize: 16,
                                      color: AppColors.textColor,
                                      letterSpacing: -0.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  // Cart button on RIGHT
                                  CartCountView(item: item),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isTemporarilyHighlighted)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  _buildOutOfStockOverlay(
                    borderRadius: BorderRadius.circular(16),
                    label: 'انتهت الكمية',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// List View Card - Horizontal layout (like old screen)
  Widget _buildListCard(BuildContext context) {
    final itemController = Get.find<ItemController>();
    final finalPrice = itemController.getStartingPrice(item);
    final hasDiscount = item.discount != null && item.discount! > 0;
    final isOutOfStock = _isOutOfStock(item);

    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final bool isLtr = localizationController.isLtr;

        return GestureDetector(
          onTap: isOutOfStock ? null : onTap,
          child: AbsorbPointer(
            absorbing: isOutOfStock,
            child: Stack(
              children: [
                Opacity(
                  opacity: isOutOfStock ? 0.75 : 1,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 136),
                    margin: const EdgeInsets.only(
                        bottom: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(
                        color: AppColors.gryColor_3,
                        width: 0.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      textDirection:
                          isLtr ? TextDirection.ltr : TextDirection.rtl,
                      children: [
                        // Image Section
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 17),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault),
                                child: CustomImage(
                                  image: item.displayImage ?? '',
                                  height: 100,
                                  width: 120,
                                  cacheWidth: 320,
                                  cacheHeight: 260,
                                ),
                              ),
                            ),
                            // Discount Badge - Top left of image
                            if (hasDiscount)
                              Positioned(
                                top: 8,
                                left: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.redColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.discount}% ${'off'.tr}',
                                    style: robotoBold.copyWith(
                                      fontSize: 9,
                                      color: AppColors.backgroundColor,
                                    ),
                                  ),
                                ),
                              ),
                            // Heart icon on image - top right
                            Positioned(
                              top: 8,
                              right: 20,
                              child: GetBuilder<FavouriteController>(
                                builder: (favouriteController) {
                                  final bool isWished = favouriteController
                                      .wishItemIdList
                                      .contains(item.id);
                                  return CustomFavouriteWidget(
                                    isWished: isWished,
                                    item: item,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        // Text Info Section
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 8,
                              top: Dimensions.paddingSizeExtraSmall,
                              bottom: Dimensions.paddingSizeExtraSmall,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection:
                                  isLtr ? TextDirection.ltr : TextDirection.rtl,
                              children: [
                                // Item Name
                                Text(
                                  item.name ?? '',
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: isLtr
                                      ? TextDirection.ltr
                                      : TextDirection.rtl,
                                ),
                                // Description (store name)
                                Text(
                                  item.storeName ?? '',
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: isLtr
                                      ? TextDirection.ltr
                                      : TextDirection.rtl,
                                ),
                                const SizedBox(
                                    height: Dimensions.paddingSizeExtraSmall),
                                // Price and Cart Button Row
                                Row(
                                  textDirection: isLtr
                                      ? TextDirection.ltr
                                      : TextDirection.rtl,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${PriceConverter.convertPrice(finalPrice)} ${'currency'.tr}',
                                        style: robotoBold.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: AppColors.textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            Dimensions.paddingSizeExtraLarge),
                                    CartCountView(item: item),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isTemporarilyHighlighted)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault),
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  _buildOutOfStockOverlay(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                    label: 'انتهت الكمية',
                    bottomSpacing: Dimensions.paddingSizeSmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isOutOfStock(Item item) {
    // TEMP: force all products as in stock in menu cards.
    return false;
  }

  Widget _buildOutOfStockOverlay({
    required BorderRadius borderRadius,
    required String label,
    double bottomSpacing = 0,
  }) {
    return Positioned.fill(
      bottom: bottomSpacing,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          color: Colors.black.withValues(alpha: 0.22),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.redColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: robotoBold.copyWith(
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
