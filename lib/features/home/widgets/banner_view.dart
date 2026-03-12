import 'package:carousel_slider/carousel_slider.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BannerView extends StatelessWidget {
  final bool isFeatured;
  final double? aspectRatio;
  final double? verticalPadding;
  final bool forceShow;
  const BannerView(
      {super.key,
      required this.isFeatured,
      this.aspectRatio,
      this.verticalPadding,
      this.forceShow = false});

  List<_BannerEntry> _buildEntries({
    required List<String?>? bannerList,
    required List<dynamic>? bannerDataList,
  }) {
    final List<_BannerEntry> entries = [];
    if (bannerList == null || bannerList.isEmpty) {
      return entries;
    }
    for (int i = 0; i < bannerList.length; i++) {
      final String? image = bannerList[i];
      if (image == null || image.isEmpty) {
        continue;
      }
      final dynamic data =
          bannerDataList != null && i < bannerDataList.length
              ? bannerDataList[i]
              : null;
      if (data == null) {
        entries.add(_BannerEntry(image: image, data: image));
        continue;
      }
      if (data is String && data.isEmpty) {
        continue;
      }
      entries.add(_BannerEntry(image: image, data: data));
    }
    const int maxBannerItems = 3;
    return entries.length > maxBannerItems
        ? entries.sublist(0, maxBannerItems)
        : entries;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(builder: (bannerController) {
      final List<String?>? bannerList = isFeatured
          ? bannerController.featuredBannerList
          : bannerController.bannerImageList;
      final List<dynamic>? bannerDataList = isFeatured
          ? bannerController.featuredBannerDataList
          : bannerController.bannerDataList;
    final List<_BannerEntry> entries = _buildEntries(
      bannerList: bannerList,
      bannerDataList: bannerDataList,
    );
      // ⚡ TASK 1: Kill fake shimmer - bypass if zoneId is cached from Hive
      // If LocationController has cached zoneId, show content immediately (optimistic rendering)
      bool hasCachedZone = false;
      if (Get.isRegistered<LocationController>()) {
        final locationController = Get.find<LocationController>();
        hasCachedZone = locationController.zoneID > 0;
      }

      final bool showShimmer = !hasCachedZone &&
          (entries.isEmpty && bannerController.isLoading);
      final bool showEmpty = entries.isEmpty && !bannerController.isLoading;
      final bool shouldShowPlaceholder = forceShow && showEmpty;

      return showEmpty && !forceShow
          ? const SizedBox.shrink()
          : Container(
              width: MediaQuery.of(context).size.width,
              height: GetPlatform.isDesktop
                  ? 500
                  : MediaQuery.of(context).size.width * (aspectRatio ?? 0.40),
              padding: EdgeInsets.only(
                  top: verticalPadding ?? Dimensions.paddingSizeDefault),
              child: !(showShimmer || shouldShowPlaceholder)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: RepaintBoundary(
                            child: CarouselSlider.builder(
                              options: CarouselOptions(
                                autoPlay: true,
                                enlargeCenterPage: true,
                                disableCenter: true,
                                autoPlayInterval: const Duration(seconds: 7),
                                onPageChanged: (index, reason) {
                                  bannerController.setCurrentIndex(index, true);
                                },
                              ),
                              itemCount: entries.isEmpty ? 1 : entries.length,
                              itemBuilder: (context, index, _) {
                                if (entries.isEmpty || entries.length <= index) {
                                  return const SizedBox.shrink();
                                }
                                final _BannerEntry entry = entries[index];
                                return InkWell(
                                  onTap: () async {
                                    if (entry.data is Item) {
                                      final Item? item =
                                          entry.data as Item?;
                                      Get.find<ItemController>()
                                          .navigateToItemPage(item, context);
                                    } else if (entry.data is Store) {
                                      final Store? store =
                                          entry.data as Store?;
                                      if (isFeatured &&
                                          (AddressHelper.getUserAddressFromSharedPref()!
                                                      .zoneData !=
                                                  null &&
                                              AddressHelper
                                                      .getUserAddressFromSharedPref()!
                                                  .zoneData!
                                                  .isNotEmpty)) {
                                        for (final ModuleModel module
                                            in Get.find<SplashController>()
                                                .moduleList!) {
                                          if (module.id == store!.moduleId) {
                                            Get.find<SplashController>()
                                                .setModule(module);
                                            break;
                                          }
                                        }
                                        final ZoneData zoneData = AddressHelper
                                                .getUserAddressFromSharedPref()!
                                            .zoneData!
                                            .firstWhere((data) =>
                                                data.id == store!.zoneId);

                                        final Modules module = zoneData.modules!
                                            .firstWhere((module) =>
                                                module.id == store!.moduleId);
                                        Get.find<SplashController>().setModule(
                                            ModuleModel(
                                                id: module.id,
                                                moduleName: module.moduleName,
                                                moduleType: module.moduleType,
                                                themeId: module.themeId,
                                                storesCount:
                                                    module.storesCount));
                                      }
                                      Get.toNamed<void>(
                                        RouteHelper.getStoreRoute(
                                            id: store!.id,
                                            page: isFeatured
                                                ? 'module'
                                                : 'banner'),
                                        arguments: StoreScreen(
                                            store: store,
                                            fromModule: isFeatured),
                                      );
                                    } else if (entry.data
                                        is BasicCampaignModel) {
                                      final BasicCampaignModel campaign =
                                          entry.data as BasicCampaignModel;
                                      Get.toNamed<void>(
                                          RouteHelper.getBasicCampaignRoute(
                                              campaign));
                                    } else if (entry.data is String) {
                                      final String url =
                                          entry.data.toString();
                                      if (url.startsWith('module://')) {
                                        final int moduleId = int.tryParse(
                                                url.replaceFirst('module://', '')) ??
                                            0;
                                        final splashController =
                                            Get.find<SplashController>();
                                        if (splashController.moduleList != null) {
                                          final int moduleIndex =
                                              splashController.moduleList!
                                                  .indexWhere(
                                                      (m) => m.id == moduleId);
                                          if (moduleIndex != -1) {
                                            splashController.switchModule(
                                                context, moduleIndex, true);
                                          }
                                        }
                                      } else if (Uri.tryParse(url)?.host.contains('qaydha.com') == true) {
                                        Get.offAllNamed(RouteHelper.getMainRoute('home'));
                                      } else if (await canLaunchUrlString(url)) {
                                        await launchUrlString(url,
                                            mode:
                                                LaunchMode.externalApplication);
                                      } else {
                                        showCustomSnackBar(
                                            'unable_to_found_url'.tr);
                                      }
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      // 🎨 UI IMPROVEMENT: Larger radius for premium look
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                        vertical:
                                            Dimensions.paddingSizeExtraSmall),
                                    child: ClipRRect(
                                      // 🎨 UI IMPROVEMENT: Larger radius for premium look
                                      borderRadius: BorderRadius.circular(20),
                                      child: GetBuilder<SplashController>(
                                          builder: (splashController) {
                                        // 🔧 FIX: Use LayoutBuilder to get finite width and height
                                        // ✅ FIX: Ensure image fills container properly with cover fit
                                        return LayoutBuilder(
                                          builder: (context, constraints) {
                                            return Stack(
                                              children: [
                                                SizedBox(
                                                  width: constraints.maxWidth.isFinite
                                                      ? constraints.maxWidth
                                                      : null,
                                                  height: constraints.maxHeight.isFinite
                                                      ? constraints.maxHeight
                                                      : null,
                                                  child: CustomImage(
                                                    image:
                                                        entry.image,
                                                    fit: BoxFit.cover, // ✅ FIX: Changed from contain to cover to fill the container properly
                                                    width: constraints.maxWidth.isFinite
                                                        ? constraints.maxWidth
                                                        : null,
                                                    height: constraints.maxHeight.isFinite
                                                        ? constraints.maxHeight
                                                        : null,
                                                  ),
                                                ),
                                                // 🎨 UI IMPROVEMENT: Gradient overlay for premium look
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black.withValues(alpha: 0.1),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: entries.map((entry) {
                            final int index = entries.indexOf(entry);
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                height: index == bannerController.currentIndex
                                    ? 8
                                    : 5,
                                width: index == bannerController.currentIndex
                                    ? 8
                                    : 6,
                                decoration: BoxDecoration(
                                  color: index == bannerController.currentIndex
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : Shimmer(
                      duration: const Duration(seconds: 2),
                      enabled: showShimmer || shouldShowPlaceholder,
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusSmall),
                            color: Colors.grey[300],
                          )),
                    ),
            );
    });
  }
}

class _BannerEntry {
  final String image;
  final dynamic data;
  const _BannerEntry({required this.image, required this.data});
}
