import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/widgets/item_add_to_cart_control.dart';
import 'package:sixam_mart/features/item/widgets/item_price_text.dart';

/// Price (end) + morphing add-to-cart control (start) row.
///
/// Rebuilds on cart mutations ('cart_count') and reads this item's live
/// quantity straight from the cart so the counter and the cart badge never
/// drift apart. The actual cart mutation is delegated to the owning screen via
/// [onActivate] / [onIncrement] / [onDecrement].
class ItemAddToCartRow extends StatelessWidget {
  final ItemController itemController;
  final bool quantitySelected;
  final VoidCallback onActivate;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ItemAddToCartRow({
    super.key,
    required this.itemController,
    required this.quantitySelected,
    required this.onActivate,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      id: 'cart_count',
      builder: (cartController) {
        final bool isOutOfStock = (itemController.item?.stock ?? 1) <= 0;
        // 🔗 Live cart sync.
        final int? existingCartId = itemController.item?.id != null
            ? cartController.getCartIdByItemId(itemController.item!.id!)
            : null;
        final bool inCart = existingCartId != null;
        int displayQty = itemController.quantity ?? 1;
        if (inCart) {
          final int idx =
              cartController.cartList.indexWhere((e) => e.id == existingCartId);
          if (idx != -1) {
            displayQty = cartController.cartList[idx].quantity ?? displayQty;
          }
        }
        return Row(
          children: [
            // Price on the end (right in RTL).
            ItemPriceText(item: itemController.item!),
            const Spacer(),
            // Add control on the start (left in RTL).
            ItemAddToCartControl(
              outOfStock: isOutOfStock,
              active: (quantitySelected || inCart) && !isOutOfStock,
              quantity: displayQty,
              isLoading: cartController.isLoading,
              onActivate: onActivate,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        );
      },
    );
  }
}
