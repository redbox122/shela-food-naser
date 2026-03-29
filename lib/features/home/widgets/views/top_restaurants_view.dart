import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/circular_ring_avatar.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

class TopRestaurantsViewWidget extends StatelessWidget {
  static const double _storeLogoDiameter = 72;
  /// Two rows × three columns (6 stores).
  static const int _maxStoresOnHome = 6;

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
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 96,
                    ),
                    itemCount: storeList.length > _maxStoresOnHome
                        ? _maxStoresOnHome
                        : storeList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Store store = storeList[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Get.toNamed<void>(
                            RouteHelper.getStoreRoute(
                              id: store.id,
                              page: 'item',
                            ),
                            arguments: StoreScreen(
                              store: store,
                              fromModule: false,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(999),
                          child: Center(
                            child: CircularRingAvatar(
                              imageUrl: store.logoFullUrl ?? '',
                              diameter:
                                  TopRestaurantsViewWidget._storeLogoDiameter,
                              fit: BoxFit.contain,
                              imageBackgroundColor:
                                  Theme.of(context).colorScheme.surface,
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
      height: 300,
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
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 96,
              ),
              itemCount: TopRestaurantsViewWidget._maxStoresOnHome,
              itemBuilder: (BuildContext context, int index) {
                return Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .disabledColor
                            .withValues(alpha: 0.1),
                        border: Border.all(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: ColoredBox(
                          color: Theme.of(context)
                              .disabledColor
                              .withValues(alpha: 0.08),
                        ),
                      ),
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
