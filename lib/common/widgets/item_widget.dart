import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/corner_banner/banner.dart';
import 'package:sixam_mart/common/widgets/corner_banner/corner_discount_tag.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/common/widgets/organic_tag.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemWidget extends StatelessWidget {
  final Item? item;
  final Store? store;
  final bool isStore;
  final int index;
  final int? length;
  final bool inStore;
  final bool isCampaign;
  final bool isFeatured;
  final bool fromCartSuggestion;
  final double? imageHeight;
  final double? imageWidth;
  final bool? isCornerTag;
  final bool verticalItem;

  const ItemWidget({
    super.key,
    required this.item,
    required this.isStore,
    required this.store,
    required this.index,
    required this.length,
    this.inStore = false,
    this.isCampaign = false,
    this.verticalItem = false,
    this.isFeatured = false,
    this.fromCartSuggestion = false,
    this.imageHeight,
    this.imageWidth,
    this.isCornerTag = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool ltr = Get.find<LocalizationController>().isLtr;
    final bool desktop = ResponsiveHelper.isDesktop(context);

    // Determine discount and availability based on item or store
    final double? discount = _getDiscount();
    final String? discountType = _getDiscountType();
    final bool isAvailable = _getAvailability();

    // 🔥 FIX: Add height constraints for SliverList compatibility
    // Vertical items need more height, horizontal items need less
    final double minHeight = verticalItem ? 140.0 : 100.0;
    final double maxHeight = verticalItem ? 200.0 : 140.0;

    return Container(
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight,
      ),
      child: Stack(
        children: [
          _buildMainContainer(
              context, desktop, discount, discountType, isAvailable, ltr),
          _buildCornerDiscountTag(discount, discountType, ltr),
          // Heart icon - topmost layer with responsive positioning
          Positioned(
            top: verticalItem ? 1 : 8,
            right: ltr ? (verticalItem ? 10 : 8) : null,
            left: ltr ? null : (verticalItem ? 10 : 8),
            child:
                GetBuilder<FavouriteController>(builder: (favouriteController) {
              // 🎯 PERFORMANCE: Cache lookup result - no calculation in build
              // Contains is O(n) but acceptable for small lists (~100 items)
              // Better: Use Set<int> in controller for O(1) lookup
              final int? targetId = isStore ? store?.id : item?.id;
              final List<int?> wishList = isStore
                  ? favouriteController.wishStoreIdList
                  : favouriteController.wishItemIdList;
              final bool isWished =
                  targetId != null && wishList.contains(targetId);

              return CustomFavouriteWidget(
                  isWished: isWished,
                  isStore: isStore,
                  store: store,
                  item: item);
            }),
          ),
        ],
      ),
    );
  }

  // Helper methods to get discount, type, and availability
  double? _getDiscount() {
    if (isStore) {
      return store!.discount != null ? store!.discount!.discount : 0;
    }
    return (item!.storeDiscount == 0 || isCampaign)
        ? item!.discount
        : item!.storeDiscount;
  }

  String? _getDiscountType() {
    if (isStore) {
      return store!.discount != null
          ? store!.discount!.discountType
          : 'percent';
    }
    return (item!.storeDiscount == 0 || isCampaign)
        ? item!.discountType
        : 'percent';
  }

  bool _getAvailability() {
    if (isStore) {
      return store!.isOpen == true && store!.active!;
    }
    // TEMP: force product availability.
    return true;
  }

  // Main container widget
  Widget _buildMainContainer(BuildContext context, bool desktop,
      double? discount, String? discountType, bool isAvailable, bool ltr) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
        ],
      ),
      child: CustomInkWell(
        onTap: _onItemTap,
        radius: Dimensions.radiusDefault,
        padding: ResponsiveHelper.isDesktop(context)
            ? EdgeInsets.all(fromCartSuggestion
                ? Dimensions.paddingSizeExtraSmall
                : Dimensions.paddingSizeSmall)
            : const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeExtraSmall),
        child: TextHover(builder: (hovered) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: desktop ? 0 : Dimensions.paddingSizeExtraSmall),
                  child: verticalItem
                      ? Column(
                          children: [
                            _buildImageSection(context, hovered, discount,
                                discountType, isAvailable),
                            _buildTextInfo(context, hovered),
                          ],
                        )
                      : Row(
                          children: [
                            _buildImageSection(context, hovered, discount,
                                discountType, isAvailable),
                            _buildTextInfo(context, hovered),
                          ],
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Item on tap handler
  void _onItemTap() {
    if (isStore) {
      if (store != null) {
        if (isFeatured && Get.find<SplashController>().moduleList != null) {
          for (final ModuleModel module
              in Get.find<SplashController>().moduleList!) {
            if (module.id == store!.moduleId) {
              Get.find<SplashController>().setModule(module);
              break;
            }
          }
        }
        Get.toNamed(
          RouteHelper.getStoreRoute(
              id: store!.id, page: isFeatured ? 'module' : 'item'),
          arguments: StoreScreen(store: store, fromModule: isFeatured),
        );
      }
    } else {
      if (item != null) {
        // Added null check for item
        if (isFeatured && Get.find<SplashController>().moduleList != null) {
          for (final ModuleModel module
              in Get.find<SplashController>().moduleList!) {
            if (module.id == item!.moduleId) {
              Get.find<SplashController>().setModule(module);
              break;
            }
          }
        }
        Get.find<ItemController>().navigateToItemPage(item!, Get.context!,
            inStore: inStore, isCampaign: isCampaign);
      }
    }
  }

  // Text info widget
  Widget _buildTextInfo(BuildContext context, bool hovered) {
    final bool ltr = Get.find<LocalizationController>().isLtr;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: ltr ? 0 : 8, left: ltr ? 8 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment:
              ltr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                _buildItemName(),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _buildItemUnit(context),
              ],
            ),
            _buildStoreOrItemDescription(context),
            if (!isStore &&
                item!.nutrition != null &&
                item!.nutrition!.calories != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item!.nutrition!.calories} ${'calories'.tr}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _buildPriceSection(context),
                  ),
                  CartCountView(item: item!, index: index),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemName() {
    return Flexible(
      child: Text(
        isStore ? store!.name! : item!.name!,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildItemUnit(BuildContext context) {
    if (Get.find<SplashController>().configModel?.moduleConfig?.module?.unit ==
            true &&
        item != null &&
        item!.unitType != null) {
      return Text(
        '(${item!.unitType ?? ''})',
        style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall,
          color: Theme.of(context).primaryColor,
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildStoreOrItemDescription(BuildContext context) {
    return Text(
      isStore ? (store?.address ?? '') : (item?.storeName ?? ''),
      style: robotoBold.copyWith(
        fontSize: Dimensions.fontSizeSmall,
        color: Theme.of(context).disabledColor,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  // Price section widget
  Widget _buildPriceSection(BuildContext context) {
    final discount = _getDiscount();
    final color =
        Theme.of(context).extension<CustomThemeExtension>()?.yellow_Color;

    return Row(
      children: [
        if (discount != null &&
            discount > 0 &&
            item!.originalPrice != null) ...[
          PriceConverter.convertPrice2(
            item!.originalPrice!,
            textStyle: robotoBold.copyWith(
              fontSize: 11,
              color: Theme.of(context).disabledColor,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        ],
        PriceConverter.convertPrice2(
          item!.price,
          // ✅ NO discount/discountType - backend already calculated it!
          textStyle: robotoBold.copyWith(
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  // Image section widget
  Widget _buildImageSection(BuildContext context, bool hovered,
      double? discount, String? discountType, bool isAvailable) {
    final bool ltr = Get.find<LocalizationController>().isLtr;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: ltr ? 17 : 0, right: ltr ? 0 : 17),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: isStore && store != null
                ? Hero(
                    tag: 'store_logo_${store?.id ?? 0}',
                    child: CustomImage(
                      isHovered: hovered,
                      image: store?.logoFullUrl ?? '',
                      imageStatus: store?.logoStatus ?? 'ok',
                      height: imageHeight ??
                          (ResponsiveHelper.isDesktop(context)
                              ? 130
                              : length == null
                                  ? 110
                                  : 100),
                      width: imageWidth ??
                          (ResponsiveHelper.isDesktop(context) ? 120 : 100),
                    ),
                  )
                : CustomImage(
                    isHovered: hovered,
                    image: item?.displayImage ?? '',
                    fallbackUrls: item?.imagesFullUrl,
                    imageStatus: item?.imageStatus ?? 'ok',
                    height: imageHeight ??
                        (ResponsiveHelper.isDesktop(context)
                            ? 130
                            : length == null
                                ? 110
                                : 100),
                    width: imageWidth ??
                        (ResponsiveHelper.isDesktop(context) ? 120 : 100),
                  ),
          ),
        ),

        //

        (isStore || isCornerTag!)
            ? DiscountTag(
                discount: discount,
                discountType: discountType,
                freeDelivery: isStore ? store!.freeDelivery : false)
            : const SizedBox(),
        !isStore
            ? OrganicTag(item: item!, placeInImage: true)
            : const SizedBox(),
        isAvailable ? const SizedBox() : NotAvailableWidget(isStore: isStore),

        //
      ],
    );
  }

  // Corner discount tag widget
  Widget _buildCornerDiscountTag(
      double? discount, String? discountType, bool ltr) {
    return (!isStore && isCornerTag! == false)
        ? Positioned(
            right: ltr ? 0 : null,
            left: ltr ? null : 0,
            child: CornerDiscountTag(
              bannerPosition: ltr
                  ? CornerBannerPosition.topRight
                  : CornerBannerPosition.topLeft,
              discount: discount,
              discountType: discountType,
              freeDelivery: isStore ? store!.freeDelivery : false,
            ),
          )
        : const SizedBox();
  }
}

class SimilarItemWidget extends StatelessWidget {
  final Item? item;

  const SimilarItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bool ltr = Get.find<LocalizationController>().isLtr;
    final bool desktop = ResponsiveHelper.isDesktop(context);

    // Determine discount and availability based on item or store
    final double? discount = _getDiscount();
    final String? discountType = _getDiscountType();
    final bool isAvailable = _getAvailability();

    return _buildMainContainer(
        context, desktop, discount, discountType, isAvailable, ltr);
  }

  // Helper methods to get discount, type, and availability
  double? _getDiscount() {
    return (item!.storeDiscount == 0) ? item!.discount : item!.storeDiscount;
  }

  String? _getDiscountType() {
    return (item!.storeDiscount == 0) ? item!.discountType : 'percent';
  }

  bool _getAvailability() {
    // TEMP: force product availability.
    return true;
  }

  // Main container widget
  Widget _buildMainContainer(BuildContext context, bool desktop,
      double? discount, String? discountType, bool isAvailable, bool ltr) {
    return Container(
      margin: ResponsiveHelper.isDesktop(context)
          ? null
          : const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
        ],
      ),
      width: 250,
      height: 200,
      child: CustomInkWell(
        onTap: _onItemTap,
        radius: Dimensions.radiusDefault,
        padding: ResponsiveHelper.isDesktop(context)
            ? const EdgeInsets.all(Dimensions.paddingSizeSmall)
            : const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeExtraSmall),
        child: TextHover(builder: (hovered) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical:
                            desktop ? 0 : Dimensions.paddingSizeExtraSmall),
                    child: Column(
                      children: [
                        _buildImageSection(context, hovered, discount,
                            discountType, isAvailable),
                        _buildTextInfo(context, hovered),
                      ],
                    )),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Item on tap handler
  void _onItemTap() {
    Get.find<ItemController>().navigateToItemPage(
      item!,
      Get.context!,
    );
  }

  // Text info widget
  Widget _buildTextInfo(BuildContext context, bool hovered) {
    final bool ltr = Get.find<LocalizationController>().isLtr;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: ltr ? 0 : 8, left: ltr ? 8 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment:
              ltr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                _buildItemName(),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _buildItemUnit(context),
              ],
            ),
            _buildStoreOrItemDescription(context),
            if (item!.nutrition != null && item!.nutrition!.calories != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item!.nutrition!.calories} ${'calories'.tr}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Flexible(
                  child: _buildPriceSection(context),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraLarge),
                CartCountView(
                  item: item!,
                  index: 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemName() {
    return Flexible(
      child: Text(
        item!.name!,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildItemUnit(BuildContext context) {
    if (Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! &&
        item != null &&
        item!.unitType != null) {
      return Text(
        '(${item!.unitType ?? ''})',
        style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall,
          color: Theme.of(context).primaryColor,
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildStoreOrItemDescription(BuildContext context) {
    return Text(
      item!.storeName ?? '',
      style: robotoBold.copyWith(
        fontSize: Dimensions.fontSizeSmall,
        color: Theme.of(context).disabledColor,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  // Price section widget
  Widget _buildPriceSection(BuildContext context) {
    final discount = _getDiscount();
    final color =
        Theme.of(context).extension<CustomThemeExtension>()?.yellow_Color;

    return Row(
      children: [
        if (discount != null &&
            discount > 0 &&
            item!.originalPrice != null) ...[
          PriceConverter.convertPrice2(
            item!.originalPrice!,
            textStyle: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).disabledColor,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        ],
        PriceConverter.convertPrice2(
          item!.price,
          // ✅ NO discount/discountType - backend already calculated it!
          textStyle: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
            color: color,
          ),
        ),
      ],
    );
  }

  // Image section widget
  Widget _buildImageSection(BuildContext context, bool hovered,
      double? discount, String? discountType, bool isAvailable) {
    final bool ltr = Get.find<LocalizationController>().isLtr;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: ltr ? 17 : 0, right: ltr ? 0 : 17),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: CustomImage(
              isHovered: hovered,
              image: item?.displayImage ?? '',
              fallbackUrls: item?.imagesFullUrl,
              imageStatus: item?.imageStatus ?? 'ok',
              height: 100,
              width: 120,
            ),
          ),
        ),

        //

        const SizedBox(),
        isAvailable ? const SizedBox() : const NotAvailableWidget(),

        //

        Positioned(
          top: 8,
          right: ltr ? 8 : null,
          left: ltr ? null : 8,
          child:
              GetBuilder<FavouriteController>(builder: (favouriteController) {
            favouriteController.wishItemIdList.contains(item!.id);
            return CustomFavouriteWidget(isWished: false, item: item);
          }),
        ),
      ],
    );
  }
}

// import 'package:sixam_mart/common/widgets/cart_count_view.dart';
// import 'package:sixam_mart/common/widgets/corner_banner/banner.dart';
// import 'package:sixam_mart/common/widgets/corner_banner/corner_discount_tag.dart';
// import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
// import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
// import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
// import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
// import 'package:sixam_mart/features/item/controllers/item_controller.dart';
// import 'package:sixam_mart/features/language/controllers/language_controller.dart';
// import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
// import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
// import 'package:sixam_mart/features/item/domain/models/item_model.dart';
// import 'package:sixam_mart/common/models/module_model.dart';
// import 'package:sixam_mart/features/store/domain/models/store_model.dart';
// import 'package:sixam_mart/helper/date_converter.dart';
// import 'package:sixam_mart/helper/price_converter.dart';
// import 'package:sixam_mart/helper/responsive_helper.dart';
// import 'package:sixam_mart/helper/route_helper.dart';
// import 'package:sixam_mart/util/dimensions.dart';
// import 'package:sixam_mart/util/images.dart';
// import 'package:sixam_mart/util/styles.dart';
// import 'package:sixam_mart/common/widgets/custom_image.dart';
// import 'package:sixam_mart/common/widgets/discount_tag.dart';
// import 'package:sixam_mart/common/widgets/not_available_widget.dart';
// import 'package:sixam_mart/common/widgets/organic_tag.dart';
// import 'package:sixam_mart/features/store/screens/store_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class ItemWidget extends StatelessWidget {
//   final Item? item;
//   final Store? store;
//   final bool isStore;
//   final int index;
//   final int? length;
//   final bool inStore;
//   final bool isCampaign;
//   final bool isFeatured;
//   final bool fromCartSuggestion;
//   final double? imageHeight;
//   final double? imageWidth;
//   final bool? isCornerTag;
//   const ItemWidget(
//       {super.key,
//       required this.item,
//       required this.isStore,
//       required this.store,
//       required this.index,
//       required this.length,
//       this.inStore = false,
//       this.isCampaign = false,
//       this.isFeatured = false,
//       this.fromCartSuggestion = false,
//       this.imageHeight,
//       this.imageWidth,
//       this.isCornerTag = false});

//   @override
//   Widget build(BuildContext context) {
//     final bool ltr = Get.find<LocalizationController>().isLtr;
//     bool desktop = ResponsiveHelper.isDesktop(context);
//     double? discount;
//     String? discountType;
//     bool isAvailable;
//     String genericName = '';

//     if (!isStore && item!.genericName != null && item!.genericName!.isNotEmpty) {
//       for (String name in item!.genericName!) {
//         genericName += name;
//       }
//     }
//     if (isStore) {
//       discount = store!.discount != null ? store!.discount!.discount : 0;
//       discountType = store!.discount != null ? store!.discount!.discountType : 'percent';
//       isAvailable = store!.open == 1 && store!.active!;
//     } else {
//       discount = (item!.storeDiscount == 0 || isCampaign) ? item!.discount : item!.storeDiscount;
//       discountType = (item!.storeDiscount == 0 || isCampaign) ? item!.discountType : 'percent';
//       isAvailable = DateConverter.isAvailable(item!.availableTimeStarts, item!.availableTimeEnds);
//     }

//     return Stack(
//       children: [
//         Container(
//           margin: ResponsiveHelper.isDesktop(context) ? null : const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//             color: Theme.of(context).cardColor,
//             boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
//           ),
//           child: CustomInkWell(
//             onTap: () {
//               if (isStore) {
//                 if (store != null) {
//                   if (isFeatured && Get.find<SplashController>().moduleList != null) {
//                     for (ModuleModel module in Get.find<SplashController>().moduleList!) {
//                       if (module.id == store!.moduleId) {
//                         Get.find<SplashController>().setModule(module);
//                         break;
//                       }
//                     }
//                   }
//                   Get.toNamed(
//                     RouteHelper.getStoreRoute(id: store!.id, page: isFeatured ? 'module' : 'item'),
//                     arguments: StoreScreen(store: store, fromModule: isFeatured),
//                   );
//                 }
//               } else {
//                 if (isFeatured && Get.find<SplashController>().moduleList != null) {
//                   for (ModuleModel module in Get.find<SplashController>().moduleList!) {
//                     if (module.id == item!.moduleId) {
//                       Get.find<SplashController>().setModule(module);
//                       break;
//                     }
//                   }
//                 }
//                 Get.find<ItemController>().navigateToItemPage(item, context, inStore: inStore, isCampaign: isCampaign);
//               }
//             },
//             radius: Dimensions.radiusDefault,
//             padding: ResponsiveHelper.isDesktop(context)
//                 ? EdgeInsets.all(fromCartSuggestion ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall)
//                 : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
//             child: TextHover(builder: (hovered) {
//               return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//                 Expanded(
//                     child: Padding(
//                   padding: EdgeInsets.symmetric(vertical: desktop ? 0 : Dimensions.paddingSizeExtraSmall),
//                   child: Row(children: [
//                     Stack(children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//                         child: CustomImage(
//                           isHovered: hovered,
//                           image: '${isStore ? store != null ? store!.logoFullUrl : '' : item!.imageFullUrl}',
//                           height: imageHeight ??
//                               (desktop
//                                   ? 120
//                                   : length == null
//                                       ? 100
//                                       : 90),
//                           width: imageWidth ?? (desktop ? 120 : 90),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       (isStore || isCornerTag!)
//                           ? DiscountTag(
//                               discount: discount,
//                               discountType: discountType,
//                               freeDelivery: isStore ? store!.freeDelivery : false,
//                             )
//                           : const SizedBox(),
//                       !isStore ? OrganicTag(item: item!, placeInImage: true) : const SizedBox(),
//                       isAvailable ? const SizedBox() : NotAvailableWidget(isStore: isStore),
//                       Positioned(
//                         top: 5,
//                         left: 5,
//                         child: GetBuilder<FavouriteController>(builder: (favouriteController) {
//                           bool isWished = isStore
//                               ? favouriteController.wishStoreIdList.contains(store!.id)
//                               : favouriteController.wishItemIdList.contains(item!.id);
//                           return CustomFavouriteWidget(
//                             isWished: isWished,
//                             isStore: isStore,
//                             store: store,
//                             item: item,
//                           );
//                         }),
//                       ),
//                     ]),
//                     const SizedBox(width: Dimensions.paddingSizeSmall),
//                     Expanded(
//                       child:
//                           Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
//                         Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
//                           Flexible(
//                             child: Text(
//                               isStore ? store!.name! : item!.name!,
//                               style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           const SizedBox(width: Dimensions.paddingSizeExtraSmall),
//                           (!isStore &&
//                                   Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! &&
//                                   Get.find<SplashController>().configModel!.toggleVegNonVeg!)
//                               ? Image.asset(item != null && item!.veg == 0 ? Images.nonVegImage : Images.vegImage,
//                                   height: 10, width: 10, fit: BoxFit.contain)
//                               : const SizedBox(),
//                           (Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! &&
//                                   item != null &&
//                                   item!.unitType != null)
//                               ? Text(
//                                   '(${item!.unitType ?? ''})',
//                                   style: robotoRegular.copyWith(
//                                       fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
//                                 )
//                               : const SizedBox(),
//                           SizedBox(width: item!.isStoreHalalActive! && item!.isHalalItem! ? Dimensions.paddingSizeExtraSmall : 0),
//                           !isStore && item!.isStoreHalalActive! && item!.isHalalItem!
//                               ? const CustomAssetImageWidget(Images.halalTag, height: 13, width: 13)
//                               : const SizedBox(),
//                           SizedBox(width: ResponsiveHelper.isDesktop(context) ? 20 : 0),
//                         ]),
//                         const SizedBox(height: 3),
//                         (isStore ? store!.address != null : item!.storeName != null)
//                             ? Text(
//                                 isStore ? store!.address ?? '' : item!.storeName ?? '',
//                                 style: robotoRegular.copyWith(
//                                   fontSize: Dimensions.fontSizeExtraSmall,
//                                   color: Theme.of(context).disabledColor,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               )
//                             : const SizedBox(),
//                         (genericName.isNotEmpty)
//                             ? Flexible(
//                                 child: Padding(
//                                   padding: const EdgeInsets.only(top: 5.0),
//                                   child: Text(
//                                     genericName,
//                                     style: robotoMedium.copyWith(
//                                       fontSize: Dimensions.fontSizeSmall,
//                                       color: Theme.of(context).disabledColor,
//                                     ),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               )
//                             : const SizedBox(),
//                         SizedBox(
//                             height: ((desktop || isStore) && (isStore ? store!.address != null : item!.storeName != null)) ? 3 : 3),
//                         !isStore && (item!.ratingCount! > 0)
//                             ? Row(children: [
//                                 Icon(Icons.star, size: 16, color: Theme.of(context).primaryColor),
//                                 const SizedBox(width: Dimensions.paddingSizeExtraSmall),
//                                 Text(
//                                   item!.avgRating!.toStringAsFixed(1),
//                                   style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
//                                 ),
//                                 const SizedBox(width: Dimensions.paddingSizeExtraSmall),
//                                 Text(
//                                   '(${item!.ratingCount})',
//                                   style:
//                                       robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
//                                 ),
//                               ])
//                             : const SizedBox(),
//                         SizedBox(height: (!isStore && desktop) || (!isStore && (item!.ratingCount! > 0)) ? 3 : 0),
//                         isStore && (store != null && store!.ratingCount! > 0)
//                             ? Row(children: [
//                                 Icon(Icons.star, size: 16, color: Theme.of(context).primaryColor),
//                                 const SizedBox(width: Dimensions.paddingSizeExtraSmall),
//                                 Text(
//                                   store!.avgRating!.toStringAsFixed(1),
//                                   style: robotoMedium,
//                                 ),
//                                 const SizedBox(width: Dimensions.paddingSizeExtraSmall),
//                                 Text(
//                                   '(${store!.ratingCount})',
//                                   style:
//                                       robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
//                                 ),
//                               ])
//                             : Row(children: [
//                                 Text(
//                                   PriceConverter.convertPrice(item!.price, discount: discount, discountType: discountType),
//                                   style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
//                                   textDirection: TextDirection.ltr,
//                                 ),
//                                 SizedBox(width: discount! > 0 ? Dimensions.paddingSizeExtraSmall : 0),
//                                 discount > 0
//                                     ? Text(
//                                         PriceConverter.convertPrice(item!.price),
//                                         style: robotoMedium.copyWith(
//                                           fontSize: Dimensions.fontSizeExtraSmall,
//                                           color: Theme.of(context).disabledColor,
//                                           decoration: TextDecoration.lineThrough,
//                                         ),
//                                         textDirection: TextDirection.ltr,
//                                       )
//                                     : const SizedBox(),
//                               ]),
//                       ]),
//                     ),
//                     Column(mainAxisAlignment: isStore ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween, children: [
//                       const SizedBox(),
//                       CartCountView(
//                         item: item!,
//                         index: index,
//                       ),
//                     ]),
//                   ]),
//                 )),
//               ]);
//             }),
//           ),
//         ),
//         (!isStore && isCornerTag! == false)
//             ? Positioned(
//                 right: ltr ? 0 : null,
//                 left: ltr ? null : 0,
//                 child: CornerDiscountTag(
//                   bannerPosition: ltr ? CornerBannerPosition.topRight : CornerBannerPosition.topLeft,
//                   elevation: 0,
//                   discount: discount,
//                   discountType: discountType,
//                   freeDelivery: isStore ? store!.freeDelivery : false,
//                 ))
//             : const SizedBox(),
//       ],
//     );
//   }
// }
