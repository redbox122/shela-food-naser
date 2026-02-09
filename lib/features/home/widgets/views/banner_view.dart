import 'package:carousel_slider/carousel_slider.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
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
  const BannerView({super.key, required this.isFeatured});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(builder: (bannerController) {
      final List<String?>? bannerList = isFeatured ? bannerController.featuredBannerList : bannerController.bannerImageList;
      final List<dynamic>? bannerDataList = isFeatured ? bannerController.featuredBannerDataList : bannerController.bannerDataList;

      return (bannerList != null && bannerList.isEmpty)
          ? const SizedBox()
          : Container(
              width: MediaQuery.of(context).size.width,
              height: GetPlatform.isDesktop ? 500 : MediaQuery.of(context).size.width * 0.45,
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
              child: bannerList != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: CarouselSlider.builder(
                            options: CarouselOptions(
                              autoPlay: true,
                              enlargeCenterPage: true,
                              disableCenter: true,
                              viewportFraction: 0.95,
                              autoPlayInterval: const Duration(seconds: 7),
                              onPageChanged: (index, reason) {
                                bannerController.setCurrentIndex(index, true);
                              },
                            ),
                            itemCount: bannerList.isEmpty ? 1 : bannerList.length,
                            itemBuilder: (context, index, _) {
                              return InkWell(
                                onTap: () async {
                                  if (bannerDataList![index] is Item) {
                                    final Item? item = bannerDataList[index] as Item?;
                                    Get.find<ItemController>().navigateToItemPage(item, context);
                                  } else if (bannerDataList[index] is Store) {
                                    final Store? store = bannerDataList[index] as Store?;
                                    if (isFeatured && Get.find<SplashController>().moduleList != null) {
                                      for (final ModuleModel module in Get.find<SplashController>().moduleList!) {
                                        if (module.id == store!.moduleId) {
                                          Get.find<SplashController>().setModule(module);
                                          break;
                                        }
                                      }
                                    }
                                    Get.toNamed(
                                      RouteHelper.getStoreRoute(id: store!.id, page: isFeatured ? 'module' : 'banner'),
                                      arguments: StoreScreen(store: store, fromModule: isFeatured),
                                    );
                                  } else if (bannerDataList[index] is BasicCampaignModel) {
                                    final BasicCampaignModel campaign = bannerDataList[index] as BasicCampaignModel;
                                    Get.toNamed(RouteHelper.getBasicCampaignRoute(campaign));
                                  } else {
                                    final String url = bannerDataList[index] as String;
                                    if (await canLaunchUrlString(url)) {
                                      await launchUrlString(url, mode: LaunchMode.externalApplication);
                                    } else {
                                      showCustomSnackBar('unable_to_found_url'.tr);
                                    }
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                    child: GetBuilder<SplashController>(builder: (splashController) {
                                      return AspectRatio(
                                        aspectRatio: 2.5, // Fixed aspect ratio to prevent image distortion
                                        child: CustomImage(
                                          image: '${bannerList[index]}',
                                          fit: BoxFit.fitWidth, // Fill width while maintaining aspect ratio
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: bannerController.bannerImageList!.map((bnr) {
                            final int index = bannerController.bannerImageList!.indexOf(bnr);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                height: index == bannerController.currentIndex ? 8 : 5,
                                width: index == bannerController.currentIndex ? 8 : 6,
                                decoration: BoxDecoration(
                                  color: index == bannerController.currentIndex 
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : Shimmer(
                      duration: const Duration(seconds: 2),
                      enabled: bannerList == null,
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                            color: Colors.grey[300],
                          )),
                    ),
            );
    });
  }
}
