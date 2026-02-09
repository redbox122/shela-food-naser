import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/item/widgets/details_app_bar_widget.dart';
import 'package:sixam_mart/features/item/widgets/details_web_view_widget.dart';
import 'package:sixam_mart/features/item/widgets/item_image_view_widget.dart';
import 'package:sixam_mart/features/item/widgets/item_title_view_widget.dart';
import 'package:sixam_mart/common/widgets/food_variation_section.dart';

import '../../../common/widgets/item_widget.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item? item;
  final List<Item>? itemList;
  final bool inStorePage;
  final bool? isCampaign;
  const ItemDetailsScreen(
      {super.key,
      required this.item,
      required this.inStorePage,
      this.isCampaign,
      this.itemList});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final Size size = Get.size;
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  final GlobalKey<DetailsAppBarWidgetState> _key = GlobalKey();

  @override
  void initState() {
    super.initState();

    // ⚡ SILICON VALLEY WAY: Use widget.item immediately for instant UI (0ms perceived load)
    // Set item in controller immediately so header shows name/image instantly
    // ⚠️ FIX: Use post-frame callback to prevent "setState during build" error
    // Flutter prohibits any setState/update() calls during the build phase
    if (widget.item != null) {
      final itemController = Get.find<ItemController>();
      final hasBasicData =
          widget.item!.name != null || widget.item!.imageFullUrl != null;
      if (hasBasicData) {
        // ⚡ FIX: Defer setItemMiniCache to post-frame callback to avoid "setState during build"
        WidgetsBinding.instance.addPostFrameCallback((_) {
          itemController.setItemMiniCache(widget.item!);
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            debugPrint(
                '⚡ ItemDetailsScreen: Item header visible instantly (0ms) - using widget.item');
          }
        });
      }
    }

    // ⚡ BACKGROUND FETCH: Only fetch additional details in background (not basic info)
    // This makes the app feel "Lightning Fast" even if internet is slow
    if (widget.item != null) {
      final itemController = Get.find<ItemController>();
      // Fetch additional details in background (non-blocking)
      itemController.getProductDetails(widget.item!).then((_) {
        itemController.setSelect(0, false);
        itemController.getSimilarProducts(widget.item!.categoryId.toString());
      }).catchError((Object e) {
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          debugPrint('❌ ItemDetailsScreen: Error fetching item details: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<ItemController>(
        builder: (itemController) {
          final details = itemController.detailsViewData;
          final int stock = details.stock;
          final CartModel? cartModel = details.cartModel;
          final OnlineCart? cart = details.cart;
          final double priceWithAddons = details.priceWithAddons;

          return Scaffold(
            key: _globalKey,
            backgroundColor: Theme.of(context).cardColor,
            endDrawerEnableOpenDragGesture: false,
            appBar: ResponsiveHelper.isDesktop(context)
                ? const CustomAppBar(title: '')
                : DetailsAppBarWidget(key: _key),
            body: SafeArea(
                child: (itemController.item != null)
                    ? ResponsiveHelper.isDesktop(context)
                        ? DetailsWebViewWidget(
                            cartModel: cartModel,
                            stock: stock,
                            priceWithAddOns: priceWithAddons,
                            cart: cart,
                          )
                        : Column(children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeSmall),
                                physics: const BouncingScrollPhysics(),
                                child: Center(
                                  child: SizedBox(
                                    width: Dimensions.webMaxWidth,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ItemImageViewWidget(
                                            item: itemController.item,
                                            isCampaign:
                                                widget.isCampaign ?? false),
                                        const SizedBox(height: 20),

                                        Builder(builder: (context) {
                                          return ItemTitleViewWidget(
                                            item: itemController.item,
                                            inStorePage: widget.inStorePage,
                                            isCampaign: itemController.item!
                                                    .availableDateStarts !=
                                                null,
                                            inStock: false,
                                          );
                                        }),
                                        const Divider(height: 20, thickness: 2),

                                        // ✅ DATA-DRIVEN MORPHING: Priority 1 - Food Variations (Coffee, Food modules)
                                        if (itemController
                                                    .item?.foodVariations !=
                                                null &&
                                            itemController.item!.foodVariations!
                                                .isNotEmpty)
                                          Column(
                                            children: [
                                              FoodVariationSection(
                                                foodVariations: itemController
                                                    .item!.foodVariations!,
                                                item: itemController.item!,
                                                selectedVariations:
                                                    itemController
                                                        .selectedVariations,
                                                onVariationSelected:
                                                    (variationIndex,
                                                        optionIndex) {
                                                  itemController
                                                      .setNewCartVariationIndex(
                                                          variationIndex,
                                                          optionIndex,
                                                          itemController.item!);
                                                },
                                              ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeLarge),
                                            ],
                                          )
                                        // ✅ DATA-DRIVEN MORPHING: Priority 2 - eCommerce Variations (choiceOptions + variations)
                                        else if (itemController
                                                    .item?.choiceOptions !=
                                                null &&
                                            itemController.item!.choiceOptions!
                                                .isNotEmpty &&
                                            itemController.variationIndex !=
                                                null)
                                          Column(
                                            children: [
                                              ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: itemController.item!
                                                    .choiceOptions!.length,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemBuilder: (context, index) {
                                                  return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            itemController
                                                                .item!
                                                                .choiceOptions![
                                                                    index]
                                                                .title!,
                                                            style: robotoMedium
                                                                .copyWith(
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeLarge)),
                                                        const SizedBox(
                                                            height: Dimensions
                                                                .paddingSizeExtraSmall),
                                                        GridView.builder(
                                                          gridDelegate:
                                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                            crossAxisCount: 3,
                                                            crossAxisSpacing:
                                                                20,
                                                            mainAxisSpacing: 10,
                                                            childAspectRatio:
                                                                (1 / 0.25),
                                                          ),
                                                          shrinkWrap: true,
                                                          physics:
                                                              const NeverScrollableScrollPhysics(),
                                                          itemCount:
                                                              itemController
                                                                  .item!
                                                                  .choiceOptions![
                                                                      index]
                                                                  .options!
                                                                  .length,
                                                          itemBuilder:
                                                              (context, i) {
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
                                                                    Alignment
                                                                        .center,
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        Dimensions
                                                                            .paddingSizeExtraSmall),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: (itemController.variationIndex !=
                                                                              null &&
                                                                          index <
                                                                              itemController
                                                                                  .variationIndex!.length &&
                                                                          itemController.variationIndex![index] !=
                                                                              i)
                                                                      ? Theme.of(
                                                                              context)
                                                                          .disabledColor
                                                                      : Theme.of(
                                                                              context)
                                                                          .primaryColor,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5),
                                                                  border: (itemController.variationIndex !=
                                                                              null &&
                                                                          index <
                                                                              itemController
                                                                                  .variationIndex!.length &&
                                                                          itemController.variationIndex![index] !=
                                                                              i)
                                                                      ? Border.all(
                                                                          color: Theme.of(context)
                                                                              .disabledColor,
                                                                          width:
                                                                              2)
                                                                      : null,
                                                                ),
                                                                child: Text(
                                                                  itemController
                                                                      .item!
                                                                      .choiceOptions![
                                                                          index]
                                                                      .options![
                                                                          i]
                                                                      .trim(),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: robotoRegular
                                                                      .copyWith(
                                                                    color: (itemController.variationIndex !=
                                                                                null &&
                                                                            index <
                                                                                itemController
                                                                                    .variationIndex!.length &&
                                                                            itemController.variationIndex![index] !=
                                                                                i)
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
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
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeLarge),
                                            ],
                                          ),
                                        // ✅ DATA-DRIVEN MORPHING: Priority 3 - Simple Product (no variations - direct add to cart)

                                        // Quantity

                                        GetBuilder<CartController>(
                                            builder: (cartController) {
                                          return Row(children: [
                                            Text('quantity'.tr,
                                                style: robotoMedium.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeLarge)),
                                            const Expanded(child: SizedBox()),
                                            Container(
                                              decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .disabledColor,
                                                  borderRadius:
                                                      BorderRadius.circular(5)),
                                              child: Row(children: [
                                                // -

                                                InkWell(
                                                  onTap:
                                                      cartController.isLoading
                                                          ? null
                                                          : () {
                                                              HapticFeedback
                                                                  .lightImpact();
                                                              if (itemController
                                                                      .cartIndex !=
                                                                  -1) {
                                                                if (cartController
                                                                        .cartList[
                                                                            itemController.cartIndex]
                                                                        .quantity! >
                                                                    1) {
                                                                  // 🔥 FIX: Use cart_id instead of index
                                                                  final cartItem = cartController
                                                                          .cartList[
                                                                      itemController
                                                                          .cartIndex];
                                                                  if (cartItem
                                                                          .id ==
                                                                      null) {
                                                                    showCustomSnackBar(
                                                                        'something_went_wrong'
                                                                            .tr);
                                                                    return;
                                                                  }
                                                                  cartController
                                                                      .setQuantityById(
                                                                    false,
                                                                    cartItem
                                                                        .id!,
                                                                    stock,
                                                                    cartItem
                                                                        .quantity,
                                                                  );
                                                                }
                                                              } else {
                                                                if (itemController
                                                                        .quantity! >
                                                                    1) {
                                                                  itemController.setQuantity(
                                                                      false,
                                                                      stock,
                                                                      itemController
                                                                          .item!
                                                                          .quantityLimit);
                                                                }
                                                              }
                                                            },
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal: Dimensions
                                                            .paddingSizeSmall,
                                                        vertical: Dimensions
                                                            .paddingSizeExtraSmall),
                                                    child: Icon(Icons.remove,
                                                        size: 20),
                                                  ),
                                                ),

                                                //

                                                Text(
                                                  (itemController.cartIndex !=
                                                              -1 &&
                                                          cartController
                                                              .cartList
                                                              .isNotEmpty &&
                                                          itemController
                                                                  .cartIndex <
                                                              cartController
                                                                  .cartList
                                                                  .length)
                                                      ? cartController
                                                          .cartList[
                                                              itemController
                                                                  .cartIndex]
                                                          .quantity
                                                          .toString()
                                                      : itemController.quantity
                                                          .toString(),
                                                  style: robotoMedium.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraLarge),
                                                ),

                                                // +

                                                InkWell(
                                                  onTap:
                                                      cartController.isLoading
                                                          ? null
                                                          : () {
                                                              HapticFeedback
                                                                  .lightImpact();
                                                              if (itemController
                                                                      .cartIndex !=
                                                                  -1) {
                                                                // 🔥 FIX: Use cart_id instead of index
                                                                if (itemController
                                                                            .cartIndex <
                                                                        0 ||
                                                                    itemController
                                                                            .cartIndex >=
                                                                        cartController
                                                                            .cartList
                                                                            .length) {
                                                                  itemController
                                                                      .cartIndexSet();
                                                                  showCustomSnackBar(
                                                                      'something_went_wrong'
                                                                          .tr);
                                                                  return;
                                                                }
                                                                final cartItem =
                                                                    cartController
                                                                            .cartList[
                                                                        itemController
                                                                            .cartIndex];
                                                                if (cartItem
                                                                        .id ==
                                                                    null) {
                                                                  showCustomSnackBar(
                                                                      'something_went_wrong'
                                                                          .tr);
                                                                  return;
                                                                }
                                                                cartController
                                                                    .setQuantityById(
                                                                  true,
                                                                  cartItem.id!,
                                                                  stock,
                                                                  cartItem
                                                                      .quantityLimit,
                                                                );
                                                              } else {
                                                                itemController.setQuantity(
                                                                    true,
                                                                    stock,
                                                                    itemController
                                                                        .item!
                                                                        .quantityLimit);
                                                              }
                                                            },
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal: Dimensions
                                                            .paddingSizeSmall,
                                                        vertical: Dimensions
                                                            .paddingSizeExtraSmall),
                                                    child: Icon(Icons.add,
                                                        size: 20),
                                                  ),
                                                ),
                                              ]),
                                            ),
                                          ]);
                                        }),

                                        //

                                        const SizedBox(
                                            height:
                                                Dimensions.paddingSizeLarge),

                                        Row(children: [
                                          Text('${'total_amount'.tr}:',
                                              style: robotoMedium.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeLarge)),
                                          const SizedBox(
                                              width: Dimensions
                                                  .paddingSizeExtraSmall),
                                          PriceConverter.convertPrice2(
                                            (itemController.cartIndex != -1 &&
                                                    Get.find<CartController>()
                                                        .cartList
                                                        .isNotEmpty &&
                                                    itemController.cartIndex <
                                                        Get.find<
                                                                CartController>()
                                                            .cartList
                                                            .length)
                                                ? _getItemDetailsDiscountPrice(
                                                    cart: Get.find<
                                                                CartController>()
                                                            .cartList[
                                                        itemController
                                                            .cartIndex])
                                                : priceWithAddons,
                                            textStyle: robotoBold.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                            ),
                                          ),
                                        ]),

                                        //

                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraLarge),

                                        // ⚠️ FIX: Null-safe check for isPrescriptionRequired to prevent crash
                                        // Mini-cache may not include this field, so check safely
                                        (itemController.item
                                                    ?.isPrescriptionRequired ==
                                                true)
                                            ? Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: Dimensions
                                                        .paddingSizeSmall,
                                                    vertical: Dimensions
                                                        .paddingSizeExtraSmall),
                                                margin: const EdgeInsets.only(
                                                    bottom: Dimensions
                                                        .paddingSizeSmall),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Dimensions
                                                              .radiusSmall),
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

                                        (itemController.item!.description !=
                                                    null &&
                                                itemController.item!
                                                    .description!.isNotEmpty)
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('description'.tr,
                                                      style: robotoMedium),
                                                  const SizedBox(
                                                      height: Dimensions
                                                          .paddingSizeExtraSmall),
                                                  Text(
                                                      itemController
                                                          .item!.description!,
                                                      style: robotoRegular),
                                                  const SizedBox(
                                                      height: Dimensions
                                                          .paddingSizeLarge),
                                                ],
                                              )
                                            : const SizedBox(),

                                        // Nutrition values (calories, protein, carbs, etc.)
                                        (_hasNutritionData(itemController))
                                            ? (itemController.item?.nutrition !=
                                                    null)
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          'nutrition_details'
                                                              .tr,
                                                          style: robotoMedium),
                                                      const SizedBox(
                                                          height: Dimensions
                                                              .paddingSizeExtraSmall),
                                                      // Calories
                                                      if (itemController
                                                                  .item!
                                                                  .nutrition!
                                                                  .calories !=
                                                              null &&
                                                          itemController
                                                                  .item!
                                                                  .nutrition!
                                                                  .calories! >
                                                              0)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 8.0),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .local_fire_department,
                                                                size: 18,
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                '${itemController.item!.nutrition!.calories} ${'calories'.tr}',
                                                                style:
                                                                    robotoMedium
                                                                        .copyWith(
                                                                  fontSize:
                                                                      Dimensions
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
                                                          itemController
                                                                  .item!
                                                                  .nutrition!
                                                                  .carbs !=
                                                              null ||
                                                          itemController
                                                                  .item!
                                                                  .nutrition!
                                                                  .fat !=
                                                              null ||
                                                          itemController
                                                                  .item!
                                                                  .nutrition!
                                                                  .fiber !=
                                                              null)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
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
                                                                _buildNutritionItem(
                                                                  context,
                                                                  'protein'.tr,
                                                                  '${itemController.item!.nutrition!.protein!.toStringAsFixed(1)}g',
                                                                ),
                                                              if (itemController
                                                                      .item!
                                                                      .nutrition!
                                                                      .carbs !=
                                                                  null)
                                                                _buildNutritionItem(
                                                                  context,
                                                                  'carbs'.tr,
                                                                  '${itemController.item!.nutrition!.carbs!.toStringAsFixed(1)}g',
                                                                ),
                                                              if (itemController
                                                                      .item!
                                                                      .nutrition!
                                                                      .fat !=
                                                                  null)
                                                                _buildNutritionItem(
                                                                  context,
                                                                  'fat'.tr,
                                                                  '${itemController.item!.nutrition!.fat!.toStringAsFixed(1)}g',
                                                                ),
                                                              if (itemController
                                                                      .item!
                                                                      .nutrition!
                                                                      .fiber !=
                                                                  null)
                                                                _buildNutritionItem(
                                                                  context,
                                                                  'fiber'.tr,
                                                                  '${itemController.item!.nutrition!.fiber!.toStringAsFixed(1)}g',
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      // Nutrition tags (if available)
                                                      if (widget.item!
                                                                  .nutritionsName !=
                                                              null &&
                                                          widget
                                                              .item!
                                                              .nutritionsName!
                                                              .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: Dimensions
                                                                .paddingSizeSmall),
                                                        Wrap(
                                                            children: List.generate(
                                                                widget
                                                                    .item!
                                                                    .nutritionsName!
                                                                    .length,
                                                                (index) {
                                                          return Text(
                                                            '${widget.item!.nutritionsName![index]}${widget.item!.nutritionsName!.length - 1 == index ? '.' : ', '}',
                                                            style: robotoRegular
                                                                .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .color
                                                                  ?.withValues(
                                                                      alpha:
                                                                          0.5),
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
                                                : (widget.item!.nutritionsName !=
                                                            null &&
                                                        widget
                                                            .item!
                                                            .nutritionsName!
                                                            .isNotEmpty)
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              'nutrition_details'
                                                                  .tr,
                                                              style:
                                                                  robotoMedium),
                                                          const SizedBox(
                                                              height: Dimensions
                                                                  .paddingSizeExtraSmall),
                                                          Wrap(
                                                              children: List.generate(
                                                                  widget
                                                                      .item!
                                                                      .nutritionsName!
                                                                      .length,
                                                                  (index) {
                                                            return Text(
                                                              '${widget.item!.nutritionsName![index]}${widget.item!.nutritionsName!.length - 1 == index ? '.' : ', '}',
                                                              style: robotoRegular.copyWith(
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
                                                    : const SizedBox()
                                            : const SizedBox(),

                                        (_shouldShowAllergies(
                                                widget.item!.allergiesName))
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'allergic_ingredients'.tr,
                                                      style: robotoMedium),
                                                  const SizedBox(
                                                      height: Dimensions
                                                          .paddingSizeExtraSmall),
                                                  Wrap(
                                                      children: List.generate(
                                                          widget
                                                              .item!
                                                              .allergiesName!
                                                              .length, (index) {
                                                    return Text(
                                                      '${widget.item!.allergiesName![index]}${widget.item!.allergiesName!.length - 1 == index ? '.' : ', '}',
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

                                        itemController.similarProductsList !=
                                                    null &&
                                                itemController
                                                    .similarProductsList!
                                                    .isNotEmpty
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 10),
                                                child: Column(
                                                  children: [
                                                    Text('Similar_products'.tr,
                                                        style: robotoMedium),
                                                  ],
                                                ),
                                              )
                                            : Container(),
                                        itemController.similarProductsList !=
                                                    null &&
                                                itemController
                                                    .similarProductsList!
                                                    .isNotEmpty
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 10),
                                                height: 240,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: itemController
                                                      .similarProductsList!
                                                      .length,
                                                  padding: const EdgeInsets
                                                      .only(
                                                      left: Dimensions
                                                          .paddingSizeSmall),
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  itemBuilder:
                                                      (context, index) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: SimilarItemWidget(
                                                        item: itemController
                                                                .similarProductsList![
                                                            index],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : const Column(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // الازرار

                            GetBuilder<CartController>(
                                builder: (cartController) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 6.0,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final bool useStackedButtons =
                                        constraints.maxWidth < 320;
                                    final Widget continueShoppingButton =
                                        CustomButton(
                                      buttonText: 'أكمل التسوق'.tr,
                                      onPressed: () {
                                        Get.back<void>();
                                      },
                                    );
                                    final Widget actionButton = CustomButton(
                                      isLoading: cartController.isLoading,
                                      buttonText: (itemController
                                                  .item?.availableDateStarts !=
                                              null)
                                          ? 'order_now'.tr
                                          : itemController.cartIndex != -1
                                              ? 'update_in_cart'.tr
                                              : 'add_to_cart'.tr,
                                      onPressed: () async {
                                        HapticFeedback.lightImpact();
                                        if (!itemController
                                            .ensureRequiredVariationsSelected()) {
                                          return;
                                        }
                                        if (itemController
                                                .item?.availableDateStarts !=
                                            null) {
                                          Get.toNamed<void>(
                                              RouteHelper
                                                  .getCampaignCheckoutRoute(),
                                              arguments: CheckoutScreen(
                                                storeId: null,
                                                fromCart: false,
                                                cartList: [cartModel],
                                              ));
                                        } else {
                                          if (itemController.cartIndex == -1) {
                                            await cartController
                                                .addToCartWithFallback(
                                              cartModel: cartModel!,
                                              onlineCart: cart!,
                                            )
                                                .then((success) {
                                              if (success && mounted) {
                                                itemController.setExistInCart(
                                                    widget.item, null);
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                showCartSnackBar(context);
                                                Get.toNamed<dynamic>(
                                                    RouteHelper.getCartRoute());

                                                _key.currentState!.shake();
                                              }
                                            });
                                          } else {
                                            // 🔥 FIX: Use cart_id instead of index
                                            if (itemController.cartIndex < 0 ||
                                                itemController.cartIndex >=
                                                    cartController
                                                        .cartList.length) {
                                              itemController.cartIndexSet();
                                              showCustomSnackBar(
                                                  'something_went_wrong'.tr);
                                              return;
                                            }
                                            final cartItem =
                                                cartController.cartList[
                                                    itemController.cartIndex];
                                            if (cartItem.id == null) {
                                              showCustomSnackBar(
                                                  'something_went_wrong'.tr);
                                              return;
                                            }
                                            await cartController
                                                .setQuantityById(
                                                    true,
                                                    cartItem.id!,
                                                    stock,
                                                    cartItem.quantityLimit);
                                            // Note: setQuantityById doesn't return Future, so no .then() needed
                                            if (mounted) {
                                              if (!context.mounted) {
                                                return;
                                              }
                                              Get.toNamed<dynamic>(
                                                  RouteHelper.getCartRoute());
                                              showCartSnackBar(context);

                                              _key.currentState!.shake();
                                            }
                                          }
                                        }
                                      },
                                    );
                                    if (useStackedButtons) {
                                      return Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: continueShoppingButton,
                                          ),
                                          const SizedBox(
                                              height: Dimensions
                                                  .paddingSizeExtraSmall),
                                          SizedBox(
                                            width: double.infinity,
                                            child: actionButton,
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: continueShoppingButton),
                                        const SizedBox(
                                            width: Dimensions.paddingSizeSmall),
                                        Expanded(child: actionButton),
                                      ],
                                    );
                                  },
                                ),
                              );
                            }),
                          ])
                    : const _ItemDetailsSkeleton()),
          );
        },
      );
    });
  }

  double _getItemDetailsDiscountPrice({required CartModel cart}) {
    // ✅ Cart.price is already discounted by backend - just multiply by quantity
    return cart.price! * cart.quantity!;
  }

  Widget _buildNutritionItem(BuildContext context, String label, String value) {
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

  /// Check if text contains English characters (A-Z, a-z)
  bool _containsEnglishText(String text) {
    // ignore: deprecated_member_use
    return RegExp(r'[A-Za-z]').hasMatch(text);
  }

  /// Check if nutrition section has any data to display
  bool _hasNutritionData(ItemController itemController) {
    final nutrition = itemController.item?.nutrition;
    if (nutrition == null) {
      return widget.item?.nutritionsName != null &&
          widget.item!.nutritionsName!.isNotEmpty;
    }
    return (nutrition.calories != null && nutrition.calories! > 0) ||
        nutrition.protein != null ||
        nutrition.carbs != null ||
        nutrition.fat != null ||
        nutrition.fiber != null ||
        (widget.item?.nutritionsName != null &&
            widget.item!.nutritionsName!.isNotEmpty);
  }

  /// Check if allergies should be shown
  /// Returns false if app is in Arabic and allergies are in English
  bool _shouldShowAllergies(List<String>? allergiesName) {
    if (allergiesName == null || allergiesName.isEmpty) {
      return false;
    }
    try {
      final isArabic =
          Get.find<LocalizationController>().locale.languageCode == 'ar';
      if (isArabic) {
        // Check if any allergy name contains English text
        for (final String allergy in allergiesName) {
          if (_containsEnglishText(allergy)) {
            return false; // Don't show if in Arabic mode and contains English
          }
        }
      }
      return true;
    } catch (e) {
      // If LocalizationController is not available, show anyway
      return true;
    }
  }
}

class _ItemDetailsSkeleton extends StatelessWidget {
  const _ItemDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: SizedBox(
          width: Dimensions.webMaxWidth,
          child: Shimmer(
            duration: const Duration(seconds: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(height: 220),
                const SizedBox(height: 16),
                _skeletonBox(height: 20, width: 220),
                const SizedBox(height: 8),
                _skeletonBox(height: 16, width: 140),
                const SizedBox(height: 16),
                _skeletonBox(height: 60),
                const SizedBox(height: 16),
                _skeletonBox(height: 16, width: 180),
                const SizedBox(height: 8),
                _skeletonBox(height: 16, width: 200),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _skeletonBox(height: 44)),
                    const SizedBox(width: 12),
                    Expanded(child: _skeletonBox(height: 44)),
                  ],
                ),
                const SizedBox(height: 16),
                _skeletonBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
    );
  }
}

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
