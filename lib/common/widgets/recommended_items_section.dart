import 'package:flutter/material.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
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
            height: 195,
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
    return GetBuilder<CartController>(builder: (cartController) {
      final cartQuantity = _getCartQuantity(cartController);
      final showQuantityControls = cartQuantity > 0 && !_hasVariations(item);

      return Container(
        width: 150,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: CustomImage(
                image: item.imageFullUrl ?? '',
                height: 100,
                width: double.infinity,
              ),
            ),

            // Item details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Item name
                    Text(
                      item.name ?? '',
                      style: robotoRegular.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF2D3633),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),

                    // Price and controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Flexible(
                          child: Text(
                            '${PriceConverter.convertPrice(item.price)} ريال',
                            style: robotoBold.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF2D3633),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Plus button or quantity controls
                        if (showQuantityControls)
                          _QuantityControls(
                            quantity: cartQuantity,
                            onDecrement: () => _handleDecrement(cartController),
                            onIncrement: () => _handleIncrement(cartController),
                          )
                        else
                          GestureDetector(
                            onTap: () => _handleAddToCart(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFF31A342),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x1A31A342),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Quantity controls widget with minus, quantity display, and plus buttons
class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControls({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button (orange outlined circle)
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFA9D2B),
                ),
              ),
              child: const Icon(
                Icons.remove,
                size: 10,
                color: Color(0xFF2D3633),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Quantity number
          Text(
            quantity.toString(),
            style: robotoRegular.copyWith(
              color: const Color(0xFF2D3633),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(width: 12),

          // Plus button (green filled circle)
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF31A342),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
