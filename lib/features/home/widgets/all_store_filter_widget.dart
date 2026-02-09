import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/store_filter_button_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class AllStoreFilterWidget extends StatelessWidget {
  const AllStoreFilterWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      final splashController = Get.find<SplashController>();
      final isFood =
          splashController.module?.moduleType.toString() == AppConstants.food;
      final showRestaurantText = splashController
          .configModel!.moduleConfig!.module!.showRestaurantText!;

      // For Food module, use "nearest_restaurants_to_you", otherwise use existing logic
      final subtitleKey = isFood && showRestaurantText
          ? 'nearest_restaurants_to_you'
          : (showRestaurantText ? 'restaurants_near_you' : 'stores_near_you');

      return Center(
        child: Container(
          width: Dimensions.webMaxWidth,
          transform: Matrix4.translationValues(0, -2, 0),
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.only(
              left: Dimensions.paddingSizeDefault,
              top: Dimensions.paddingSizeSmall),
          child: ResponsiveHelper.isDesktop(context)
              ? Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showRestaurantText ? 'restaurants'.tr : 'stores'.tr,
                            style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeLarge),
                          ),
                          Text(
                            '${storeController.allStoreModel?.totalSize ?? 0} ${subtitleKey.tr}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(
                                color: Theme.of(context).disabledColor,
                                fontSize: Dimensions.fontSizeSmall),
                          ),
                        ]),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  IconButton(
                    icon: Icon(
                      storeController.isVertical
                          ? Icons.grid_view
                          : Icons.view_list,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    onPressed: () {
                      storeController
                          .setVerticalItems(!storeController.isVertical);
                    },
                    tooltip:
                        storeController.isVertical ? 'Grid View' : 'List View',
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  filter(context, storeController),
                ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        right: Dimensions.paddingSizeSmall),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  showRestaurantText
                                      ? 'restaurants'.tr
                                      : 'stores'.tr,
                                  style: robotoBold.copyWith(
                                      fontSize: Dimensions.fontSizeLarge),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${storeController.allStoreModel?.totalSize ?? 0} ${subtitleKey.tr}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: robotoRegular.copyWith(
                                      color: Theme.of(context).disabledColor,
                                      fontSize: Dimensions.fontSizeSmall),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            icon: Icon(
                              storeController.isVertical
                                  ? Icons.grid_view
                                  : Icons.view_list,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            onPressed: () {
                              storeController.setVerticalItems(
                                  !storeController.isVertical);
                            },
                            tooltip: storeController.isVertical
                                ? 'Grid View'
                                : 'List View',
                          ),
                        ]),
                  ),
                  const SizedBox(height: 2),
                  filter(context, storeController),
                ]),
        ),
      );
    });
  }

  Widget filter(BuildContext context, StoreController storeController) {
    return SizedBox(
      height: ResponsiveHelper.isDesktop(context) ? 40 : 28,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            // ⚠️ UI REQUIREMENT: Only "all" button should be visible
            // Do NOT re-add discounts / popular / filter buttons
            StoreFilterButtonWidget(
              buttonText: 'all'.tr,
              onTap: () => storeController.setStoreType('all'),
              isSelected: storeController.storeType == 'all',
            ),
          ],
        ),
      ),
    );
  }
}
