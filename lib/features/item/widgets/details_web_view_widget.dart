import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/item/widgets/quantity_button.dart';
import 'package:sixam_mart/features/item/widgets/item_title_view_widget.dart';

class DetailsWebViewWidget extends StatelessWidget {
  final CartModel? cartModel;
  final int? stock;
  final double priceWithAddOns;
  final OnlineCart? cart;
  const DetailsWebViewWidget(
      {super.key,
      required this.cartModel,
      required this.stock,
      required this.priceWithAddOns,
      this.cart});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemController>(builder: (itemController) {
      final List<String?> imageList = [];
      imageList.add(itemController.item!.imageFullUrl);
      if (itemController.item!.imagesFullUrl != null) {
        imageList.addAll(itemController.item!.imagesFullUrl!);
      }

      return SingleChildScrollView(
          child: FooterView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 560),
          child: Column(children: [
            const SizedBox(height: 20),
            Center(
                child: SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 4,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(
                                      height: Get.size.height * 0.5,
                                      child: CustomImage(
                                        image:
                                            '${imageList[itemController.productSelect]}',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 70,
                                      child: itemController
                                                  .item!.imageFullUrl !=
                                              null
                                          ? ListView.builder(
                                              itemCount: imageList.length,
                                              scrollDirection: Axis.horizontal,
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .only(
                                                      right: Dimensions
                                                          .paddingSizeSmall),
                                                  child: InkWell(
                                                    onTap: () => itemController
                                                        .setSelect(index, true),
                                                    child: Container(
                                                      width: 70,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius
                                                            .circular(Dimensions
                                                                .radiusSmall),
                                                        border: Border.all(
                                                            color: index ==
                                                                    itemController
                                                                        .productSelect
                                                                ? Theme.of(
                                                                        context)
                                                                    .primaryColor
                                                                : Theme.of(
                                                                        context)
                                                                    .disabledColor,
                                                            width: index ==
                                                                    itemController
                                                                        .productSelect
                                                                ? 2
                                                                : 1),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2),
                                                      child: CustomImage(
                                                        image:
                                                            '${imageList[index]}',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : const SizedBox(),
                                    )
                                  ],
                                ),
                              )),
                          const SizedBox(width: 40),
                          Expanded(
                              flex: 6,
                              child: SingleChildScrollView(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ItemTitleViewWidget(
                                        item: itemController.item,
                                        inStock: false,
                                      ),
                                      (itemController.item!.description !=
                                                  null &&
                                              itemController.item!.description!
                                                  .isNotEmpty)
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeSmall),
                                                Text('description'.tr,
                                                    style: robotoMedium),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeExtraSmall),
                                                Text(
                                                  itemController
                                                      .item!.description!,
                                                  style: robotoRegular,
                                                  maxLines:
                                                      itemController.isReadMore
                                                          ? 10
                                                          : 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                itemController
                                                            .item!
                                                            .description!
                                                            .length >
                                                        150
                                                    ? InkWell(
                                                        onTap: () =>
                                                            itemController
                                                                .changeReadMore(),
                                                        child: Text(
                                                          itemController
                                                                  .isReadMore
                                                              ? 'read_less'.tr
                                                              : 'read_more'.tr,
                                                          style: robotoRegular.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor),
                                                        ),
                                                      )
                                                    : const SizedBox(),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeLarge),
                                              ],
                                            )
                                          : const SizedBox(),
                                      // Nutrition values (calories, protein, carbs, etc.)
                                      (itemController.item?.nutrition != null)
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('nutrition_details'.tr,
                                                    style: robotoMedium),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeExtraSmall),
                                                // Calories
                                                if (itemController.item!
                                                        .nutrition!.calories !=
                                                    null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8.0),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .local_fire_department,
                                                          size: 18,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          '${itemController.item!.nutrition!.calories} ${'calories'.tr}',
                                                          style: robotoMedium
                                                              .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                // Nutrition breakdown
                                                if (itemController
                                                            .item!
                                                            .nutrition!
                                                            .protein !=
                                                        null ||
                                                    itemController.item!
                                                            .nutrition!.carbs !=
                                                        null ||
                                                    itemController.item!
                                                            .nutrition!.fat !=
                                                        null ||
                                                    itemController.item!
                                                            .nutrition!.fiber !=
                                                        null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8.0),
                                                    child: Wrap(
                                                      spacing: 16,
                                                      runSpacing: 8,
                                                      children: [
                                                        if (itemController
                                                                .item!
                                                                .nutrition!
                                                                .protein !=
                                                            null)
                                                          DetailsWebViewWidget
                                                              ._buildNutritionItem(
                                                            context,
                                                            'protein'.tr,
                                                            '${itemController.item!.nutrition!.protein!.toStringAsFixed(1)}g',
                                                          ),
                                                        if (itemController
                                                                .item!
                                                                .nutrition!
                                                                .carbs !=
                                                            null)
                                                          DetailsWebViewWidget
                                                              ._buildNutritionItem(
                                                            context,
                                                            'carbs'.tr,
                                                            '${itemController.item!.nutrition!.carbs!.toStringAsFixed(1)}g',
                                                          ),
                                                        if (itemController
                                                                .item!
                                                                .nutrition!
                                                                .fat !=
                                                            null)
                                                          DetailsWebViewWidget
                                                              ._buildNutritionItem(
                                                            context,
                                                            'fat'.tr,
                                                            '${itemController.item!.nutrition!.fat!.toStringAsFixed(1)}g',
                                                          ),
                                                        if (itemController
                                                                .item!
                                                                .nutrition!
                                                                .fiber !=
                                                            null)
                                                          DetailsWebViewWidget
                                                              ._buildNutritionItem(
                                                            context,
                                                            'fiber'.tr,
                                                            '${itemController.item!.nutrition!.fiber!.toStringAsFixed(1)}g',
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                // Nutrition tags (if available)
                                                if (itemController.item!
                                                            .nutritionsName !=
                                                        null &&
                                                    itemController
                                                        .item!
                                                        .nutritionsName!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(
                                                      height: Dimensions
                                                          .paddingSizeSmall),
                                                  Wrap(
                                                      children: List.generate(
                                                          itemController
                                                              .item!
                                                              .nutritionsName!
                                                              .length, (index) {
                                                    return Text(
                                                      '${itemController.item!.nutritionsName![index]}${itemController.item!.nutritionsName!.length - 1 == index ? '.' : ', '}',
                                                      style: robotoRegular
                                                          .copyWith(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge!
                                                            .color
                                                            ?.withValues(
                                                                alpha: 0.5),
                                                      ),
                                                    );
                                                  })),
                                                ],
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeLarge),
                                              ],
                                            )
                                          // Fallback to nutrition tags only if nutrition object is null
                                          : (itemController.item!
                                                          .nutritionsName !=
                                                      null &&
                                                  itemController
                                                      .item!
                                                      .nutritionsName!
                                                      .isNotEmpty)
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('nutrition_details'.tr,
                                                        style: robotoMedium),
                                                    const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeExtraSmall),
                                                    Wrap(
                                                        children: List.generate(
                                                            itemController
                                                                .item!
                                                                .nutritionsName!
                                                                .length,
                                                            (index) {
                                                      return Text(
                                                        '${itemController.item!.nutritionsName![index]}${itemController.item!.nutritionsName!.length - 1 == index ? '.' : ', '}',
                                                        style: robotoRegular
                                                            .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyLarge!
                                                                    .color
                                                                    ?.withValues(
                                                                        alpha:
                                                                            0.5)),
                                                      );
                                                    })),
                                                    const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeLarge),
                                                  ],
                                                )
                                              : const SizedBox(),
                                      (itemController.item!.allergiesName !=
                                                  null &&
                                              itemController.item!
                                                  .allergiesName!.isNotEmpty)
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('allergic_ingredients'.tr,
                                                    style: robotoMedium),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeExtraSmall),
                                                Wrap(
                                                    children: List.generate(
                                                        itemController
                                                            .item!
                                                            .allergiesName!
                                                            .length, (index) {
                                                  return Text(
                                                    '${itemController.item!.allergiesName![index]}${itemController.item!.allergiesName!.length - 1 == index ? '.' : ', '}',
                                                    style:
                                                        robotoRegular.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyLarge!
                                                                .color
                                                                ?.withValues(
                                                                    alpha:
                                                                        0.5)),
                                                  );
                                                })),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeLarge),
                                              ],
                                            )
                                          : const SizedBox(),
                                      itemController
                                              .item!.isPrescriptionRequired!
                                          ? Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: Dimensions
                                                      .paddingSizeSmall,
                                                  vertical: Dimensions
                                                      .paddingSizeExtraSmall),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Dimensions.radiusSmall),
                                              ),
                                              child: Text(
                                                '* ${'prescription_required'.tr}',
                                                style: robotoRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                              ),
                                            )
                                          : const SizedBox(),
                                      const SizedBox(height: 30),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: itemController
                                            .item!.choiceOptions!.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (context, index) {
                                          return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    itemController
                                                        .item!
                                                        .choiceOptions![index]
                                                        .title!,
                                                    style: robotoMedium.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeLarge)),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeExtraSmall),
                                                Text('select_one'.tr,
                                                    style:
                                                        robotoRegular.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .disabledColor,
                                                            fontSize: Dimensions
                                                                .fontSizeSmall)),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeSmall),
                                                GridView.builder(
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 3,
                                                    crossAxisSpacing: 20,
                                                    mainAxisSpacing: 10,
                                                    childAspectRatio:
                                                        ResponsiveHelper
                                                                .isDesktop(
                                                                    context)
                                                            ? 6.5
                                                            : (1 / 0.25),
                                                  ),
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: itemController
                                                      .item!
                                                      .choiceOptions![index]
                                                      .options!
                                                      .length,
                                                  itemBuilder: (context, i) {
                                                    return InkWell(
                                                      onTap: () {
                                                        itemController
                                                            .setCartVariationIndex(
                                                                index,
                                                                i,
                                                                itemController
                                                                    .item);
                                                      },
                                                      child: Container(
                                                        alignment:
                                                            Alignment.center,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: Dimensions
                                                                .paddingSizeExtraSmall),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: itemController
                                                                          .variationIndex![
                                                                      index] !=
                                                                  i
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .surface
                                                              : Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .radiusSmall),
                                                          border: itemController
                                                                          .variationIndex![
                                                                      index] !=
                                                                  i
                                                              ? Border.all(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .disabledColor)
                                                              : null,
                                                        ),
                                                        child: Text(
                                                          itemController
                                                              .item!
                                                              .choiceOptions![
                                                                  index]
                                                              .options![i]
                                                              .trim(),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: robotoRegular
                                                              .copyWith(
                                                            color: itemController
                                                                            .variationIndex![
                                                                        index] !=
                                                                    i
                                                                ? Theme.of(
                                                                        context)
                                                                    .disabledColor
                                                                : Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                SizedBox(
                                                    height: index !=
                                                            itemController
                                                                    .item!
                                                                    .choiceOptions!
                                                                    .length -
                                                                1
                                                        ? Dimensions
                                                            .paddingSizeLarge
                                                        : 0),
                                              ]);
                                        },
                                      ),
                                      const SizedBox(height: 30),
                                      GetBuilder<CartController>(
                                          builder: (cartController) {
                                        return Row(children: [
                                          Text('${'total_amount'.tr}:',
                                              style: robotoMedium.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeLarge)),
                                          const SizedBox(
                                              width: Dimensions
                                                  .paddingSizeExtraSmall),
                                          PriceConverter.convertPrice2(
                                            itemController.cartIndex != -1
                                                ? _getItemDetailsDiscountPrice(
                                                    cart: Get.find<
                                                                CartController>()
                                                            .cartList[
                                                        itemController
                                                            .cartIndex])
                                                : priceWithAddOns,
                                            textStyle: robotoBold.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                            ),
                                          ),
                                        ]);
                                      }),
                                      const SizedBox(height: 30),
                                      Row(children: [
                                        GetBuilder<CartController>(
                                            builder: (cartController) {
                                          return Row(children: [
                                            QuantityButton(
                                              isIncrement: false,
                                              quantity:
                                                  itemController.cartIndex != -1
                                                      ? cartController
                                                          .cartList[
                                                              itemController
                                                                  .cartIndex]
                                                          .quantity
                                                      : itemController.quantity,
                                              stock: stock,
                                              isExistInCart:
                                                  itemController.cartIndex !=
                                                      -1,
                                              cartIndex:
                                                  itemController.cartIndex,
                                              quantityLimit:
                                                  itemController.cartIndex != -1
                                                      ? cartController
                                                          .cartList[
                                                              itemController
                                                                  .cartIndex]
                                                          .quantityLimit
                                                      : itemController
                                                          .item!.quantityLimit,
                                              cartController: cartController,
                                            ),
                                            const SizedBox(width: 30),
                                            Text(
                                              itemController.cartIndex != -1
                                                  ? cartController
                                                      .cartList[itemController
                                                          .cartIndex]
                                                      .quantity
                                                      .toString()
                                                  : itemController.quantity
                                                      .toString(),
                                              style: robotoBold.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeExtraLarge),
                                            ),
                                            const SizedBox(width: 30),
                                            QuantityButton(
                                              isIncrement: true,
                                              quantity:
                                                  itemController.cartIndex != -1
                                                      ? cartController
                                                          .cartList[
                                                              itemController
                                                                  .cartIndex]
                                                          .quantity
                                                      : itemController.quantity,
                                              stock: stock,
                                              cartIndex:
                                                  itemController.cartIndex,
                                              isExistInCart:
                                                  itemController.cartIndex !=
                                                      -1,
                                              quantityLimit:
                                                  itemController.cartIndex != -1
                                                      ? cartController
                                                          .cartList[
                                                              itemController
                                                                  .cartIndex]
                                                          .quantityLimit
                                                      : itemController
                                                          .item!.quantityLimit,
                                              cartController: cartController,
                                            ),
                                          ]);
                                        }),
                                        const SizedBox(
                                            width: Dimensions.paddingSizeLarge),
                                        GetBuilder<CartController>(
                                            builder: (cartController) {
                                          return CustomButton(
                                            width: 300,
                                            isLoading: cartController.isLoading,
                                            buttonText: itemController.item!
                                                        .availableDateStarts !=
                                                    null
                                                ? 'order_now'.tr
                                                : 'add_to_cart'.tr,
                                            onPressed: () async {
                                              if (itemController.item!
                                                      .availableDateStarts !=
                                                  null) {
                                                Get.toNamed<void>(
                                                    RouteHelper
                                                        .getCampaignCheckoutRoute(),
                                                    arguments: CheckoutScreen(
                                                      storeId: null,
                                                      fromCart: false,
                                                      cartList: [cartModel],
                                                    ));
                                              } else if (Get.find<
                                                      CartController>()
                                                  .existAnotherStoreItem(
                                                      cartModel!.item!.storeId,
                                                      Get.find<
                                                              SplashController>()
                                                          .module!
                                                          .id)) {
                                                Get.dialog<void>(
                                                    ConfirmationDialog(
                                                      icon: Images.warning,
                                                      title:
                                                          'are_you_sure_to_reset'
                                                              .tr,
                                                      description: Get.find<
                                                                  SplashController>()
                                                              .configModel!
                                                              .moduleConfig!
                                                              .module!
                                                              .showRestaurantText!
                                                          ? 'if_you_continue'.tr
                                                          : 'if_you_continue_without_another_store'
                                                              .tr,
                                                      onYesPressed: () {
                                                        Get.back<void>();
                                                        cartController
                                                            .clearCartOnline()
                                                            .then(
                                                                (success) async {
                                                          if (success) {
                                                            await cartController
                                                                .addToCartWithFallback(
                                                              cartModel:
                                                                  cartModel!,
                                                              onlineCart: cart!,
                                                            );
                                                            itemController
                                                                .setExistInCart(
                                                                    itemController
                                                                        .item,
                                                                    null);
                                                            if (!context
                                                                .mounted) {
                                                              return;
                                                            }
                                                            showCartSnackBar(
                                                                context);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    barrierDismissible: false);
                                              } else {
                                                // Use smart cart method that automatically chooses add or update
                                                await cartController
                                                    .addToCartWithFallback(
                                                  cartModel: cartModel!,
                                                  onlineCart: cart!,
                                                )
                                                    .then((success) {
                                                  if (success) {
                                                    itemController
                                                        .setExistInCart(
                                                            itemController.item,
                                                            null);
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    showCartSnackBar(context);
                                                  }
                                                });
                                              }
                                            },
                                          );
                                        }),
                                      ]),
                                      const SizedBox(
                                          height: Dimensions
                                              .paddingSizeExtremeLarge),
                                    ]),
                              )),
                        ]))),
          ]),
        ),
      ));
    });
  }

  double _getItemDetailsDiscountPrice({required CartModel cart}) {
    // ✅ Backend already calculated discount - cart.price is already discounted!
    // Don't recalculate - just multiply by quantity
    double discountedPrice = 0;
    final String variationType =
        cart.variation != null && cart.variation!.isNotEmpty
            ? cart.variation![0].type!
            : '';

    if (cart.variation != null && cart.variation!.isNotEmpty) {
      // Find the variation price (already discounted by backend)
      for (final Variation variation in cart.item!.variations!) {
        if (variation.type == variationType) {
          discountedPrice = variation.price! * cart.quantity!;
          break;
        }
      }
    } else {
      // ✅ cart.price is already discounted by backend - just multiply
      discountedPrice = cart.price! * cart.quantity!;
    }

    return discountedPrice;
  }

  static Widget _buildNutritionItem(
      BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
