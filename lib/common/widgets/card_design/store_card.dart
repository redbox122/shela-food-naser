import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/new_tag.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/common/widgets/error_boundary_widget.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final bool? isTopOffers;
  const StoreCard({super.key, required this.store, this.isTopOffers = false});

  @override
  Widget build(BuildContext context) {
    // ⚡ TASK 1: Wrap in RepaintBoundary to isolate GPU repaints
    // 🔧 FIX 4: Wrap in error boundary to prevent crashes
    return RepaintBoundary(
      child: ErrorBoundaryWidget(
        widgetName: 'StoreCard',
        child: _buildStoreCard(context),
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context) {
    final bool isPharmacy = Get.find<SplashController>().module != null &&
        Get.find<SplashController>().module!.moduleType.toString() ==
            AppConstants.pharmacy;
    // ⚡ BFF API v2: Distance is in meters from API, convert to km
    // Backend returns 999999 when GPS is unavailable - display "Distance N/A"
    double? distanceKm;
    if (store.distance != null &&
        store.distance! > 0 &&
        store.distance! < 100000) {
      distanceKm = store.distance! / 1000;
    } else if (store.distance == 999999 ||
        store.distance == null ||
        store.distance! <= 0) {
      // Backend default 999999 means no GPS - show "Distance N/A"
      distanceKm = null;
    } else if (store.latitude != null &&
        store.longitude != null &&
        store.distance! > 100000) {
      // Fallback to local calculation if API distance is invalid (> 100km)
      distanceKm = Get.find<StoreController>().getRestaurantDistance(
        LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
      );
    }
    final double discount = store.discount?.discount ?? 0;
    final String discountType = store.discount?.discountType ?? '';
    final bool isRightSide =
        Get.find<SplashController>().configModel!.currencySymbolDirection ==
            'right';
    final String currencySymbol =
        Get.find<SplashController>().configModel!.currencySymbol!;
    final bool isAvailable = (store.isOpen ?? true) && (store.active ?? true);

    return Stack(children: [
      Container(
        width: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: ResponsiveHelper.isMobile(context)
              ? [
                  BoxShadow(
                      color: Theme.of(context)
                          .disabledColor
                          .withValues(alpha: 0.2),
                      blurRadius: 5,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: CustomInkWell(
          onTap: () {
            if (Get.find<SplashController>().moduleList != null) {
              for (final ModuleModel module
                  in Get.find<SplashController>().moduleList!) {
                if (module.id == store.moduleId) {
                  Get.find<SplashController>().setModule(module);
                  break;
                }
              }
            }
            Get.toNamed(
              RouteHelper.getStoreRoute(id: store.id, page: 'store'),
              arguments: StoreScreen(store: store, fromModule: false),
            );
          },
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          radius: Dimensions.radiusDefault,
          child: TextHover(builder: (hovered) {
            return Stack(children: [
              Column(children: [
                Expanded(
                  flex: 5,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault),
                              child: Hero(
                                tag: 'store_image_card_${store.id}',
                                placeholderBuilder: (context, heroSize, child) {
                                  return Container(
                                    width: heroSize.width,
                                    height: heroSize.height,
                                    color: Theme.of(context)
                                        .cardColor
                                        .withValues(alpha: 0.3),
                                    child: child,
                                  );
                                },
                                child: CustomImage(
                                  isHovered: hovered,
                                  // ⚡ FIX: Prioritize logoFullUrl for store cards (logo is more appropriate for list view)
                                  // Use coverPhotoFullUrl as fallback only if logo is not available
                                  image: (store.logoFullUrl != null &&
                                          store.logoFullUrl!.isNotEmpty)
                                      ? store.logoFullUrl!
                                      : (store.coverPhotoFullUrl ?? ''),
                                  imageStatus: (store.logoFullUrl != null &&
                                          store.logoFullUrl!.isNotEmpty)
                                      ? store.logoStatus
                                      : store.coverPhotoStatus,
                                  height: 50,
                                  width: 50,
                                ),
                              ),
                            ),
                            isAvailable
                                ? const SizedBox()
                                : NotAvailableWidget(
                                    isStore: true,
                                    store: store,
                                    fontSize: Dimensions.fontSizeExtraSmall),
                          ],
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 190,
                                  child: Text(
                                    store.name ?? '',
                                    style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeSmall),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(
                                    height: Dimensions.paddingSizeExtraSmall),
                                !isPharmacy
                                    ? store.ratingCount! > 0
                                        ? RatingBar(
                                            rating: store.avgRating,
                                            ratingCount: store.ratingCount,
                                            size: 12,
                                          )
                                        : const SizedBox()
                                    : Row(children: [
                                        Icon(Icons.storefront,
                                            size: 15,
                                            color:
                                                Theme.of(context).primaryColor),
                                        const SizedBox(
                                            width: Dimensions
                                                .paddingSizeExtraSmall),
                                        Expanded(
                                          child: Text(
                                            store.address ?? '',
                                            style: robotoRegular.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeExtraSmall,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ]),
                                const SizedBox(
                                    height: Dimensions.paddingSizeExtraSmall),
                                !isPharmacy
                                    ? Row(children: [
                                        Icon(Icons.storefront,
                                            size: 15,
                                            color:
                                                Theme.of(context).primaryColor),
                                        const SizedBox(
                                            width: Dimensions
                                                .paddingSizeExtraSmall),
                                        Flexible(
                                          child: Text(
                                            store.address ?? '',
                                            style: robotoMedium.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeExtraSmall,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ])
                                    : Text('${store.itemCount}' ' ' 'items'.tr,
                                        style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context)
                                                .primaryColor)),
                              ]),
                        ),
                      ]),
                ),
                Expanded(
                  flex: 2,
                  child: isTopOffers!
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeExtraSmall,
                              vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                Dimensions.radiusExtraLarge),
                          ),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const SizedBox(
                                      width: Dimensions.paddingSizeExtraSmall),
                                  Image.asset(
                                    Images.distanceLine,
                                    height: 15,
                                    width: 15,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                      distanceKm != null
                                          ? '${distanceKm > 100 ? '100+' : distanceKm.toStringAsFixed(2)} ${'km'.tr}'
                                          : 'Distance N/A',
                                      style: robotoBold.copyWith(
                                          color:
                                              Theme.of(context).disabledColor,
                                          fontSize: Dimensions.fontSizeSmall)),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeExtraSmall),
                                  Text('from_you'.tr,
                                      style: robotoRegular.copyWith(
                                          color:
                                              Theme.of(context).disabledColor,
                                          fontSize: Dimensions.fontSizeSmall)),
                                ]),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusExtraLarge),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeSmall,
                                      vertical: 3),
                                  child: Text(
                                    discount > 0
                                        ? '${(isRightSide || discountType == 'percent') ? '' : currencySymbol}$discount${discountType == 'percent' ? '%' : isRightSide ? currencySymbol : ''} ${'off'.tr}'
                                        : 'free_delivery'.tr,
                                    style: robotoMedium.copyWith(
                                        color: Theme.of(context).cardColor,
                                        fontSize: Dimensions.fontSizeSmall),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              ]),
                        )
                      : Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeSmall,
                                vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  Dimensions.radiusExtraLarge),
                            ),
                            child: Row(children: [
                              Image.asset(Images.distanceLine,
                                  height: 15, width: 15),
                              const SizedBox(
                                  width: Dimensions.paddingSizeExtraSmall),
                              Text(
                                  distanceKm != null
                                      ? '${distanceKm > 100 ? '100+' : distanceKm.toStringAsFixed(2)} ${'km'.tr}'
                                      : 'Distance N/A',
                                  style: robotoBold.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: Dimensions.fontSizeSmall)),
                              const SizedBox(
                                  width: Dimensions.paddingSizeExtraSmall),
                              Text('from_you'.tr,
                                  style: robotoRegular.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: Dimensions.fontSizeSmall)),
                            ]),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeSmall,
                                vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(
                                  Dimensions.radiusExtraLarge),
                            ),
                            child: Row(children: [
                              Image.asset(Images.clockIcon,
                                  height: 15,
                                  width: 15,
                                  color: Get.find<StoreController>()
                                          .isOpenNow(store)
                                      ? const Color(0xffECA507)
                                      : Theme.of(context).colorScheme.error),
                              const SizedBox(
                                  width: Dimensions.paddingSizeExtraSmall),
                              Text(
                                  Get.find<StoreController>().isOpenNow(store)
                                      ? 'open_now'.tr
                                      : 'closed_now'.tr,
                                  style: robotoBold.copyWith(
                                      color: Get.find<StoreController>()
                                              .isOpenNow(store)
                                          ? const Color(0xffECA507)
                                          : Theme.of(context).colorScheme.error,
                                      fontSize: Dimensions.fontSizeSmall)),
                            ]),
                          ),
                        ]),
                ),
              ]),
              Positioned(
                top: 0,
                left: Get.find<LocalizationController>().isLtr ? null : 0,
                right: Get.find<LocalizationController>().isLtr ? 0 : null,
                // ⚡ TASK 1: Isolate favorite button rebuilds - only this widget rebuilds, not entire card
                child: RepaintBoundary(
                  child: GetBuilder<FavouriteController>(
                    builder: (favouriteController) {
                      final bool isWished = favouriteController.wishStoreIdList
                          .contains(store.id);
                      return InkWell(
                        onTap: () {
                          if (AuthHelper.isLoggedIn()) {
                            isWished
                                ? favouriteController.removeFromFavouriteList(
                                    store.id, true)
                                : favouriteController.addToFavouriteList(
                                    null, store.id, true);
                          } else {
                            showCustomSnackBar('you_are_not_logged_in'.tr);
                          }
                        },
                        child: Icon(
                          isWished ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
      !isTopOffers! ? const NewTag() : const SizedBox(),
    ]);
  }
}
