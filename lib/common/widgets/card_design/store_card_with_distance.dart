import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/new_tag.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';

class StoreCardWithDistance extends StatefulWidget {
  final Store store;
  final bool fromAllStore;
  final bool? isNewStore;
  final bool? fromTopOffers;
  final String heroSection;
  final int? heroIndex;
  const StoreCardWithDistance(
      {super.key,
      required this.store,
      this.fromAllStore = false,
      this.isNewStore = false,
      this.fromTopOffers = false,
      this.heroSection = 'default',
      this.heroIndex});

  @override
  State<StoreCardWithDistance> createState() => _StoreCardWithDistanceState();
}

class _StoreCardWithDistanceState extends State<StoreCardWithDistance> {
  String _heroTag(String type, int storeId) {
    final int safeIndex = widget.heroIndex ?? 0;
    return '${widget.heroSection}_${type}_${storeId}_$safeIndex';
  }

  Future<void> _handleStoreTap(Store store) async {
    final SplashController splashController = Get.find<SplashController>();
    final int? currentModuleId = splashController.selectedModule.value?.id ??
        splashController.module?.id;
    final int? targetModuleId = store.moduleId;
    ModuleModel? targetModuleModel;
    if (targetModuleId != null && splashController.moduleList != null) {
      final int foundIndex = splashController.moduleList!
          .indexWhere((ModuleModel m) => m.id == targetModuleId);
      if (foundIndex >= 0) {
        targetModuleModel = splashController.moduleList![foundIndex];
      }
    }
    final bool logFavoriteNav = kDebugMode && widget.fromAllStore;
    if (logFavoriteNav) {
      debugPrint(
        '[FavoriteStore][TAP] id=${store.id} storeId=${store.id} name=${store.name} '
        'moduleId=$targetModuleId moduleType=${targetModuleModel?.moduleType} '
        'currentModuleId=$currentModuleId',
      );
    }
    if (store.id == null) {
      if (logFavoriteNav) {
        debugPrint('[FavoriteStore][NAV_BLOCKED] reason=store_id_null');
      }
      return;
    }
    if (targetModuleId != null &&
        currentModuleId != null &&
        targetModuleId != currentModuleId &&
        targetModuleModel != null) {
      if (logFavoriteNav) {
        debugPrint(
          '[FavoriteStore][NAV_DECISION] route=setModule_then_store '
          'reason=cross_module_headers_sync',
        );
      }
      try {
        await splashController.setModule(targetModuleModel);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[FavoriteStore][NAV_DECISION] setModule_failed error=$e st=$st');
        }
      }
    } else if (targetModuleId != null &&
        currentModuleId != null &&
        targetModuleId != currentModuleId &&
        targetModuleModel == null) {
      if (logFavoriteNav) {
        debugPrint(
          '[FavoriteStore][NAV_DECISION] route=store_only '
          'reason=cross_module_but_target_not_in_module_list',
        );
      }
    } else {
      if (logFavoriteNav) {
        debugPrint(
          '[FavoriteStore][NAV_DECISION] route=store_only '
          'reason=same_module_or_missing_module_ids',
        );
      }
    }
    final String heroBannerTag =
        _heroTag('store_image_distance', store.id ?? 0);
    final String heroLogoTag = _heroTag('store_logo', store.id ?? 0);
    final String route =
        RouteHelper.getStoreRoute(id: store.id, page: 'store');
    Get.toNamed(
      route,
      arguments: StoreScreen(
        store: store,
        fromModule: false,
        heroBannerTag: heroBannerTag,
        heroLogoTag: heroLogoTag,
      ),
    );
    if (logFavoriteNav) {
      debugPrint('[FavoriteStore][NAV_SUCCESS] route=$route');
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    // 🔧 PERF FIX: Disable background prefetching of store details.
    // Store details should be fetched only when opening a store page.
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    // RULE #2 (last-resort defence): hide a store with no image (kept in DB,
    // shown once an image is added). Lists are pre-filtered, so this is a guard.
    if ((store.logoFullUrl ?? '').trim().isEmpty &&
        (store.coverPhotoFullUrl ?? '').trim().isEmpty) {
      return const SizedBox.shrink();
    }
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

    // ⚡ TASK 2: Wrap in VisibilityDetector for scroll-aware pre-fetching
    return VisibilityDetector(
      key: Key('store_card_${store.id}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: Stack(
        children: [
          Container(
            width: widget.fromAllStore ? double.infinity : 260,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
              ],
            ),
            child: CustomInkWell(
              onTap: () {
                unawaited(_handleStoreTap(store));
              },
              radius: Dimensions.radiusDefault,
              child: TextHover(builder: (hovered) {
                return Column(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(Dimensions.radiusDefault),
                          topRight: Radius.circular(Dimensions.radiusDefault)),
                      child: Stack(clipBehavior: Clip.none, children: [
                        Hero(
                          tag: _heroTag('store_image_distance', store.id ?? 0),
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
                          child: Builder(
                            builder: (context) {
                              // ⚡ FIX: Banner should use coverPhotoFullUrl (banner image), fallback to logo if cover photo missing
                              // The banner is the large background image, not the logo
                              final useCover =
                                  (store.coverPhotoFullUrl != null &&
                                          store.coverPhotoFullUrl!.isNotEmpty)
                                      ? true
                                      : false;
                              final imageUrl = useCover
                                  ? store.coverPhotoFullUrl!
                                  : (store.logoFullUrl ?? '');
                              final imageStatus = useCover
                                  ? store.coverPhotoStatus
                                  : store.logoStatus;
                              return CustomImage(
                                isHovered: hovered,
                                image: imageUrl,
                                imageStatus: imageStatus,
                                fit: BoxFit.fitWidth,
                                height: double.infinity,
                                width: double.infinity,
                              );
                            },
                          ),
                        ),
                        !widget.fromTopOffers!
                            ? DiscountTag(
                                discount: Get.find<StoreController>()
                                    .getDiscount(store),
                                discountType: Get.find<StoreController>()
                                    .getDiscountType(store),
                                freeDelivery: store.freeDelivery,
                              )
                            : const SizedBox(),
                        Get.find<StoreController>().isOpenNow(store)
                            ? const SizedBox()
                            : const NotAvailableWidget(isStore: true),

                        /* AddFavouriteView(
                          item: Item(id: store.id),
                        ),*/

                        widget.fromTopOffers!
                            ? Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeSmall,
                                      vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(
                                            Dimensions.radiusDefault)),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withValues(alpha: 0.8),
                                  ),
                                  child: Text(
                                    discount > 0
                                        ? '${(isRightSide || discountType == 'percent') ? '' : currencySymbol}$discount${discountType == 'percent' ? '%' : isRightSide ? currencySymbol : ''} ${'off'.tr}'
                                        : 'free_delivery'.tr,
                                    style: robotoMedium.copyWith(
                                        color: Theme.of(context).cardColor,
                                        fontSize: Dimensions.fontSizeSmall),
                                    textAlign: TextAlign.center,
                                  ),
                                  // child: Text('new'.tr, style: robotoMedium.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall)),
                                ),
                              )
                            : const SizedBox(),
                        Positioned(
                          top: 15,
                          left: Get.find<LocalizationController>().isLtr
                              ? null
                              : 15,
                          right: Get.find<LocalizationController>().isLtr
                              ? 15
                              : null,
                          child: GetBuilder<FavouriteController>(
                              builder: (favouriteController) {
                            final bool isWished = favouriteController
                                .wishStoreIdList
                                .contains(store.id);
                            return InkWell(
                              onTap: () {
                                if (AuthHelper.isLoggedIn()) {
                                  isWished
                                      ? favouriteController
                                          .removeFromFavouriteList(
                                              store.id, true)
                                      : favouriteController.addToFavouriteList(
                                          null, store.id, true);
                                } else {
                                  showCustomSnackBar(
                                      'you_are_not_logged_in'.tr);
                                }
                              },
                              child: Icon(
                                isWished
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                            );
                          }),
                        ),
                        widget.isNewStore! ? const NewTag() : const SizedBox(),
                      ]),
                    ),
                  ),
                  Expanded(
                    child: Column(children: [
                      Flexible(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: Get.find<LocalizationController>().isLtr
                                ? 95
                                : 8,
                            right: Get.find<LocalizationController>().isLtr
                                ? 8
                                : 95,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                Get.find<LocalizationController>().isLtr
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.end,
                            children: [
                              // Top row: Rating and Restaurant name (RTL aware)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Restaurant name - position and alignment based on LTR/RTL
                                  Flexible(
                                    flex: 2,
                                    child: Align(
                                      alignment:
                                          Get.find<LocalizationController>()
                                                  .isLtr
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                      child: Text(
                                        store.name ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextAlign.left
                                                : TextAlign.right,
                                        textDirection:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextDirection.ltr
                                                : TextDirection.rtl,
                                        style: robotoMedium,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 4),

                                  // Rating with review count
                                  if (store.avgRating != null &&
                                      store.avgRating! > 0 &&
                                      store.ratingCount != null &&
                                      store.ratingCount! > 0)
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        textDirection:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextDirection.ltr
                                                : TextDirection.rtl,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              '${store.avgRating!.toStringAsFixed(1)} (${store.ratingCount})',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textDirection: Get.find<
                                                          LocalizationController>()
                                                      .isLtr
                                                  ? TextDirection.ltr
                                                  : TextDirection.rtl,
                                              style: robotoRegular.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeExtraSmall,
                                                color: Theme.of(context)
                                                    .disabledColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                              ),

                              // Delivery time with free delivery indicator
                              if (store.deliveryTime != null &&
                                  store.deliveryTime!.isNotEmpty) ...[
                                const SizedBox(height: 0),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  textDirection:
                                      Get.find<LocalizationController>().isLtr
                                          ? TextDirection.ltr
                                          : TextDirection.rtl,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(
                                        width:
                                            Dimensions.paddingSizeExtraSmall),
                                    Flexible(
                                      child: Text(
                                        '${store.deliveryTime}${store.freeDelivery == true ? ' ${'free_delivery'.tr}' : ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextDirection.ltr
                                                : TextDirection.rtl,
                                        textAlign:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextAlign.left
                                                : TextAlign.right,
                                        style: robotoRegular.copyWith(
                                          color:
                                              Theme.of(context).disabledColor,
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Discount/Offer text or Address
                              if (store.discount != null &&
                                  store.discount!.discount != null &&
                                  store.discount!.discount! > 0) ...[
                                const SizedBox(height: 0),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  textDirection:
                                      Get.find<LocalizationController>().isLtr
                                          ? TextDirection.ltr
                                          : TextDirection.rtl,
                                  children: [
                                    Icon(
                                      Icons.local_offer,
                                      size: 14,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(
                                        width:
                                            Dimensions.paddingSizeExtraSmall),
                                    Flexible(
                                      child: Text(
                                        '${store.discount!.discountType == 'percent' ? '${store.discount!.discount!.toStringAsFixed(0)}%' : store.discount!.discount!.toStringAsFixed(0)} ${'off'.tr}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextDirection.ltr
                                                : TextDirection.rtl,
                                        textAlign:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextAlign.left
                                                : TextAlign.right,
                                        style: robotoRegular.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (!widget.fromTopOffers! &&
                                  store.address != null &&
                                  store.address!.isNotEmpty) ...[
                                const SizedBox(height: 0),
                                Row(
                                  textDirection:
                                      Get.find<LocalizationController>().isLtr
                                          ? TextDirection.ltr
                                          : TextDirection.rtl,
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        color: isPharmacy
                                            ? Colors.blue
                                            : Theme.of(context).primaryColor,
                                        size: 15),
                                    const SizedBox(
                                        width:
                                            Dimensions.paddingSizeExtraSmall),
                                    Expanded(
                                      child: Text(
                                        store.address ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextDirection.ltr
                                                : TextDirection.rtl,
                                        textAlign:
                                            Get.find<LocalizationController>()
                                                    .isLtr
                                                ? TextAlign.left
                                                : TextAlign.right,
                                        style: robotoRegular.copyWith(
                                          color:
                                              Theme.of(context).disabledColor,
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      widget.fromTopOffers!
                          ? Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault),
                                child: Column(
                                    crossAxisAlignment:
                                        Get.find<LocalizationController>().isLtr
                                            ? CrossAxisAlignment.start
                                            : CrossAxisAlignment.end,
                                    children: [
                                      const SizedBox(
                                          height:
                                              Dimensions.paddingSizeExtraSmall),
                                      Flexible(
                                        child: Text(
                                          store.address ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: robotoRegular.copyWith(
                                            color:
                                                Theme.of(context).disabledColor,
                                            fontSize:
                                                Dimensions.fontSizeExtraSmall,
                                          ),
                                        ),
                                      ),
                                      Row(children: [
                                        if (store.ratingCount! > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: Dimensions
                                                    .paddingSizeDefault),
                                            child: Row(children: [
                                              Icon(Icons.star,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  size: 14),
                                              const SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeExtraSmall),
                                              Text('${store.avgRating}',
                                                  style: robotoRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraSmall)),
                                              const SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeExtraSmall),
                                              Text('(${store.ratingCount})',
                                                  style: robotoRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraSmall,
                                                      color: Theme.of(context)
                                                          .disabledColor)),
                                            ]),
                                          ),
                                        Text('${store.itemCount} ${'items'.tr}',
                                            style: robotoRegular.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeExtraSmall,
                                                color: Theme.of(context)
                                                    .primaryColor)),
                                      ]),
                                    ]),
                              ),
                            )
                          : Expanded(
                              flex: 3,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    textDirection: TextDirection.ltr,
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            height: 28,
                                            child: CustomButton(
                                              height: 28,
                                              radius: Dimensions.radiusSmall,
                                              onPressed: () {
                                                unawaited(_handleStoreTap(store));
                                              },
                                              buttonText: 'visit'.tr,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              textColor:
                                                  Theme.of(context).cardColor,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 🔧 FIX: Hide distance widget if distance is invalid/null
                                      if (distanceKm != null && distanceKm > 0)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2, horizontal: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions.radiusLarge),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Image.asset(Images.distanceLine,
                                                    height: 12, width: 12),
                                                const SizedBox(width: 2),
                                                Text(
                                                  distanceKm > 100
                                                      ? '100+ ${'km'.tr}'
                                                      : '${distanceKm.toStringAsFixed(1)} ${'km'.tr}',
                                                  style: robotoBold.copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontSize: 9),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox.shrink(),
                                    ]),
                              ),
                            ),
                    ]),
                  ),
                ]);
              }),
            ),
          ),
          Positioned(
            top: widget.fromTopOffers! ? 40 : 60,
            left: Get.find<LocalizationController>().isLtr ? 15 : null,
            right: Get.find<LocalizationController>().isLtr ? null : 15,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 65,
                  width: 65,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: Hero(
                      tag: _heroTag('store_logo', store.id ?? 0),
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
                        image: (store.coverPhotoFullUrl != null &&
                                store.coverPhotoFullUrl!.isNotEmpty)
                            ? store.coverPhotoFullUrl!
                            : (store.logoFullUrl ?? ''),
                        imageStatus: (store.coverPhotoFullUrl != null &&
                                store.coverPhotoFullUrl!.isNotEmpty)
                            ? store.coverPhotoStatus
                            : store.logoStatus,
                        height: double.infinity,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                store.avgRating! > 0
                    ? Positioned(
                        bottom: -5,
                        right: 5,
                        left: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusDefault),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  spreadRadius: 1)
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            textDirection:
                                Get.find<LocalizationController>().isLtr
                                    ? TextDirection.ltr
                                    : TextDirection.rtl,
                            children: [
                              Text(
                                store.avgRating!.toStringAsFixed(1),
                                textDirection:
                                    Get.find<LocalizationController>().isLtr
                                        ? TextDirection.ltr
                                        : TextDirection.rtl,
                                style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall),
                              ),
                              const SizedBox(width: 3),
                              Icon(Icons.star,
                                  color: Theme.of(context).primaryColor,
                                  size: 15),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
