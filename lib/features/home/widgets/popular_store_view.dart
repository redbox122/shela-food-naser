// ignore_for_file: deprecated_member_use

import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PopularStoreView extends StatelessWidget {
  final bool isPopular;
  final bool isFeatured;
  const PopularStoreView({super.key, required this.isPopular, required this.isFeatured});

  @override
Widget build(BuildContext context) {
  return GetBuilder<StoreController>(builder: (storeController) {
    final List<Store>? storeList = isFeatured
        ? storeController.featuredStoreList
        : isPopular
            ? storeController.popularStoreList
            : storeController.latestStoreList;

    // Header with title and toggle button
    final Widget header = Padding(
      padding: EdgeInsets.fromLTRB(10, isPopular ? 2 : 15, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            final splashController = Get.find<SplashController>();
            final moduleId = splashController.selectedModule.value?.id ??
                splashController.module?.id;
            final moduleName =
                (splashController.selectedModule.value?.moduleName ??
                        splashController.module?.moduleName ??
                        '')
                    .trim();
            final bool showRestaurantText =
                splashController.configModel?.moduleConfig?.module?.showRestaurantText ??
                    false;
            final String popularTitle = moduleId == 9
                ? 'المقاهي'
                : (moduleName.isNotEmpty
                    ? moduleName
                    : (showRestaurantText
                        ? 'popular_restaurants'.tr
                        : 'popular_stores'.tr));
            final String title = isFeatured
                ? 'featured_stores'.tr
                : isPopular
                    ? popularTitle
                    : '${'new_on'.tr} ${AppConstants.appName}';
            return TitleWidget(
              title: title,
              onTap: () => Get.toNamed(RouteHelper.getAllStoreRoute(isFeatured
                  ? 'featured'
                  : isPopular
                      ? 'popular'
                      : 'latest')),
            );
          }),
          IconButton(
            icon: Icon(
              storeController.isVertical ? Icons.grid_view : Icons.view_list,
              color: Theme.of(context).primaryColor,
            ),
            tooltip: storeController.isVertical ? 'Grid View' : 'List View',
            onPressed: () {
              storeController.setVerticalItems(!storeController.isVertical);
            },
          ),
        ],
      ),
    );

    // Content: Grid or List view
    Widget content;
    if (storeList == null) {
      // Still loading - show shimmer
      content = const PopularStoreShimmer();
    } else if (storeList.isEmpty) {
      // API returned 0 stores - show empty state message
      content = Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_outlined,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                    ? 'no_restaurant_available'.tr
                    : 'no_store_available'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).disabledColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'no_stores_found_in_your_area'.tr.isEmpty 
                    ? 'Try changing your location or check back later'
                    : 'no_stores_found_in_your_area'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).disabledColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      if (storeController.isVertical) {
        content = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: Dimensions.paddingSizeSmall,
            crossAxisSpacing: Dimensions.paddingSizeSmall,
            childAspectRatio: 200 / 150,
          ),
          itemCount: storeList.length > 7 ? 7 : storeList.length,
          itemBuilder: (context, index) {
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                boxShadow: [
                  BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200]!, blurRadius: 5, spreadRadius: 1),
                ],
              ),
              child: InkWell(
                onTap: () {
                  if (isFeatured && Get.find<SplashController>().moduleList != null) {
                    for (final ModuleModel module in Get.find<SplashController>().moduleList!) {
                      if (module.id == storeList[index].moduleId) {
                        Get.find<SplashController>().setModule(module);
                        break;
                      }
                    }
                  }
                  Get.toNamed(
                    RouteHelper.getStoreRoute(id: storeList[index].id, page: isFeatured ? 'module' : 'store'),
                    arguments: StoreScreen(store: storeList[index], fromModule: isFeatured),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSmall)),
                          child: CustomImage(
                            image: '${storeList[index].coverPhotoFullUrl}',
                            height: 90,
                            width: 200,
                          ),
                        ),
                        GetBuilder<FavouriteController>(builder: (favouriteController) {
                          final bool isWished = favouriteController.wishStoreIdList.contains(storeList[index].id);
                          return Positioned(
                            top: Dimensions.paddingSizeExtraSmall,
                            right: Dimensions.paddingSizeExtraSmall,
                            child: InkWell(
                              onTap: () {
                                if (AuthHelper.isLoggedIn()) {
                                  isWished
                                      ? favouriteController.removeFromFavouriteList(storeList[index].id, true)
                                      : favouriteController.addToFavouriteList(null, storeList[index].id, true);
                                } else {
                                  showCustomSnackBar('you_are_not_logged_in'.tr);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                                  borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                                ),
                                child: Icon(
                                  isWished ? Icons.favorite : Icons.favorite_border,
                                  size: 15,
                                  color: isWished ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              storeList[index].name ?? '',
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              storeList[index].address ?? '',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).disabledColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            RatingBar(
                              rating: storeList[index].avgRating,
                              size: 12,
                              ratingCount: storeList[index].ratingCount,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // Existing horizontal list view (limited to 10 items)
        content = SizedBox(
          height: 170,
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          itemCount: storeList.length > 7 ? 7 : storeList.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                  boxShadow: [
                    BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200]!, blurRadius: 5, spreadRadius: 1),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    if (isFeatured && Get.find<SplashController>().moduleList != null) {
                      for (final ModuleModel module in Get.find<SplashController>().moduleList!) {
                        if (module.id == storeList[index].moduleId) {
                          Get.find<SplashController>().setModule(module);
                          break;
                        }
                      }
                    }
                    Get.toNamed(
                      RouteHelper.getStoreRoute(id: storeList[index].id, page: isFeatured ? 'module' : 'store'),
                      arguments: StoreScreen(store: storeList[index], fromModule: isFeatured),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSmall)),
                            child: CustomImage(
                              image: '${storeList[index].coverPhotoFullUrl}',
                              height: 90,
                              width: 200,
                            ),
                          ),
                          GetBuilder<FavouriteController>(builder: (favouriteController) {
                            final bool isWished = favouriteController.wishStoreIdList.contains(storeList[index].id);
                            return Positioned(
                              top: Dimensions.paddingSizeExtraSmall,
                              right: Dimensions.paddingSizeExtraSmall,
                              child: InkWell(
                                onTap: () {
                                  if (AuthHelper.isLoggedIn()) {
                                    isWished
                                        ? favouriteController.removeFromFavouriteList(storeList[index].id, true)
                                        : favouriteController.addToFavouriteList(null, storeList[index].id, true);
                                  } else {
                                    showCustomSnackBar('you_are_not_logged_in'.tr);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                                  ),
                                  child: Icon(
                                    isWished ? Icons.favorite : Icons.favorite_border,
                                    size: 15,
                                    color: isWished ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                storeList[index].name ?? '',
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                storeList[index].address ?? '',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              RatingBar(
                                rating: storeList[index].avgRating,
                                size: 12,
                                ratingCount: storeList[index].ratingCount,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    }

    return Column(
      children: [
        header,
        const SizedBox(height: 10),
        Expanded(child: content),
      ],
    );
  });
}

}

class PopularStoreShimmer extends StatelessWidget {
  const PopularStoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeSmall,
                0,
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeExtraSmall),
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
              itemCount: 7,
              itemBuilder: (context, index) {
                return Container(
                  height: 150,
                  width: 200,
                  margin: const EdgeInsets.only(
                      right: Dimensions.paddingSizeSmall, bottom: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Dimensions.radiusSmall)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[300]!,
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 90,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(Dimensions.radiusSmall)),
                          color: Colors.grey[300],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(
                              Dimensions.paddingSizeExtraSmall),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 10,
                                width: 100,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: 10,
                                width: 130,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 8,
                                width: 70,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
