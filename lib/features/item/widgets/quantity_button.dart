import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';

/// Circular +/- quantity stepper used by the item details (web) view.
///
/// When the item is already in the cart it mutates the real cart line by
/// cart_id; otherwise it adjusts the controller's local quantity.
class QuantityButton extends StatelessWidget {
  final bool isIncrement;
  final int? quantity;
  final bool isCartWidget;
  final int? stock;
  final bool isExistInCart;
  final int cartIndex;
  final int? quantityLimit;
  final CartController cartController;
  const QuantityButton({
    super.key,
    required this.isIncrement,
    required this.quantity,
    required this.stock,
    required this.isExistInCart,
    required this.cartIndex,
    this.isCartWidget = false,
    this.quantityLimit,
    required this.cartController,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isExistInCart) {
          final cartController = Get.find<CartController>();
          if (cartIndex >= 0 && cartIndex < cartController.cartList.length) {
            final cartItem = cartController.cartList[cartIndex];
            if (!isIncrement && quantity! > 1) {
              // 🔥 FIX: Use cart_id instead of index
              if (cartItem.id == null) {
                showCustomSnackBar('something_went_wrong'.tr);
                return;
              }
              cartController.setQuantityById(
                  false, cartItem.id!, stock, quantityLimit);
            } else if (isIncrement && quantity! > 0) {
              // TEMP: stock validation is intentionally disabled.
              if (cartItem.id == null) {
                showCustomSnackBar('something_went_wrong'.tr);
                return;
              }
              cartController.setQuantityById(
                  true, cartItem.id!, stock, quantityLimit);
            }
          }
        } else {
          if (!isIncrement && quantity! > 1) {
            Get.find<ItemController>().setQuantity(false, stock, quantityLimit);
          } else if (isIncrement && quantity! > 0) {
            // TEMP: stock validation is intentionally disabled.
            Get.find<ItemController>().setQuantity(true, stock, quantityLimit);
          }
        }
      },
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (quantity! == 1 && !isIncrement) || cartController.isLoading
              ? Theme.of(context).disabledColor
              : Theme.of(context).primaryColor,
        ),
        child: Center(
          child: Icon(
            isIncrement ? Icons.add : Icons.remove,
            color: isIncrement
                ? Colors.white
                : quantity! == 1
                    ? Colors.black
                    : Colors.white,
            size: isCartWidget ? 26 : 20,
          ),
        ),
      ),
    );
  }
}
