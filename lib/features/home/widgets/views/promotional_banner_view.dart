import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PromotionalBannerView extends StatelessWidget {
  const PromotionalBannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(builder: (bannerController) {
      final String? bannerUrl =
          bannerController.promotionalBanner?.bottomSectionBannerFullUrl;
      if (kDebugMode) {
        debugPrint(
            '[PromotionalBannerView] url=${bannerUrl ?? "null"} hasUrl=${(bannerUrl?.isNotEmpty ?? false)}');
      }
      final bool hasBannerUrl = bannerUrl != null && bannerUrl.isNotEmpty;
      if (!hasBannerUrl) {
        return const PromotionalBannerShimmerView();
      }
      return InkWell(
        onTap: () async {
          final link =
              bannerController.promotionalBanner?.bottomSectionBannerLink;
          if (link != null && link.isNotEmpty) {
            if (await canLaunchUrlString(link)) {
              await launchUrlString(link, mode: LaunchMode.externalApplication);
            } else {
              showCustomSnackBar('unable_to_found_url'.tr);
            }
          }
        },
        child: Container(
          height: 90,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeDefault,
            horizontal: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius:
                BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            child: CustomImage(
              image: bannerUrl,
              height: 80,
              width: double.infinity,
            ),
          ),
        ),
      );
    });
  }
}

class PromotionalBannerShimmerView extends StatelessWidget {
  const PromotionalBannerShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Container(
        height: 90,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        ),
      ),
    );
  }
}
