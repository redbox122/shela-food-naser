import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/getText_Length.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/popular_store_view.dart';

class ModuleView extends StatefulWidget {
  final SplashController splashController;
  const ModuleView({super.key, required this.splashController});

  @override
  State<ModuleView> createState() => _ModuleViewState();
}

class _ModuleViewState extends State<ModuleView> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Dimensions.fontSizeLarge),
        Padding(
          padding: EdgeInsets.all(Dimensions.fontSizeSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // For RTL (Arabic): View All on left, Sections on right
              // For LTR (English): Sections on left, View All on right
              if (Get.find<LocalizationController>().isLtr) ...[
                // LTR: Sections first, then View All
                Text(
                  'sections'.tr,
                  style: robotoBold.copyWith(
                    fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeLarge : Dimensions.fontSizeLarge,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to modules page or show all modules
                    // You can add navigation logic here if needed
                  },
                  child: Text(
                    'see_all'.tr,
                    style: robotoBold.copyWith(
                      fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeLarge : Dimensions.fontSizeLarge,
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ] else ...[
                // RTL: View All first, then Sections
                GestureDetector(
                  onTap: () {
                    // Navigate to modules page or show all modules
                    // You can add navigation logic here if needed
                  },
                  child: Text(
                    'see_all'.tr,
                    style: robotoBold.copyWith(
                      fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeLarge : Dimensions.fontSizeLarge,
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  'sections'.tr,
                  style: robotoBold.copyWith(
                    fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeLarge : Dimensions.fontSizeLarge,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: Dimensions.fontSizeLarge),

        widget.splashController.moduleList != null
            ? widget.splashController.moduleList!.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Row(
                      children: List.generate(widget.splashController.moduleList!.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10, left: 3),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });

                              widget.splashController.switchModule(context, index, true);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 13, left: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ⚡ TITAN BOARD: GPU save-layer Purge - Replaced ClipRRect with Container decoration
                                  // ClipRRect forces off-screen save layer (191ms spike). Container uses native GPU texture mapping (0ms).
                                  Container(
                                    height: 110,
                                    width: 110,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    ),
                                    child: ClipOval(
                                      // ClipOval is acceptable for circles (more efficient than ClipRRect)
                                      child: CustomImage(
                                        image: '${widget.splashController.moduleList![index].iconFullUrl}',
                                        height: 110,
                                        width: 110,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: Dimensions.fontSizeSmall),
                                  Text(
                                    widget.splashController.moduleList![index].moduleName!,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeMedim),
                                  ),
                                  SizedBox(height: Dimensions.fontSizeSmall),
                                  Container(
                                    height: 3,
                                    width: getText_Length(
                                          context,
                                          widget.splashController.moduleList![index].moduleName!,
                                          robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                        ) *
                                        1.3,
                                    color: selectedIndex == index ? Theme.of(context).primaryColor : Colors.transparent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      child: Text('no_module_found'.tr),
                    ),
                  )
            : ModuleShimmer(isEnabled: widget.splashController.moduleList == null),

        // Banner =====================

        SizedBox(height: Dimensions.fontSizeLarge),

        GetBuilder<BannerController>(
          builder: (bannerController) {
            return const BannerView(isFeatured: true);
          },
        ),

        //

        // GetBuilder<AddressController>(builder: (locationController) {
        //   List<AddressModel?> addressList = [];
        //   if (AuthHelper.isLoggedIn() && locationController.addressList != null) {
        //     addressList = [];
        //     bool contain = false;
        //     if (AddressHelper.getUserAddressFromSharedPref()!.id != null) {
        //       for (int index = 0; index < locationController.addressList!.length; index++) {
        //         if (locationController.addressList![index].id == AddressHelper.getUserAddressFromSharedPref()!.id) {
        //           contain = true;
        //           break;
        //         }
        //       }
        //     }
        //     if (!contain) {
        //       addressList.add(AddressHelper.getUserAddressFromSharedPref());
        //     }
        //     addressList.addAll(locationController.addressList!);
        //   }
        //   return (!AuthHelper.isLoggedIn() || locationController.addressList != null)
        //       ? addressList.isNotEmpty
        //           ? Column(
        //               children: [
        //                 const SizedBox(height: Dimensions.paddingSizeLarge),
        //                 Padding(
        //                   padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        //                   child: TitleWidget(title: 'deliver_to'.tr),
        //                 ),
        //                 const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        //                 SizedBox(
        //                   height: 80,
        //                   child: ListView.builder(
        //                     physics: const BouncingScrollPhysics(),
        //                     itemCount: addressList.length,
        //                     scrollDirection: Axis.horizontal,
        //                     padding: const EdgeInsets.only(
        //                         left: Dimensions.paddingSizeSmall,
        //                         right: Dimensions.paddingSizeSmall,
        //                         top: Dimensions.paddingSizeExtraSmall),
        //                     itemBuilder: (context, index) {
        //                       return Container(
        //                         width: 300,
        //                         padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        //                         child: AddressWidget(
        //                           address: addressList[index],
        //                           fromAddress: false,
        //                           onTap: () {
        //                             if (AddressHelper.getUserAddressFromSharedPref()!.id != addressList[index]!.id) {
        //                               Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
        //                               Get.find<LocationController>().saveAddressAndNavigate(
        //                                 addressList[index],
        //                                 false,
        //                                 null,
        //                                 false,
        //                                 ResponsiveHelper.isDesktop(context),
        //                               );
        //                             }
        //                           },
        //                         ),
        //                       );
        //                     },
        //                   ),
        //                 ),
        //               ],
        //             )
        //           : const SizedBox()
        //       : AddressShimmer(isEnabled: AuthHelper.isLoggedIn() && locationController.addressList == null);
        // }),

        const PopularStoreView(isPopular: false, isFeatured: true),

        //

        const SizedBox(height: 150),
      ],
    );
  }
}

class ModuleShimmer extends StatelessWidget {
  final bool isEnabled;
  const ModuleShimmer({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: Dimensions.paddingSizeSmall,
        crossAxisSpacing: Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      itemCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: isEnabled,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Colors.grey[300]),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Center(child: Container(height: 15, width: 50, color: Colors.grey[300])),
            ]),
          ),
        );
      },
    );
  }
}

class AddressShimmer extends StatelessWidget {
  final bool isEnabled;
  const AddressShimmer({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          child: TitleWidget(title: 'deliver_to'.tr),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        SizedBox(
          height: 70,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: 5,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                child: Container(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      Icons.location_on,
                      size: ResponsiveHelper.isDesktop(context) ? 50 : 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Shimmer(
                        duration: const Duration(seconds: 2),
                        enabled: isEnabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 15, width: 100, color: Colors.grey[300]),
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              Container(height: 10, width: 150, color: Colors.grey[300]),
                            ]),
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
