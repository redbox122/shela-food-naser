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
import 'package:sixam_mart/theme/app_color_tokens.dart';
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

  /// Circular product photo with soft ring + shadow (food / restaurants / cafes).
  static Widget _circularItemPhoto({
    required BuildContext context,
    required double diameter,
    required String imageUrl,
    required int cacheSize,
  }) {
    final Color primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: primary.withValues(alpha: 0.22),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: CustomImage(
            image: imageUrl,
            fit: BoxFit.cover,
            width: diameter,
            height: diameter,
            cacheWidth: cacheSize,
            cacheHeight: cacheSize,
          ),
        ),
      ),
    );
  }

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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).extension<AppColorTokens>()!.outlineSoft,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
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
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: Center(
                                child: _circularItemPhoto(
                                  context: context,
                                  diameter: 110,
                                  imageUrl: item.displayImage ?? '',
                                  cacheSize: 420,
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
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.error
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
                                      color: Theme.of(context).colorScheme.onError,
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
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
                                      color: Theme.of(context).disabledColor,
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
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  _buildOutOfStockOverlay(
                    context: context,
                    borderRadius: BorderRadius.circular(24),
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
    const double listImageSize = 100;

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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Theme.of(context).extension<AppColorTokens>()!.outlineSoft,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withValues(alpha: 0.12),
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
                              child: _circularItemPhoto(
                                context: context,
                                diameter: listImageSize,
                                imageUrl: item.displayImage ?? '',
                                cacheSize: 320,
                              ),
                            ),
                            // Discount Badge - Top left of image
                            if (hasDiscount)
                              Positioned(
                                top: 8,
                                left: 22,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.discount}% ${'off'.tr}',
                                    style: robotoBold.copyWith(
                                      fontSize: 9,
                                      color: Theme.of(context).colorScheme.onError,
                                    ),
                                  ),
                                ),
                              ),
                            // Heart icon on image - top right
                            Positioned(
                              top: 8,
                              right: 22,
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
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  _buildOutOfStockOverlay(
                    context: context,
                    borderRadius: BorderRadius.circular(22),
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
    required BuildContext context,
    required BorderRadius borderRadius,
    required String label,
    double bottomSpacing = 0,
  }) {
    return Positioned.fill(
      bottom: bottomSpacing,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.22),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: robotoBold.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

