import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreDescriptionViewWidget extends StatelessWidget {
  final Store? store;
  const StoreDescriptionViewWidget({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStore = store;
    if (currentStore == null || currentStore.active == null) {
      return const SizedBox.shrink();
    }
    // ✅ FRONTEND ONLY: Use store.isOpen from API only (no time calculations)
    // ❌ NO DateTime, NO schedule checks, NO time logic
    final bool isAvailable = currentStore.isOpen == true;
    final Color? textColor = ResponsiveHelper.isDesktop(context) ? theme.colorScheme.onSurface : null;
    // Module? moduleData;
    // for(ZoneData zData in AddressHelper.getUserAddressFromSharedPref()!.zoneData!) {
    //   for(Modules m in zData.modules!) {
    //     if(m.id == Get.find<SplashController>().module!.id) {
    //       moduleData = m as Module?;
    //       break;
    //     }
    //   }
    // }
    return Column(children: [
      ResponsiveHelper.isDesktop(context)
          ? Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Stack(children: [
                  CustomImage(
                    image: '${currentStore.logoFullUrl}',
                    height: ResponsiveHelper.isDesktop(context) ? 140 : 60,
                    width: ResponsiveHelper.isDesktop(context) ? 140 : 70,
                  ),
                  isAvailable
                      ? const SizedBox()
                      : Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusSmall)),
                              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6),
                            ),
                            child: Text(
                              'closed_now'.tr,
                              textAlign: TextAlign.center,
                              style: robotoRegular.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ),
                        ),
                ]),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: Text(
                    currentStore.name ?? '',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  // ResponsiveHelper.isDesktop(context) ? InkWell(
                  //   onTap: () => Get.toNamed(RouteHelper.getSearchStoreItemRoute(store!.id)),
                  //   child: ResponsiveHelper.isDesktop(context) ? Container(
                  //     padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), color: Theme.of(context).primaryColor),
                  //     child: const Center(child: Icon(Icons.search, color: Colors.white)),
                  //   ) : Icon(Icons.search, color: Theme.of(context).primaryColor),
                  // ) : const SizedBox(),
                  // const SizedBox(width: Dimensions.paddingSizeSmall),
                  GetBuilder<FavouriteController>(builder: (favouriteController) {
                    final bool isWished = favouriteController.wishStoreIdList.contains(currentStore.id);
                    return InkWell(
                      onTap: () {
                        if (AuthHelper.isLoggedIn()) {
                          isWished
                              ? favouriteController.removeFromFavouriteList(currentStore.id, true)
                              : favouriteController.addToFavouriteList(null, currentStore.id, true);
                        } else {
                          showCustomSnackBar('you_are_not_logged_in'.tr);
                        }
                      },
                      child: ResponsiveHelper.isDesktop(context)
                          ? Container(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  border: Border.all(color: theme.colorScheme.onSurface)),
                              child: Center(
                                child: Row(
                                  children: [
                                    Icon(isWished ? Icons.favorite : Icons.favorite_border, color: theme.colorScheme.onSurface, size: 14),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                    Text('wish_list'.tr,
                                        style: robotoRegular.copyWith(
                                            fontWeight: FontWeight.w200, color: theme.colorScheme.onSurface, fontSize: Dimensions.fontSizeSmall)),
                                  ],
                                ),
                              ),
                            )
                          : Icon(
                              isWished ? Icons.favorite : Icons.favorite_border,
                              color: isWished ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                            ),
                    );
                  }),
                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Row(children: [
                  Expanded(
                    child: Text(
                      currentStore.address ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                    ),
                  ),
                  AppConstants.webHostedUrl.isNotEmpty
                      ? InkWell(
                          onTap: () {
                            Get.find<StoreController>().shareStore();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            child: Icon(Icons.share, size: 24, color: theme.colorScheme.onPrimary),
                          ),
                        )
                      : const SizedBox(),
                ]),
                SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeSmall : 0),
                Row(children: [
                  Text('minimum_order_amount'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      )),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Expanded(
                    child: PriceConverter.convertPrice2(
                      currentStore.minimumOrder,
                      textStyle: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ]),
              ])),
            ])
          : const SizedBox(),
      SizedBox(height: ResponsiveHelper.isDesktop(context) ? 30 : Dimensions.paddingSizeSmall),
      ResponsiveHelper.isDesktop(context)
          ? IntrinsicHeight(
              child: Row(children: [
                const Expanded(child: SizedBox()),
                InkWell(
                  onTap: () => Get.toNamed(RouteHelper.getStoreReviewRoute(currentStore.id, currentStore.name ?? '', currentStore)),
                  child: Column(children: [
                    Row(children: [
                      Icon(Icons.star, color: Theme.of(context).primaryColor, size: 20),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        (currentStore.avgRating ?? 0.0).toStringAsFixed(1),
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor),
                      ),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      '${currentStore.ratingCount ?? 0} + ${'ratings'.tr}',
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor),
                    ),
                  ]),
                ),
                const Expanded(child: SizedBox()),
                VerticalDivider(color: theme.dividerColor.withValues(alpha: 0.6), thickness: 1),
                const Expanded(child: SizedBox()),
                // 🔧 FIX: Hide location row if coordinates are null
                if (currentStore.latitude != null && currentStore.longitude != null) ...[
                  InkWell(
                    onTap: () => Get.toNamed(RouteHelper.getMapRoute(
                      AddressModel(
                        id: currentStore.id,
                        address: currentStore.address,
                        latitude: currentStore.latitude,
                        longitude: currentStore.longitude,
                        contactPersonNumber: '',
                        contactPersonName: '',
                        addressType: '',
                      ),
                      'store',
                      Get.find<SplashController>().getModuleConfig(Get.find<SplashController>().module!.moduleType!).newVariation ?? false,
                      storeName: currentStore.name,
                    )),
                    child: Column(children: [
                      // Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 20),
                      Image.asset(Images.storeLocationIcon, height: 20, width: 20),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text('location'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
                    ]),
                  ),
                  const Expanded(child: SizedBox()),
                  VerticalDivider(color: theme.dividerColor.withValues(alpha: 0.6), thickness: 1),
                  const Expanded(child: SizedBox()),
                ], // Hide location row and divider if coordinates are null
                // ✅ DATA-DRIVEN: Only show delivery time if delivery is enabled AND time exists
                if (currentStore.deliveryTime != null &&
                    currentStore.deliveryTime!.isNotEmpty &&
                    (currentStore.delivery ?? false)) ...[
                  Column(children: [
                    Image.asset(Images.storeDeliveryTimeIcon, height: 20, width: 20),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(currentStore.deliveryTime!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
                  ]),
                  const Expanded(child: SizedBox()),
                  VerticalDivider(color: theme.dividerColor.withValues(alpha: 0.6), thickness: 1),
                  const Expanded(child: SizedBox()),
                ],
                // ✅ DATA-DRIVEN: Only show free delivery if both delivery and freeDelivery are true
                if ((currentStore.delivery ?? false) && (currentStore.freeDelivery ?? false)) ...[
                  Column(children: [
                    Icon(Icons.money_off, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text('free_delivery'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
                  ]),
                  const Expanded(child: SizedBox()),
                ],
                // ✅ DATA-DRIVEN: Only show prescription order badge if prescriptionOrder is true
                if (currentStore.prescriptionOrder == true) ...[
                  if ((currentStore.delivery ?? false) && (currentStore.freeDelivery ?? false)) ...[
                    VerticalDivider(color: theme.dividerColor.withValues(alpha: 0.6), thickness: 1),
                    const Expanded(child: SizedBox()),
                  ],
                  Column(children: [
                    Icon(Icons.medical_information, color: Theme.of(context).colorScheme.error, size: 20),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text('prescription_required'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
                  ]),
                  const Expanded(child: SizedBox()),
                ] else
                  const Expanded(child: SizedBox()),
              ]),
            )
          : Row(children: [
              const Expanded(child: SizedBox()),
                InkWell(
                  onTap: () => Get.toNamed(RouteHelper.getStoreReviewRoute(currentStore.id, currentStore.name ?? '', currentStore)),
                  child: Column(children: [
                  Row(children: [
                    Icon(Icons.star, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      (currentStore.avgRating ?? 0.0).toStringAsFixed(1),
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor),
                    ),
                  ]),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text(
                    '${currentStore.ratingCount ?? 0} + ${'ratings'.tr}',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor),
                  ),
                ]),
              ),
              const Expanded(child: SizedBox()),
              // 🔧 FIX: Hide location row if coordinates are null
              if (currentStore.latitude != null && currentStore.longitude != null)
                InkWell(
                  onTap: () => Get.toNamed(RouteHelper.getMapRoute(
                    AddressModel(
                      id: currentStore.id,
                      address: currentStore.address,
                      latitude: currentStore.latitude,
                      longitude: currentStore.longitude,
                      contactPersonNumber: '',
                      contactPersonName: '',
                      addressType: '',
                    ),
                    'store',
                    Get.find<SplashController>().getModuleConfig(Get.find<SplashController>().module!.moduleType!).newVariation ?? false,
                    storeName: currentStore.name,
                  )),
                  child: Column(children: [
                    Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text('location'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
                  ]),
                )
              else
                const SizedBox(), // Hide location row if coordinates are null
              // Note: No divider needed here as mobile layout doesn't use dividers between items
              const Expanded(child: SizedBox()),
              // ✅ DATA-DRIVEN: Only show delivery time if delivery is enabled AND time exists
              if (currentStore.deliveryTime != null &&
                  currentStore.deliveryTime!.isNotEmpty &&
                  (currentStore.delivery ?? false))
                Column(children: [
                  Row(children: [
                    Icon(Icons.timer, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      currentStore.deliveryTime!,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor),
                    ),
                  ]),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text('delivery_time'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
                ]),
              // ✅ DATA-DRIVEN: Only show free delivery if both delivery and freeDelivery are true
              if ((currentStore.delivery ?? false) && (currentStore.freeDelivery ?? false))
                Column(children: [
                  Icon(Icons.money_off, color: Theme.of(context).primaryColor, size: 20),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text('free_delivery'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
                ]),
              // ✅ DATA-DRIVEN: Only show prescription order badge if prescriptionOrder is true
              if (currentStore.prescriptionOrder == true)
                Column(children: [
                  Icon(Icons.medical_information, color: Theme.of(context).colorScheme.error, size: 20),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text('prescription_required'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
                ]),
              const Expanded(child: SizedBox()),
            ]),
    ]);
  }
}
