import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_tool_tip_widget.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/organic_tag.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';

class ItemTitleViewWidget extends StatelessWidget {
  final Item? item;
  final bool inStorePage;
  final bool isCampaign;
  final bool inStock;
  const ItemTitleViewWidget(
      {super.key,
      required this.item,
      this.inStorePage = false,
      this.isCampaign = false,
      required this.inStock});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint(inStock ? 'out_of_stock'.tr : 'in_stock'.tr);
    }
    final Item? itemData = item;
    if (itemData == null) {
      return const SizedBox();
    }
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    double? startingPrice;
    // endingPrice kept for potential future use with price ranges
    // ignore: unused_local_variable
    double? endingPrice;
    final List<Variation>? variations = itemData.variations;
    if (variations != null && variations.isNotEmpty) {
      final List<double?> priceList = [];
      for (final variation in variations) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
      if (priceList[0]! < priceList[priceList.length - 1]!) {
        endingPrice = priceList[priceList.length - 1];
      }
    } else {
      startingPrice = itemData.price;
    }

    final double? discount =
        (itemData.availableDateStarts != null || itemData.storeDiscount == 0)
            ? itemData.discount
            : itemData.storeDiscount;
    final double discountValue = discount ?? 0;

    return ResponsiveHelper.isDesktop(context)
        ? GetBuilder<ItemController>(builder: (itemController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item?.name ?? '',
                            style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeOverLarge),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                            width: itemData.isStoreHalalActive == true &&
                                    itemData.isHalalItem == true
                                ? Dimensions.paddingSizeSmall
                                : 0),
                        itemData.isStoreHalalActive == true &&
                                itemData.isHalalItem == true
                            ? CustomToolTip(
                                message: 'this_is_a_halal_food'.tr,
                                preferredDirection: AxisDirection.up,
                                child: const CustomAssetImageWidget(
                                    Images.halalTag,
                                    height: 35,
                                    width: 35),
                              )
                            : const SizedBox(),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        ((Get.find<SplashController>()
                                        .configModel!
                                        .moduleConfig!
                                        .module!
                                        .unit! &&
                                    itemData.unitType != null) ||
                                (Get.find<SplashController>()
                                        .configModel!
                                        .moduleConfig!
                                        .module!
                                        .vegNonVeg! &&
                                    Get.find<SplashController>()
                                        .configModel!
                                        .toggleVegNonVeg!))
                            ? Text(
                                Get.find<SplashController>()
                                        .configModel!
                                        .moduleConfig!
                                        .module!
                                        .unit!
                                    ? '(${itemData.unitType})'
                                    : itemData.veg == 0
                                        ? '(${'non_veg'.tr})'
                                        : '(${'veg'.tr})',
                                style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Theme.of(context).disabledColor),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  itemData.availableTimeStarts != null
                      ? const SizedBox()
                      : Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusSmall),
                          ),
                          child: GetBuilder<FavouriteController>(
                              builder: (favouriteController) {
                            return InkWell(
                              onTap: () {
                                if (AuthHelper.isLoggedIn()) {
                                  if (favouriteController.wishItemIdList
                                      .contains(itemData.id)) {
                                    favouriteController.removeFromFavouriteList(
                                        itemData.id, false);
                                  } else {
                                    favouriteController.addToFavouriteList(
                                        itemData, null, false);
                                  }
                                } else {
                                  showCustomSnackBar(
                                      'you_are_not_logged_in'.tr);
                                }
                              },
                              child: Icon(
                                favouriteController.wishItemIdList
                                        .contains(itemData.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 25,
                                color: Theme.of(context).primaryColor,
                              ),
                            );
                          }),
                        ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                (itemData.genericName != null &&
                        itemData.genericName!.isNotEmpty)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                              children: List.generate(
                                  itemData.genericName!.length,
                                  (index) {
                            return Text(
                              '${itemData.genericName![index]}${itemData.genericName!.length - 1 == index ? '.' : ', '}',
                              style: robotoRegular.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color
                                      ?.withValues(alpha: 0.5)),
                            );
                          })),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ],
                      )
                    : const SizedBox(),
                SizedBox(
                    height: (itemData.genericName != null &&
                            itemData.genericName!.isNotEmpty)
                        ? Dimensions.paddingSizeSmall
                        : 0),

                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall,
                        vertical: Dimensions.paddingSizeExtraSmall),
                    decoration: BoxDecoration(
                      color:
                          inStock ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    child: Text(inStock ? 'out_of_stock'.tr : 'in_stock'.tr,
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontSize: Dimensions.fontSizeExtraSmall,
                        )),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  OrganicTag(item: itemData, fromDetails: true),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                InkWell(
                  onTap: () {
                    if (inStorePage) {
                      Get.back();
                      return;
                    }
                    if (itemData.storeId != null) {
                      Get.offNamed(RouteHelper.getStoreRoute(
                          id: itemData.storeId, page: 'item'));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                    child: Text(
                      itemData.storeName ?? '',
                      style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
                //const SizedBox(height: Dimensions.paddingSizeSmall),

                if ((itemData.ratingCount ?? 0) > 0)
                  RatingBar(
                      rating: itemData.avgRating,
                      ratingCount: itemData.ratingCount),
                SizedBox(
                    height: (itemData.ratingCount ?? 0) > 0
                        ? Dimensions.paddingSizeSmall
                        : 0),

                Row(children: [
                  // ✅ Show original price (strikethrough) if item has discount
                  discount! > 0 && itemData.originalPrice != null
                      ? Flexible(
                          child: PriceConverter.convertPrice2(
                            itemData.originalPrice!,
                            textStyle: robotoRegular.copyWith(
                              color: Theme.of(context).disabledColor,
                              decoration: TextDecoration.lineThrough,
                              fontSize: Dimensions.fontSizeExtraSmall,
                            ),
                          ),
                        )
                      : const SizedBox(),
                  SizedBox(
                      width: discount > 0 && itemData.originalPrice != null
                          ? 10
                          : 0),
                  // ✅ Backend already calculated discount - just display price directly
                  PriceConverter.convertPrice2(
                    startingPrice,
                    // ❌ REMOVED: discount and discountType - backend already applied it!
                    textStyle:
                        robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                ]),
              ],
            );
          })
        : Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: GetBuilder<ItemController>(
              builder: (itemController) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Row(children: [
                            Flexible(
                                child: Text(
                              item?.name ?? '',
                              style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeExtraLarge),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )),
                            SizedBox(
                                width: itemData.isStoreHalalActive == true &&
                                        itemData.isHalalItem == true
                                    ? Dimensions.paddingSizeExtraSmall
                                    : 0),
                            itemData.isStoreHalalActive == true &&
                                    itemData.isHalalItem == true
                                ? CustomToolTip(
                                    message: 'this_is_a_halal_food'.tr,
                                    preferredDirection: AxisDirection.up,
                                    child: const CustomAssetImageWidget(
                                        Images.halalTag,
                                        height: 30,
                                        width: 30),
                                  )
                                : const SizedBox(),
                            /*item!.availableTimeStarts != null ? const SizedBox() : */
                          ]),
                        ),
                        GetBuilder<FavouriteController>(
                            builder: (favouriteController) {
                          return InkWell(
                            onTap: () {
                              if (isLoggedIn) {
                                if (favouriteController.wishItemIdList
                                    .contains(itemData.id)) {
                                  favouriteController.removeFromFavouriteList(
                                      itemData.id, false);
                                } else {
                                  favouriteController.addToFavouriteList(
                                      itemData, null, false);
                                }
                              } else {
                                showCustomSnackBar('you_are_not_logged_in'.tr);
                              }
                            },
                            child: Icon(
                              favouriteController.wishItemIdList
                                      .contains(itemData.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 30,
                              color: favouriteController.wishItemIdList
                                      .contains(itemData.id)
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).disabledColor,
                            ),
                          );
                        }),
                      ]),
                      const SizedBox(height: 5),
                      (itemData.genericName != null &&
                              itemData.genericName!.isNotEmpty)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                    children: List.generate(
                                        itemData.genericName!.length, (index) {
                                  return Text(
                                    '${itemData.genericName![index]}${itemData.genericName!.length - 1 == index ? '.' : ', '}',
                                    style: robotoRegular.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color
                                            ?.withValues(alpha: 0.5)),
                                  );
                                })),
                                const SizedBox(
                                    height: Dimensions.paddingSizeExtraSmall),
                              ],
                            )
                          : const SizedBox(),
                      InkWell(
                        onTap: () {
                          if (inStorePage) {
                            Get.back();
                            return;
                          }
                          if (itemData.storeId != null) {
                            Get.offNamed(RouteHelper.getStoreRoute(
                                id: itemData.storeId, page: 'item'));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                          child: Text(
                            itemData.storeName ?? '',
                            style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(
                                    children: [
                                      // ✅ Show original price (strikethrough) if item has discount
                                      if (discountValue > 0 &&
                                          itemData.originalPrice != null)
                                        Flexible(
                                          child: PriceConverter.convertPrice2(
                                            itemData.originalPrice!,
                                            textStyle: robotoRegular.copyWith(
                                              color: Theme.of(context)
                                                  .disabledColor,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                            ),
                                          ),
                                        ),
                                      if (discountValue > 0 &&
                                          itemData.originalPrice != null)
                                        const SizedBox(width: 8),
                                      // ✅ Backend already calculated discount - just display price directly
                                      PriceConverter.convertPrice2(
                                        startingPrice,
                                        // ❌ REMOVED: discount and discountType - backend already applied it!
                                        textStyle: robotoMedium.copyWith(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontSize: Dimensions.fontSizeLarge),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  !isCampaign && itemData.avgRating != null
                                      ? Row(children: [
                                          Text(
                                              itemData.avgRating!
                                                  .toStringAsFixed(1),
                                              style: robotoRegular.copyWith(
                                                color:
                                                    Theme.of(context).hintColor,
                                                fontSize:
                                                    Dimensions.fontSizeLarge,
                                              )),
                                          const SizedBox(width: 5),
                                          RatingBar(
                                              rating: itemData.avgRating,
                                              ratingCount: itemData.ratingCount),
                                        ])
                                      : const SizedBox(),
                                ])),
                            Column(children: [
                              ((Get.find<SplashController>()
                                              .configModel!
                                              .moduleConfig!
                                              .module!
                                              .unit! &&
                                          itemData.unitType != null) ||
                                      (Get.find<SplashController>()
                                              .configModel!
                                              .moduleConfig!
                                              .module!
                                              .vegNonVeg! &&
                                          Get.find<SplashController>()
                                              .configModel!
                                              .toggleVegNonVeg!))
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical:
                                              Dimensions.paddingSizeExtraSmall,
                                          horizontal:
                                              Dimensions.paddingSizeSmall),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            Dimensions.radiusSmall),
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.1),
                                      ),
                                      child: Text(
                                        Get.find<SplashController>()
                                                .configModel!
                                                .moduleConfig!
                                                .module!
                                                .unit!
                                            ? itemData.unitType ?? ''
                                            : itemData.veg == 0
                                                ? 'non_veg'.tr
                                                : 'veg'.tr,
                                        style: robotoRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeExtraSmall,
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                    )
                                  : const SizedBox(),
                              const SizedBox(
                                  height: Dimensions.paddingSizeDefault),
                              OrganicTag(item: itemData, fromDetails: true),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeSmall,
                                    vertical: Dimensions.paddingSizeExtraSmall),
                                decoration: BoxDecoration(
                                  color: inStock ? Colors.red : Colors.green,
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusSmall),
                                ),
                                child: Text(
                                    inStock ? 'out_of_stock'.tr : 'in_stock'.tr,
                                    style: robotoRegular.copyWith(
                                      color: Colors.white,
                                      fontSize: Dimensions.fontSizeSmall,
                                    )),
                              ),
                            ]),
                          ]),
                    ]);
              },
            ),
          );
  }
}
