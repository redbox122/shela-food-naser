import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

class TopRestaurantsViewWidget extends StatelessWidget {
  const TopRestaurantsViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Store>? storeList = storeController.popularStoreList ??
          storeController.storeModel?.stores;

      return storeList != null
          ? storeList.isNotEmpty
              ? Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault),
                    child: Obx(() {
                      final splashController = Get.find<SplashController>();
                      final moduleId =
                          splashController.selectedModule.value?.id ??
                              splashController.module?.id;
                      final moduleName =
                          (splashController.selectedModule.value?.moduleName ??
                                  splashController.module?.moduleName ??
                                  '')
                              .trim();
                      final titleText = moduleId == 9
                          ? 'المقاهي'
                          : (moduleName.isNotEmpty
                              ? moduleName
                              : 'restaurants'.tr);
                      return TitleWidget(
                        title: titleText,
                        onTap: () => Get.toNamed<void>(
                            RouteHelper.getAllStoreRoute('all')),
                      );
                    }),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 13,
                      mainAxisSpacing: 13,
                    ),
                    itemCount: storeList.length > 7 ? 7 : storeList.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(
                            Dimensions.paddingSizeExtraSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .disabledColor
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: InkWell(
                          onTap: () => Get.toNamed<void>(
                              RouteHelper.getStoreRoute(
                                  id: storeList[index].id, page: 'item'),
                              arguments: StoreScreen(
                                  store: storeList[index], fromModule: false)),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusDefault),
                            child: CustomImage(
                              image: '${storeList[index].logoFullUrl}',
                              height: 60,
                              width: 60,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ])
              : const SizedBox()
          : const TopRestaurantsShimmer();
    });
  }
}

class TopRestaurantsShimmer extends StatelessWidget {
  const TopRestaurantsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // Fixed height to prevent vertical overflow
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: Obx(() {
              final splashController = Get.find<SplashController>();
              final moduleId = splashController.selectedModule.value?.id ??
                  splashController.module?.id;
              final moduleName =
                  (splashController.selectedModule.value?.moduleName ??
                          splashController.module?.moduleName ??
                          '')
                      .trim();
              final titleText = moduleId == 9
                  ? 'المقاهي'
                  : (moduleName.isNotEmpty ? moduleName : 'restaurants'.tr);
              return TitleWidget(
                title: titleText,
                onTap: () => null,
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeExtraSmall,
                Dimensions.paddingSizeDefault,
                0),
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
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return Container(
                  padding:
                      const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).disabledColor.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .disabledColor
                          .withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                    ),
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
