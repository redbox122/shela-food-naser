import 'package:flutter/material.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/design_tokens.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:get/get.dart';

/// Recommended items section widget displaying horizontal scrollable cards
class RecommendedItemsSection extends StatelessWidget {
  final List<Item> recommendedItems;
  final void Function(Item item)? onOpenItem;

  const RecommendedItemsSection({
    super.key,
    required this.recommendedItems,
    this.onOpenItem,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title and subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'غالبا ما يتم طلبه مع',
                  style: robotoBold.copyWith(
                    fontSize: 18,
                    color: const Color(0xFF2D3633),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'عادة ما يضيف الأشخاص هذه العناصر',
                  style: robotoRegular.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF8A8C8E),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Horizontal scrollable list
          SizedBox(
            height: 228,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recommendedItems.length,
              itemBuilder: (context, index) {
                return _RecommendedItemCard(
                  item: recommendedItems[index],
                  onOpenItem: onOpenItem,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual recommended item card
class _RecommendedItemCard extends StatelessWidget {
  final Item item;
  final void Function(Item item)? onOpenItem;

  const _RecommendedItemCard({required this.item, this.onOpenItem});

  /// Check if item has variations (food variations or legacy choice options)
  bool _hasVariations(Item item) {
    final hasFoodVariations =
        item.foodVariations != null && item.foodVariations!.isNotEmpty;
    final hasChoiceOptions =
        item.choiceOptions != null && item.choiceOptions!.isNotEmpty;
    return hasFoodVariations || hasChoiceOptions;
  }

  /// Get total cart quantity for this item across all variations
  int _getCartQuantity(CartController cartController) {
    return cartController.cartQuantity(item.id!);
  }

  /// Find cart index for item without variations
  int _getCartIndex(CartController cartController) {
    // Find cart item with same item ID and no variations
    for (int i = 0; i < cartController.cartList.length; i++) {
      final cartItem = cartController.cartList[i];
      if (cartItem.item?.id == item.id) {
        // Check if this cart item has no variations
        final hasVariations =
            (cartItem.variation != null && cartItem.variation!.isNotEmpty) ||
                (cartItem.foodVariations != null &&
                    cartItem.foodVariations!.isNotEmpty);
        if (!hasVariations) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Handle add to cart or open bottom sheet for items with variations
  void _handleAddToCart(BuildContext context) {
    if (_hasVariations(item)) {
      if (onOpenItem != null) {
        onOpenItem!(item);
      } else {
        Get.toNamed(RouteHelper.getItemDetailsRoute(item.id, false));
      }
    } else {
      // Item has no variations - add directly to cart
      final cartController = Get.find<CartController>();

      // Calculate price with discount if available
      final price = item.price ?? 0.0;
      final discount = item.discount ?? 0.0;
      final discountType = item.discountType;
      final priceWithDiscount = PriceConverter.convertWithDiscount(
            price,
            discount,
            discountType,
          ) ??
          price;

      // Calculate discount amount
      final discountAmount = price - priceWithDiscount;

      // 🔧 FIX: Get storeId from multiple sources to ensure it's never null
      int? effectiveStoreId = item.storeId;
      if (effectiveStoreId == null && Get.isRegistered<StoreController>()) {
        effectiveStoreId = Get.find<StoreController>().store?.id;
      }

      // Create cart model for the recommended item
      // Recommended items are added without variations or add-ons
      final cartModel = CartModel(
        id: null, // id
        // 🔧 FIX: Explicitly set storeId to enable different-store detection
        storeId: effectiveStoreId, // store id for cart validation
        price: price, // original price
        discountedPrice: priceWithDiscount, // discounted price
        variation: [], // variation (empty for recommended items)
        foodVariations: [], // foodVariations
        discountAmount: discountAmount, // discount amount
        quantity: 1, // quantity
        addOnIds: [], // addOnIds
        addOns: [], // addOns
        isCampaign: false, // isCampaign
        stock: item.stock, // stock
        item: item, // item
        quantityLimit: item.quantityLimit, // quantityLimit
      );

      // Add to cart using the cart controller
      cartController.addToCart(cartModel, null);

      // 🎨 Show modern top notification (prevents accumulation, beautiful design)
      // 🔥 FIX: Pass context for ScaffoldMessenger (required for production safety)
      showCartSnackBar(context);
    }
  }

  /// Handle quantity increment
  void _handleIncrement(CartController cartController) {
    final cartIndex = _getCartIndex(cartController);
    if (cartIndex != -1 && cartIndex < cartController.cartList.length) {
      final cartItem = cartController.cartList[cartIndex];
      // 🔥 FIX: Use cart_id instead of index
      if (cartItem.id != null) {
        cartController.setQuantityById(
          true,
          cartItem.id!,
          item.stock,
          item.quantityLimit,
        );
      } else {
        // Fallback for items without cart_id
        // ignore: deprecated_member_use_from_same_package
        cartController.setQuantity(
          true,
          cartIndex,
          item.stock,
          item.quantityLimit,
        );
      }
    }
  }

  /// Handle quantity decrement
  void _handleDecrement(CartController cartController) {
    final cartIndex = _getCartIndex(cartController);
    if (cartIndex != -1 && cartIndex < cartController.cartList.length) {
      final cartItem = cartController.cartList[cartIndex];
      final currentQuantity = cartItem.quantity ?? 0;
      if (currentQuantity > 1) {
        // 🔥 FIX: Use cart_id instead of index
        if (cartItem.id != null) {
          cartController.setQuantityById(
            false,
            cartItem.id!,
            item.stock,
            item.quantityLimit,
          );
        } else {
          // Fallback for items without cart_id
          // ignore: deprecated_member_use_from_same_package
          cartController.setQuantity(
            false,
            cartIndex,
            item.stock,
            item.quantityLimit,
          );
        }
      } else {
        // Remove from cart when quantity reaches 0
        // 🔥 FIX: Use cart_id instead of index
        if (cartItem.id != null) {
          cartController.removeFromCartById(cartItem.id!, item: item, reason: 'recommended_items_decrement');
        } else {
          // Fallback for items without cart_id
          // ignore: deprecated_member_use_from_same_package
          cartController.removeFromCart(cartIndex, item: item);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      id: 'cart_items',
      builder: (CartController cartController) {
        final int cartQuantity = _getCartQuantity(cartController);
        final bool showQuantityControls =
            cartQuantity > 0 && !_hasVariations(item);
        final String itemLabel = item.name ?? '';
        final ColorScheme scheme = Theme.of(context).colorScheme;

        return Container(
          width: 156,
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: showQuantityControls
                ? Border.all(
                    color: DesignTokens.primaryGreen,
                    width: 2,
                  )
                : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  children: [
                    CustomImage(
                      image: item.imageFullUrl ?? '',
                      height: 88,
                      width: double.infinity,
                    ),
                    if (showQuantityControls)
                      PositionedDirectional(
                        top: 6,
                        start: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              '${'recommended_in_cart'.tr} · $cartQuantity',
                              style: robotoMedium.copyWith(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        itemLabel,
                        style: robotoRegular.copyWith(
                          fontSize: 11,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${PriceConverter.convertPrice(item.price)} ريال',
                        style: robotoBold.copyWith(
                          fontSize: 13,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                      const Spacer(),
                      if (showQuantityControls)
                        Semantics(
                          label:
                              '$itemLabel ${'recommended_in_cart'.tr} $cartQuantity',
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: DesignTokens.primaryGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: DesignTokens.primaryGreen
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: _QuantityControls(
                                quantity: cartQuantity,
                                itemLabel: itemLabel,
                                onDecrement: () =>
                                    _handleDecrement(cartController),
                                onIncrement: () =>
                                    _handleIncrement(cartController),
                              ),
                            ),
                          ),
                        )
                      else if (_hasVariations(item))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              label:
                                  '${'recommended_customize_add'.tr} $itemLabel',
                              button: true,
                              child: Material(
                                color: DesignTokens.primaryGreen,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () => _handleAddToCart(context),
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    height: 36,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.tune_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'recommended_customize_add'.tr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: robotoBold.copyWith(
                                              fontSize: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Semantics(
                          label:
                              '${'add_to_cart'.tr} $itemLabel',
                          button: true,
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Material(
                              color: DesignTokens.primaryGreen,
                              shape: const CircleBorder(),
                              elevation: 2,
                              shadowColor:
                                  DesignTokens.primaryGreen.withValues(
                                alpha: 0.35,
                              ),
                              child: InkWell(
                                onTap: () => _handleAddToCart(context),
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-width quantity strip: each control is labeled with the product name.
class _QuantityControls extends StatelessWidget {
  final int quantity;
  final String itemLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControls({
    required this.quantity,
    required this.itemLabel,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Semantics(
            button: true,
            label: '$itemLabel decrease quantity',
            child: Material(
              color: Theme.of(context).cardColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onDecrement,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DesignTokens.secondaryOrange,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: onSurface,
                  ),
                ),
              ),
            ),
          ),
          Text(
            quantity.toString(),
            style: robotoBold.copyWith(
              color: onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Semantics(
            button: true,
            label: '$itemLabel increase quantity',
            child: Material(
              color: DesignTokens.primaryGreen,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onIncrement,
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
