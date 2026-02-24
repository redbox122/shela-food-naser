import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sixam_mart/features/refer_and_earn/widgets/bottom_sheet_view_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  GlobalKey<ExpandableBottomSheetState> key = GlobalKey();

  @override
  void initState() {
    super.initState();

    _initCall();
  }

  void _initCall() {
    if (!AuthHelper.isLoggedIn()) {
      return;
    }
    final profileController = Get.find<ProfileController>();
    final String currentRefCode =
        profileController.userInfoModel?.refCode?.trim() ?? '';
    if (profileController.userInfoModel == null || currentRefCode.isEmpty) {
      profileController.getUserInfo();
    }
  }

  String _resolveStoreLink() {
    final config = Get.find<SplashController>().configModel;
    final List<String?> candidates = <String?>[
      GetPlatform.isAndroid ? config?.appUrlAndroid : config?.appUrlIos,
      GetPlatform.isAndroid
          ? config?.landingPageLinks?.appUrlAndroid
          : config?.landingPageLinks?.appUrlIos,
      config?.appUrlAndroid,
      config?.appUrlIos,
      config?.landingPageLinks?.appUrlAndroid,
      config?.landingPageLinks?.appUrlIos,
    ];

    for (final link in candidates) {
      final String value = (link ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    return Scaffold(
      appBar: CustomAppBar(title: 'refer_and_earn'.tr),
      body: ExpandableBottomSheet(
        background: isLoggedIn
            ? SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeLarge),
                child: Column(
                  children: [
                    WebScreenTitleWidget(title: 'refer_and_earn'.tr),
                    FooterView(
                      child: Center(
                        child: SizedBox(
                          width: Dimensions.webMaxWidth,
                          child: GetBuilder<ProfileController>(builder: (profileController) {
                            final String referralCode =
                                profileController.userInfoModel?.refCode
                                        ?.trim() ??
                                    '';
                            final String storeLink = _resolveStoreLink();
                            return Column(children: [
                              Image.asset(
                                Images.referImage,
                                width: 500,
                                height: ResponsiveHelper.isDesktop(context) ? 250 : 150,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox()
                                  : Text('earn_money_on_every_referral'.tr,
                                      style: robotoRegular.copyWith(
                                          color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox()
                                  : const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox()
                                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Text(
                                        '${'one_referral'.tr}= ',
                                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                      ),
                                      PriceConverter.convertPrice2(
                                        Get.find<SplashController>().configModel != null
                                            ? Get.find<SplashController>().configModel!.refEarningExchangeRate!.toDouble()
                                            : 0.0,
                                        textStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                      )
                                    ]),
                              ResponsiveHelper.isDesktop(context) ? const SizedBox() : const SizedBox(height: 40),
                              Text('invite_friends_and_business'.tr,
                                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge), textAlign: TextAlign.center),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              ResponsiveHelper.isDesktop(context)
                                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Text(
                                        '${'one_referral'.tr}= ',
                                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                      ),
                                      PriceConverter.convertPrice2(
                                        Get.find<SplashController>().configModel != null
                                            ? Get.find<SplashController>().configModel!.refEarningExchangeRate!.toDouble()
                                            : 0.0,
                                        textStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                      )
                                    ])
                                  : const SizedBox(),
                              ResponsiveHelper.isDesktop(context) ? const SizedBox(height: 40) : const SizedBox(),
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox()
                                  : Text('copy_your_code_share_it_with_your_friends'.tr,
                                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center),
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox()
                                  : const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                              ResponsiveHelper.isDesktop(context)
                                  ? Align(
                                      alignment: Alignment.topLeft,
                                      child: Text('your_personal_code'.tr,
                                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                          textAlign: TextAlign.center),
                                    )
                                  : const SizedBox(),
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox()
                                  : Text('your_personal_code'.tr,
                                      style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                                      textAlign: TextAlign.center),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              DottedBorder(
                                color: Theme.of(context).primaryColor,
                                dashPattern: const [8, 5],
                                padding: const EdgeInsets.all(0),
                                borderType: BorderType.RRect,
                                radius: Radius.circular(ResponsiveHelper.isDesktop(context) ? Dimensions.radiusDefault : 50),
                                child: SizedBox(
                                  height: 50,
                                  child: (profileController.userInfoModel != null)
                                      ? Row(children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeLarge),
                                              child: Text(
                                                referralCode.isNotEmpty
                                                    ? referralCode
                                                    : '--',
                                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              if (referralCode.isNotEmpty) {
                                                Clipboard.setData(
                                                    ClipboardData(
                                                        text: referralCode));
                                                showCustomSnackBar('referral_code_copied'.tr, isError: false);
                                              } else {
                                                profileController.getUserInfo();
                                                showCustomSnackBar('Referral code is not available yet');
                                              }
                                            },
                                            child: Container(
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  color: Theme.of(context).primaryColor,
                                                  borderRadius: BorderRadius.circular(
                                                      ResponsiveHelper.isDesktop(context) ? Dimensions.radiusDefault : 50)),
                                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
                                              margin: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                              child: Text('copy'.tr,
                                                  style: robotoMedium.copyWith(
                                                      color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeDefault)),
                                            ),
                                          ),
                                        ])
                                      : const CircularProgressIndicator(),
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeLarge),
                              Wrap(children: [
                                InkWell(
                                  onTap: () {
                                    if (referralCode.isEmpty) {
                                      profileController.getUserInfo();
                                      showCustomSnackBar(
                                          'Referral code is not available yet');
                                      return;
                                    }
                                    final String shareText = storeLink.isNotEmpty
                                        ? '${AppConstants.appName} ${'referral_code'.tr}: $referralCode \n${'download_app_from_this_link'.tr}: $storeLink'
                                        : '${AppConstants.appName} ${'referral_code'.tr}: $referralCode';
                                    Share.share(shareText);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).cardColor,
                                      boxShadow: [
                                        BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), blurRadius: 5)
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(7),
                                    child: const Icon(Icons.share),
                                  ),
                                )
                              ]),
                              ResponsiveHelper.isDesktop(context)
                                  ? const Padding(
                                      padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraLarge),
                                      child: BottomSheetViewWidget(),
                                    )
                                  : const SizedBox(),
                            ]);
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : NotLoggedInScreen(callBack: (value) {
                _initCall();
                setState(() {});
              }),
        key: key,
        persistentHeader: ResponsiveHelper.isDesktop(context)
            ? null
            : InkWell(
                onTap: () {
                  if (key.currentState?.expansionStatus == ExpansionStatus.expanded) {
                    setState(() {
                      key.currentState!.contract();
                    });
                  } else {
                    setState(() {
                      key.currentState!.expand();
                    });
                  }
                },
                child: Container(
                  constraints: const BoxConstraints.expand(height: 60),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(Dimensions.paddingSizeExtraLarge),
                        topRight: Radius.circular(Dimensions.paddingSizeExtraLarge)),
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    border: Border(
                      top: BorderSide(color: Theme.of(context).primaryColor, width: 0.3),
                    ),
                  ),
                  child: Column(children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                        height: 3,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeDefault),
                      child: Row(children: [
                        const Icon(Icons.error_outline, size: 16),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text('how_it_works'.tr,
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault), textAlign: TextAlign.center),
                      ]),
                    ),
                  ]),
                ),
              ),
        expandableContent: ResponsiveHelper.isDesktop(context) || !isLoggedIn ? const SizedBox() : const BottomSheetViewWidget(),
      ),
    );
  }
}
