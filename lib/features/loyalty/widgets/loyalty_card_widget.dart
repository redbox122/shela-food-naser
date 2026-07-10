import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/loyalty/widgets/loyalty_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';

// ألوان بطاقة النقاط
const Color _numberColor = Color(0xFF2D2A3E);

class LoyaltyCardWidget extends StatelessWidget {
  final JustTheController tooltipController;
  const LoyaltyCardWidget({super.key, required this.tooltipController});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final String points =
            profileController.userInfoModel!.loyaltyPoint == null
                ? '0'
                : profileController.userInfoModel!.loyaltyPoint.toString();

        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        // Dark: vivid purple card + white content. Light: soft lavender + dark.
        final Color cardBg =
            isDark ? const Color(0xFF7C5CFC) : const Color(0xffEFE6FF);
        final Color cardText = isDark ? Colors.white : const Color(0xff111B18);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== بطاقة النقاط القابلة للتحويل ====
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: cardBg,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // زينة العملات: واحدة أعلى اليمين وواحدة أسفل اليسار
                  PositionedDirectional(
                    end: 0,
                    top: 65,
                    child: Image.asset(
                      Images.point_coin_2,
                      // width: MediaQuery.of(context).size.width * 0.55,
                      fit: BoxFit.contain,
                    ),
                  ),
                  PositionedDirectional(
                    start: 0,
                    bottom: 49,
                    child: Image.asset(
                      Images.point_coin_1,
                      // width: MediaQuery.of(context).size.width * 0.55,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveHelper.isDesktop(context) ? 30 : 24,
                      horizontal: Dimensions.paddingSizeLarge,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'convertible_points'.tr,
                            textAlign: TextAlign.center,
                            style: tajawalBold.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: Dimensions.fontSizeExtraLarge,
                              color: cardText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            points,
                            style: robotoBold.copyWith(
                              fontSize: 34,
                              color: isDark ? Colors.white : _numberColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ResponsiveHelper.isDesktop(context)
                ? const SizedBox(height: Dimensions.paddingSizeDefault)
                : const SizedBox(),
            ResponsiveHelper.isDesktop(context)
                ? Text('how_to_use'.tr,
                    style:
                        robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))
                : const SizedBox(),
            ResponsiveHelper.isDesktop(context)
                ? const SizedBox(height: Dimensions.paddingSizeDefault)
                : const SizedBox(),
            !ResponsiveHelper.isDesktop(context)
                ? const SizedBox()
                : const LoyaltyStepper(),
          ],
        );
      },
    );
  }
}

class LoyaltyStepper extends StatelessWidget {
  const LoyaltyStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                        top: Dimensions.paddingSizeExtraSmall),
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).primaryColor, width: 2)),
                  ),
                  Expanded(
                    child: VerticalDivider(
                      thickness: 3,
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.30),
                    ),
                  ),
                  Container(
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).primaryColor, width: 2)),
                  ),
                ],
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('convert_your_loyalty_point_to_wallet_money'.tr,
                        style: robotoRegular),
                    Text(
                        '${'minimun'.tr} ${Get.find<SplashController>().configModel!.loyaltyPointExchangeRate} ${'points_required_to_convert_into_currency'.tr}',
                        style: robotoRegular),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        CustomButton(
          radius: Dimensions.radiusSmall,
          buttonText: 'convert_to_currency_now'.tr,
          onPressed: () {
            Get.dialog(
              Dialog(
                  backgroundColor: Colors.transparent,
                  child: LoyaltyBottomSheetWidget(
                    amount: Get.find<ProfileController>()
                                .userInfoModel!
                                .loyaltyPoint ==
                            null
                        ? '0'
                        : Get.find<ProfileController>()
                            .userInfoModel!
                            .loyaltyPoint
                            .toString(),
                  )),
            );
          },
        ),
      ],
    );
  }
}
