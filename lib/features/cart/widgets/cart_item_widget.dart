// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet.dart';
import 'package:sixam_mart/common/widgets/quantity_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartItemWidget extends StatelessWidget {
  final CartModel cart;
  final int cartIndex;
  final List<AddOns> addOns;
  final bool isAvailable;
  const CartItemWidget({super.key, required this.cart, required this.cartIndex, required this.isAvailable, required this.addOns});

  @override
  Widget build(BuildContext context) {
    final double? startingPrice = _calculatePriceWithVariation(item: cart.item);
    final double? endingPrice = _calculatePriceWithVariation(item: cart.item, isStartingPrice: false);

    final double? discount = cart.item!.storeDiscount == 0 ? cart.item!.discount : cart.item!.storeDiscount;
    final String? discountType = cart.item!.storeDiscount == 0 ? cart.item!.discountType : 'percent';

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Slidable(
        key: UniqueKey(),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (context) {
                // 🔥 BUG FIX: Use cart_id instead of index (safe, index-independent)
                if (cart.id != null) {
                  Get.find<CartController>().removeFromCartById(cart.id!, item: cart.item, reason: 'slidable_action');
                } else {
                  // Fallback for items without cart_id (shouldn't happen, but safe)
                  // ignore: deprecated_member_use_from_same_package
                  Get.find<CartController>().removeFromCart(cartIndex, item: cart.item);
                }
              },
              backgroundColor: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(Get.find<LocalizationController>().isLtr ? Dimensions.radiusDefault : 0),
                  left: Radius.circular(Get.find<LocalizationController>().isLtr ? 0 : Dimensions.radiusDefault)),
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            boxShadow: !ResponsiveHelper.isMobile(context)
                ? [const BoxShadow()]
                : [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 1,
                    )
                  ],
          ),
          child: CustomInkWell(
            onTap: () {
              ResponsiveHelper.isMobile(context)
                  ? showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      isDismissible: true,
                      enableDrag: true,
                      showDragHandle: true,
                      builder: (BuildContext con) => ItemBottomSheet(
                        item: cart.item,
                        cartIndex: cartIndex,
                        cart: cart,
                      ),
                    )
                  : showDialog(
                      context: context,
                      builder: (con) => Dialog(
                            child: ItemBottomSheet(item: cart.item, cartIndex: cartIndex, cart: cart),
                          ));
            },
            radius: Dimensions.radiusDefault,
            padding:
                const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeExtraSmall),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: Dimensions.paddingSizeSmall),
                      SizedBox(
                          height: 24,
                          width: 24,
                          child: IconButton(
                            icon: Icon(Icons.cancel, size: 24),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // 🔥 BUG FIX: Use cart_id instead of index (safe, index-independent)
                              if (cart.id != null) {
                                Get.find<CartController>().removeFromCartById(cart.id!, item: cart.item, reason: 'delete_button');
                              } else {
                                // Fallback for items without cart_id
                                // ignore: deprecated_member_use_from_same_package
                                Get.find<CartController>().removeFromCart(cartIndex, item: cart.item);
                              }
                            },
                          )),
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cart.item!.name!.split(' ').take(5).join(' ') + (cart.item!.name!.split(' ').length > 5 ? '  ...' : ''),
                              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                            ),
                            Text(
                              cart.item!.storeName!,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).disabledColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: Dimensions.paddingSizeSmall),

                            //

                            Wrap(children: [
                              PriceConverter.convertPrice2(
                                startingPrice,
                                discount: discount,
                                discountType: discountType,
                                textStyle: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  color: Theme.of(context).extension<CustomThemeExtension>()?.yellow_Color,
                                ),
                              ),
                              if (endingPrice != null) ...[
                                Text(
                                  ' - ',
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Theme.of(context).extension<CustomThemeExtension>()?.yellow_Color,
                                  ),
                                ),
                                PriceConverter.convertPrice2(
                                  endingPrice,
                                  discount: discount,
                                  discountType: discountType,
                                  textStyle: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Theme.of(context).extension<CustomThemeExtension>()?.yellow_Color,
                                  ),
                                ),
                              ],
                              SizedBox(width: discount! > 0 ? Dimensions.paddingSizeExtraSmall : 0),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),

                  //    الازرار   ===================================

                  SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomImage(
                          image: '${cart.item!.imageFullUrl}',
                          height: ResponsiveHelper.isDesktop(context) ? 90 : 60,
                          width: ResponsiveHelper.isDesktop(context) ? 90 : 60,
                          fit: BoxFit.fill,
                        ),
                        SizedBox(
                          // color: AppColors.wtColor,
                          width: double.infinity,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GetBuilder<CartController>(
                                builder: (cartController) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault + 2),
                                    child: Row(children: [
                                      // +

                                      QuantityButton(
                                        isIncrement: true,
                                        color: null,
                                        onTap: () {
                                                // 🔥 BUG FIX: Guard cartList[0] access before accessing moduleId
                                                final cartController = Get.find<CartController>();
                                                if (cartController.cartList.isNotEmpty && cartController.cartList[0].item?.moduleId != null) {
                                                  cartController.forcefullySetModule(
                                                      context, cartController.cartList[0].item!.moduleId!);
                                                }
                                                // 🔥 BUG FIX: Use cart_id instead of index (safe, index-independent)
                                                if (cart.id != null) {
                                                  cartController.setQuantityById(true, cart.id!, cart.stock, cart.quantityLimit);
                                                } else {
                                                  // Fallback for items without cart_id
                                                  // ignore: deprecated_member_use_from_same_package
                                                  cartController.setQuantity(true, cartIndex, cart.stock, cart.quantityLimit);
                                                }
                                              },
                                      ),
                                      Text(
                                        cart.quantity.toString(),
                                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                                      ),

                                      // -

                                      QuantityButton(
                                        isIncrement: false,
                                        showRemoveIcon: cart.quantity! == 1,
                                        onTap: () {
                                                // 🔥 BUG FIX: Use cart_id instead of index (safe, index-independent)
                                                if (cart.id != null) {
                                                  if (cart.quantity! > 1) {
                                                    Get.find<CartController>().setQuantityById(false, cart.id!, cart.stock, cart.quantityLimit);
                                                  } else {
                                                    Get.find<CartController>().removeFromCartById(cart.id!, item: cart.item, reason: 'quantity_decrement');
                                                  }
                                                } else {
                                                  // Fallback for items without cart_id
                                                  if (cart.quantity! > 1) {
                                                    // ignore: deprecated_member_use_from_same_package
                                                    Get.find<CartController>().setQuantity(false, cartIndex, cart.stock, cart.quantityLimit);
                                                  } else {
                                                    // ignore: deprecated_member_use_from_same_package
                                                    Get.find<CartController>().removeFromCart(cartIndex, item: cart.item);
                                                  }
                                                }
                                              },
                                      ),
                                    ]),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: Dimensions.paddingSizeSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double? _calculatePriceWithVariation({required Item? item, bool isStartingPrice = true}) {
    double? startingPrice;
    double? endingPrice;
    final bool newVariation = Get.find<SplashController>().getModuleConfig(item!.moduleType).newVariation ?? false;

    if (item.variations!.isNotEmpty && !newVariation) {
      final List<double?> priceList = [];
      for (final variation in item.variations!) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
      if (priceList[0]! < priceList[priceList.length - 1]!) {
        endingPrice = priceList[priceList.length - 1];
      }
    } else {
      startingPrice = item.price;
    }
    if (isStartingPrice) {
      return startingPrice;
    } else {
      return endingPrice;
    }
  }

  // ignore: unused_element
  String? _setupVariationText({required CartModel cart}) {
    String? variationText = '';

    if ((Get.find<SplashController>().getModuleConfig(cart.item!.moduleType).newVariation ?? false)) {
      if (cart.foodVariations!.isNotEmpty) {
        for (int index = 0; index < cart.foodVariations!.length; index++) {
          if (cart.foodVariations![index].contains(true)) {
            variationText = '${variationText!}${variationText.isNotEmpty ? ', ' : ''}${cart.item!.foodVariations![index].name} (';
            for (int i = 0; i < cart.foodVariations![index].length; i++) {
              if (cart.foodVariations![index][i]!) {
                variationText =
                    '${variationText!}${variationText.endsWith('(') ? '' : ', '}${cart.item!.foodVariations![index].variationValues![i].level}';
              }
            }
            variationText = '${variationText!})';
          }
        }
      }
    } else {
      if (cart.variation!.isNotEmpty) {
        final List<String> variationTypes = cart.variation![0].type!.split('-');
        if (variationTypes.length == cart.item!.choiceOptions!.length) {
          int index0 = 0;
          for (final choice in cart.item!.choiceOptions!) {
            variationText = '${variationText!}${(index0 == 0) ? '' : ',  '}${choice.title} - ${variationTypes[index0]}';
            index0 = index0 + 1;
          }
        } else {
          variationText = cart.item!.variations![0].type;
        }
      }
    }
    return variationText;
  }

  // ignore: unused_element
  String? _setupAddonsText({required CartModel cart}) {
    String addOnText = '';
    int index0 = 0;
    final List<int?> ids = [];
    final List<int?> qtys = [];
    for (final addOn in cart.addOnIds!) {
      ids.add(addOn.id);
      qtys.add(addOn.quantity);
    }
    for (final addOn in cart.item!.addOns!) {
      if (ids.contains(addOn.id)) {
        addOnText = '$addOnText${(index0 == 0) ? '' : ',  '}${addOn.name} (${qtys[index0]})';
        index0 = index0 + 1;
      }
    }
    return addOnText;
  }
}
