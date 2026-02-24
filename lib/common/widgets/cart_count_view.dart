import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class CartCountView extends StatelessWidget {
  final Item item;
  final Widget? child;
  final int? index;
  final bool inStorePage;
  final bool isCampaign;
  const CartCountView(
      {super.key,
      required this.item,
      this.child,
      this.index = -1,
      this.inStorePage = false,
      this.isCampaign = false});

  @override
  Widget build(BuildContext context) {
    // 🔥 FIX: Use cart_count ID to receive updates from _onCartMutated()
    return GetBuilder<CartController>(
      id: 'cart_count',
      builder: (cartController) {
      final int cartQty = cartController.cartQuantity(item.id!);
      final int cartIndex = cartController.isExistInCart(
          item.id, cartController.cartVariant(item.id!), false, null);
      return cartQty != 0
          ? Center(
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 70,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusExtraLarge),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                                if (cartIndex >= 0 && cartIndex < cartController.cartList.length) {
                                  final cartItem = cartController.cartList[cartIndex];
                                  if (cartItem.quantity! > 1) {
                                    cartController.setDirectlyAddToCartIndex(index);
                                    // 🔥 FIX: Use cart_id instead of index
                                    if (cartItem.id != null) {
                                      cartController.setQuantityById(
                                          false,
                                          cartItem.id!,
                                          cartItem.stock,
                                          cartItem.item!.quantityLimit);
                                    } else {
                                      // Fallback for items without cart_id
                                      // ignore: deprecated_member_use_from_same_package
                                      cartController.setQuantity(
                                          false,
                                          cartIndex,
                                          cartItem.stock,
                                          cartItem.item!.quantityLimit);
                                    }
                                  } else {
                                    // 🔥 FIX: Use cart_id instead of index
                                    if (cartItem.id != null) {
                                      cartController.removeFromCartById(cartItem.id!, reason: 'cart_count_decrement');
                                    } else {
                                      // Fallback for items without cart_id
                                      // ignore: deprecated_member_use_from_same_package
                                      cartController.removeFromCart(cartIndex);
                                    }
                                  }
                                }
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).primaryColor),
                          ),
                          padding: const EdgeInsets.all(
                              Dimensions.paddingSizeExtraSmall),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall),
                        child: cartController.isLoading &&
                                cartController.directAddCartItemIndex == index
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Theme.of(context).cardColor))
                            : Text(
                                cartQty.toString(),
                                style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).cardColor),
                              ),
                      ),
                      InkWell(
                        onTap: () {
                          if (cartIndex >= 0 &&
                              cartIndex < cartController.cartList.length) {
                            final cartItem = cartController.cartList[cartIndex];
                            cartController.setDirectlyAddToCartIndex(index);
                            // 🔥 FIX: Use cart_id instead of index
                            if (cartItem.id != null) {
                              cartController.setQuantityById(
                                  true,
                                  cartItem.id!,
                                  cartItem.stock,
                                  cartItem.quantityLimit);
                            } else {
                              // Fallback for items without cart_id
                              // ignore: deprecated_member_use_from_same_package
                              cartController.setQuantity(
                                  true,
                                  cartIndex,
                                  cartItem.stock,
                                  cartItem.quantityLimit);
                            }
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).primaryColor),
                          ),
                          padding: const EdgeInsets.all(
                              Dimensions.paddingSizeExtraSmall),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ]),
              ),
            )
          : InkWell(
              onTap: () {
                // ✅ FRONTEND ONLY: Block add to cart only when the current store matches the item store
                if (item.storeId != null) {
                  try {
                    final storeController = Get.find<StoreController>();
                    final store = storeController.store;
                    if (store != null && store.id == item.storeId) {
                      // ✅ FRONTEND ONLY: Use store.isOpen from API only
                      // ❌ NO DateTime, NO schedule checks, NO time logic
                      final bool canOrder = store.isOpen == true;
                      if (!canOrder) {
                        showCustomSnackBar(
                            'المتجر مغلق حالياً، يمكنك التصفح فقط');
                        return;
                      }
                    }
                  } catch (e) {
                    // StoreController not found or error - allow order
                  }
                }
                HapticFeedback.lightImpact();
                // Keep "+" behavior identical to card tap behavior.
                Get.find<ItemController>().navigateToItemPage(
                  item,
                  context,
                  inStore: inStorePage,
                  isCampaign: isCampaign,
                );
              },
              child: child ??
                  Container(
                    height: 25,
                    width: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            spreadRadius: 1)
                      ],
                    ),
                    child: Icon(Icons.add,
                        size: 20, color: Theme.of(context).primaryColor),
                  ),
            );
    });
  }
}
