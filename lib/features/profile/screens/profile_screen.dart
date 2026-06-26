import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/profile/widgets/notification_status_change_bottom_sheet.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/update/controllers/update_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/profile/widgets/profile_button_widget.dart';
import 'package:sixam_mart/features/profile/widgets/profile_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/widgets/web_profile_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    if (AuthHelper.isLoggedIn() && Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showWalletCard = Get.find<SplashController>().configModel!.customerWalletStatus == 1 ||
        Get.find<SplashController>().configModel!.loyaltyPointStatus == 1;

    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      backgroundColor: Theme.of(context).colorScheme.surface,
      key: UniqueKey(),
      body: SafeArea(
        // Let the green header fill behind the status bar (the title row has its
        // own inner SafeArea to clear the notch) for a taller, cohesive header.
        top: false,
        bottom: true,
        left: false,
        right: false,
        minimum: EdgeInsets.zero,
        child: GetBuilder<ProfileController>(builder: (profileController) {
        final bool isLoggedIn = AuthHelper.isLoggedIn();
        final String? joinedAt = profileController.userInfoModel?.createdAt;
        return (isLoggedIn &&
                profileController.userInfoModel == null &&
                profileController.hasProfileError)
            ? ErrorStateView(
                onRetry: () {
                  profileController.getUserInfo();
                },
              )
            : (isLoggedIn && profileController.userInfoModel == null)
                ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: FooterView(
                  minHeight: isLoggedIn
                      ? ResponsiveHelper.isDesktop(context)
                          ? 0.4
                          : 0.6
                      : 0.35,
                  child: (isLoggedIn && ResponsiveHelper.isDesktop(context))
                      ? const WebProfileWidget()
                      : Container(
                          width: Dimensions.webMaxWidth,
                          height: context.height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Theme.of(context).primaryColor,
                                const Color(0xFF1F7A35),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                                child: SafeArea(
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    !ResponsiveHelper.isDesktop(context)
                                        ? IconButton(
                                            onPressed: () => Get.back(),
                                            icon: const Icon(Icons.arrow_back_ios,
                                                color: Colors.white),
                                          )
                                        : const SizedBox(),
                                    Text('profile'.tr,
                                        style: robotoBold.copyWith(
                                            fontSize: Dimensions.fontSizeLarge,
                                            color: Colors.white)),
                                    const SizedBox(width: 50),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeDefault),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: Dimensions.paddingSizeExtremeLarge,
                                    right: Dimensions.paddingSizeExtremeLarge,
                                    bottom: Dimensions.paddingSizeExtraLarge),
                                child: Row(children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.18),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: ClipOval(
                                    child: Builder(
                                      builder: (context) {
                                        final String? imageUrl =
                                            (profileController.userInfoModel !=
                                                        null &&
                                                    isLoggedIn)
                                                ? profileController
                                                    .userInfoModel!.imageFullUrl
                                                : null;

                                        if (imageUrl == null ||
                                            imageUrl.isEmpty) {
                                          return Container(
                                            height: 70,
                                            width: 70,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .cardColor
                                                  .withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color:
                                                  Theme.of(context).cardColor,
                                              size: 38,
                                            ),
                                          );
                                        }

                                        return CustomImage(
                                          placeholder: Images.guestIcon,
                                          image: imageUrl,
                                          height: 70,
                                          width: 70,
                                        );
                                      },
                                    ),
                                  ),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeDefault),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(
                                        isLoggedIn
                                            ? '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}'
                                            : 'guest_user'.tr,
                                        style: robotoBold.copyWith(
                                            fontSize: Dimensions.fontSizeExtraLarge,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                      isLoggedIn
                                          ? Text(
                                              joinedAt == null
                                                  ? 'joined'.tr
                                                  : '${'joined'.tr} ${DateConverter.containTAndZToUTCFormat(joinedAt)}',
                                              style: robotoMedium.copyWith(
                                                  fontSize: Dimensions.fontSizeSmall,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9)),
                                            )
                                          : InkWell(
                                              onTap: () async {
                                                if (!ResponsiveHelper.isDesktop(context)) {
                                                  await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                                                  if (AuthHelper.isLoggedIn()) {
                                                    profileController.getUserInfo();
                                                  }
                                                } else {
                                                  Get.dialog(
                                                      const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)));
                                                }
                                              },
                                              child: Text(
                                                'login_to_view_all_feature'.tr,
                                                style: robotoMedium.copyWith(
                                                    fontSize: Dimensions.fontSizeSmall,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9)),
                                              ),
                                            ),
                                    ]),
                                  ),
                                  isLoggedIn
                                      ? InkWell(
                                          onTap: () => Get.toNamed(RouteHelper.getUpdateProfileRoute()),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Theme.of(context).cardColor,
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                                      blurRadius: 5,
                                                      spreadRadius: 1,
                                                      offset: const Offset(3, 3))
                                                ]),
                                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                            child: Icon(Icons.edit_outlined,
                                                size: 22,
                                                color: Theme.of(context).primaryColor),
                                          ),
                                        )
                                      : InkWell(
                                          onTap: () async {
                                            if (!ResponsiveHelper.isDesktop(context)) {
                                              await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                                              if (AuthHelper.isLoggedIn()) {
                                                profileController.getUserInfo();
                                              }
                                            } else {
                                              Get.dialog(
                                                  const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)));
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                              color: Colors.white,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                                            child: Text(
                                              'login'.tr,
                                              style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                                            ),
                                          ),
                                        )
                                ]),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
                                      color: Theme.of(context).cardColor),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
                                  child: SingleChildScrollView(child: Column(children: [
                                    const SizedBox(height: Dimensions.paddingSizeLarge),
                                    (showWalletCard && isLoggedIn)
                                        ? Row(children: [
                                            Get.find<SplashController>().configModel!.loyaltyPointStatus == 1
                                                ? Expanded(
                                                    child: ProfileCardWidget(
                                                    image: Images.loyaltyIcon,
                                                    data: profileController.userInfoModel!.loyaltyPoint != null
                                                        ? profileController.userInfoModel!.loyaltyPoint.toString()
                                                        : '0',
                                                    title: 'loyalty_points'.tr,
                                                  ))
                                                : const SizedBox(),
                                            SizedBox(
                                                width: Get.find<SplashController>().configModel!.loyaltyPointStatus == 1
                                                    ? Dimensions.paddingSizeSmall
                                                    : 0),
                                            isLoggedIn
                                                ? Expanded(
                                                    child: ProfileCardWidget(
                                                    image: Images.shoppingBagIcon,
                                                    data: (profileController.userInfoModel!.orderCount ?? 0).toString(),
                                                    title: 'total_order'.tr,
                                                  ))
                                                : const SizedBox(),
                                            SizedBox(
                                                width: Get.find<SplashController>().configModel!.customerWalletStatus == 1
                                                    ? Dimensions.paddingSizeSmall
                                                    : 0),
                                            Get.find<SplashController>().configModel!.customerWalletStatus == 1
                                                ? Expanded(
                                                    child: ProfileCardWidget(
                                                      image: Images.walletProfile,
                                                      data: PriceConverter.convertPrice(
                                                        profileController.userInfoModel!.walletBalance,
                                                      ).toString(),
                                                      title: 'wallet_balance'.tr,
                                                    ),
                                                  )
                                                : const SizedBox(),
                                          ])
                                        : const SizedBox(),
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    // Dark-mode toggle removed per request.
                                    isLoggedIn
                                        ? GetBuilder<AuthController>(builder: (authController) {
                                            return ProfileButtonWidget(
                                              icon: Icons.notifications,
                                              title: 'notification'.tr,
                                              isButtonActive: authController.notification,
                                              onTap: () {
                                                Get.bottomSheet(const NotificationStatusChangeBottomSheet());
                                                // authController.setNotificationActive(!authController.notification);
                                              },
                                            );
                                          })
                                        : const SizedBox(),
                                    SizedBox(height: isLoggedIn ? Dimensions.paddingSizeSmall : 0),
                                    // Restored feature shortcuts from the legacy menu (kept the new design).
                                    if (isLoggedIn) ...[
                                      ProfileButtonWidget(
                                        iconImage: Images.walletIcon,
                                        title: 'my_wallet'.tr,
                                        onTap: () => Get.toNamed(RouteHelper.getWalletRoute()),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        iconImage: Images.KiadaWalletSubscription,
                                        title: 'KiadaWallet_Subscription'.tr,
                                        onTap: () => Get.toNamed(RouteHelper.getKaidhaWallet()),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        iconImage: Images.loyaltyIcon,
                                        title: 'loyalty_points'.tr,
                                        onTap: () => Get.toNamed(RouteHelper.getLoyaltyRoute()),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        iconImage: Images.couponIcon,
                                        title: 'coupon'.tr,
                                        onTap: () => Get.toNamed(RouteHelper.getCouponRoute()),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        iconImage: Images.statistics,
                                        title: 'statistics'.tr,
                                        onTap: () => Get.toNamed(RouteHelper.getStatistics()),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        iconImage: Images.referIcon,
                                        title: 'refer_and_earn'.tr,
                                        onTap: () => Get.toNamed(RouteHelper.getReferAndEarnRoute()),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      // ── المساعدة والدعم ──────────────────────
                                      ProfileButtonWidget(
                                        icon: Icons.chat_bubble_outline,
                                        title: 'live_chat'.tr,
                                        onTap: () => Get.toNamed(
                                            RouteHelper.getConversationRoute()),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        iconImage: Images.helpIcon,
                                        title: 'help_and_support'.tr,
                                        onTap: () => Get.toNamed(RouteHelper.getSupportRoute()),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        icon: Icons.system_update_outlined,
                                        title: 'check_for_updates'.tr,
                                        onTap: () => Get.find<UpdateController>()
                                            .manualCheckForUpdates(),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        icon: Icons.info_outline,
                                        title: 'about_us'.tr,
                                        onTap: () => Get.toNamed(
                                            RouteHelper.getHtmlRoute('about-us')),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        icon: Icons.description_outlined,
                                        title: 'terms_conditions'.tr,
                                        onTap: () => Get.toNamed(RouteHelper
                                            .getHtmlRoute('terms-and-condition')),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        icon: Icons.privacy_tip_outlined,
                                        title: 'privacy_policy'.tr,
                                        onTap: () => Get.toNamed(RouteHelper
                                            .getHtmlRoute('privacy-policy')),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ProfileButtonWidget(
                                        icon: Icons.assignment_return_outlined,
                                        title: 'refund_policy'.tr,
                                        onTap: () => Get.toNamed(RouteHelper
                                            .getHtmlRoute('refund-policy')),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                    ],
                                    isLoggedIn && (Get.find<SplashController>().configModel?.centralizeLoginSetup?.manualLoginStatus ?? false)
                                        ? ProfileButtonWidget(
                                            icon: Icons.lock,
                                            title: 'change_password'.tr,
                                            onTap: () {
                                              Get.toNamed(RouteHelper.getResetPasswordRoute('', '', 'password-change'));
                                            })
                                        : const SizedBox(),
                                    SizedBox(
                                        height: isLoggedIn &&
                                                (Get.find<SplashController>().configModel?.centralizeLoginSetup?.manualLoginStatus ?? false)
                                            ? Dimensions.paddingSizeSmall
                                            : 0),
                                    isLoggedIn
                                        ? ProfileButtonWidget(
                                            icon: Icons.logout,
                                            title: 'logout'.tr,
                                            onTap: () {
                                              Get.dialog(
                                                  ConfirmationDialog(
                                                    icon: Images.support,
                                                    description: 'are_you_sure_to_logout'.tr,
                                                    isLogOut: true,
                                                    onYesPressed: () async {
                                                      profileController.clearUserInfo();
                                                      await Get.find<AuthController>().socialLogout();
                                                      await Get.find<AuthController>().clearSharedData();
                                                      await Get.offAllNamed(RouteHelper.getWelcomeRoute());
                                                    },
                                                  ),
                                                  useSafeArea: false);
                                            },
                                          )
                                        : const SizedBox(),
                                    SizedBox(height: isLoggedIn ? Dimensions.paddingSizeSmall : 0),
                                    isLoggedIn
                                        ? ProfileButtonWidget(
                                            icon: Icons.delete,
                                            title: 'delete_account'.tr,
                                            iconImage: Images.profileDelete,
                                            color: Theme.of(context).colorScheme.error,
                                            onTap: () {
                                              Get.dialog(
                                                  ConfirmationDialog(
                                                    icon: Images.support,
                                                    title: 'are_you_sure_to_delete_account'.tr,
                                                    description: 'it_will_remove_your_all_information'.tr,
                                                    isLogOut: true,
                                                    onYesPressed: () => profileController.deleteUser(
                                                      context,
                                                    ),
                                                  ),
                                                  useSafeArea: false);
                                            },
                                          )
                                        : const SizedBox(),
                                    SizedBox(height: isLoggedIn ? Dimensions.paddingSizeLarge : 0),
                                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Text('${'version'.tr}:', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                      Text(AppConstants.appVersion.toStringAsFixed(2),
                                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
                                    ]),
                                  ])),
                                ),
                              )
                            ]),
                          ),
                        ),
                ),
              );
      }),
      ),
    );
  }
}
