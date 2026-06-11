// ignore_for_file: non_constant_identifier_names, unnecessary_null_comparison, no_leading_underscores_for_local_identifiers

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/add_delegate/controllers/delegate_controller.dart';
import 'package:sixam_mart/features/auth/controllers/deliveryman_registration_controller.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/features/auth/domain/models/status_model.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/language/widgets/language_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/features/menu/widgets/portion_widget.dart';
import 'package:sixam_mart/features/update/controllers/update_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String _prefsDmBadgeKey = 'profile_dm_badge_suffix_v2';

  Map<String, dynamic>? _deliveryRegistrationResponse;
  bool _deliveryCheckLoading = false;
  String? _persistedDeliveryBadge;

  bool _hasServiceAccess() {
    return AuthHelper.isLoggedIn() &&
        !Get.find<AuthController>().isGuestLoggedIn();
  }

  Future<void> _showLoginRequiredAndRedirect() async {
    final String redirectPage = Get.currentRoute;
    showCustomSnackBar(
      'هذه الخدمة تتطلب تسجيل الدخول. سيتم تحويلك لصفحة تسجيل الدخول.',
      isError: false,
      showDuration: 1,
    );
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) {
      return;
    }
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    await Get.toNamed(RouteHelper.getSignInRoute(redirectPage));
  }

  Future<void> _runWithLoginRequired(VoidCallback onAuthorized) async {
    if (_hasServiceAccess()) {
      onAuthorized();
      return;
    }
    await _showLoginRequiredAndRedirect();
  }

  @override
  void initState() {
    super.initState();
    // ⚡ TASK 3: Check if userInfoModel exists - show UI instantly if data is available
    final profileController = Get.find<ProfileController>();
    if (AuthHelper.isLoggedIn() && profileController.userInfoModel != null) {
      // Data already exists - show UI instantly, refresh balance in background
      if (kDebugMode) {
        debugPrint('⚡ MenuScreen: userInfoModel exists - showing UI instantly');
        debugPrint(
            '   - Name: ${profileController.userInfoModel?.fName} ${profileController.userInfoModel?.lName}');
      }
      // Load data in background to refresh balance only
      loadData(context);
    } else {
      // No data - load it first
      loadData(context);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersistedDmBadge();
    });
  }

  Future<void> _loadPersistedDmBadge() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _persistedDeliveryBadge = prefs.getString(_prefsDmBadgeKey);
    });
  }

  Future<void> _persistDmBadge(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsDmBadgeKey, value);
    _persistedDeliveryBadge = value;
  }

  Future<void> loadData(context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kDebugMode) {
        debugPrint('📋 MenuScreen: loadData() called');
        debugPrint('   - isLoggedIn: ${AuthHelper.isLoggedIn()}');
      }

      // ⚡ TASK 2: Wallet Data Hierarchy - ONLY call getUserInfo() first
      // Then check walletBalance from userInfo before calling wallet API
      if (AuthHelper.isLoggedIn()) {
        final profileController = Get.find<ProfileController>();

        // Step 1: Load user info if not already loaded
        if (profileController.userInfoModel == null) {
          try {
            if (kDebugMode) {
              debugPrint('🔄 MenuScreen: Loading user info...');
            }
            await profileController.getUserInfo();
            if (kDebugMode) {
              debugPrint('✅ MenuScreen: User info loaded successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ MenuScreen: Error loading user info: $e');
            }
          }
        }

        // Step 2: Check Qidha wallet data from userInfo
        // ⚡ TASK 2: Show balance/limit instantly from pre-fetched data, refresh in background
        final qidhaBalance =
            profileController.userInfoModel?.qidhaWalletBalance;
        final hasQidhaWallet =
            profileController.userInfoModel?.hasQidhaWallet ?? false;
        final kaidhaController = Get.find<KaidhaSubscriptionController>();

        if (hasQidhaWallet) {
          // ⚡ TASK 2: Ensure wallet state is set with default creditLimit (5000.0) if not already set
          // This prevents showing '0' if we know the user is a Qidha member
          if (kaidhaController.walletKaidhaModel == null &&
              qidhaBalance != null) {
            if (kDebugMode) {
              debugPrint(
                  '⚡ MenuScreen: Setting wallet state with default creditLimit (5000.0) for instant display');
            }
            kaidhaController.setWalletStateFromLogin(
              signed:
                  profileController.userInfoModel?.qidhaWalletSigned == true,
              active:
                  profileController.userInfoModel?.qidhaWalletActive == true,
              balance: qidhaBalance.toString(),
            );
          } else if (kaidhaController.walletKaidhaModel?.wallet != null) {
            // ⚡ TASK 2: Ensure creditLimit is not null/empty - default to 5000.0 if needed
            final wallet = kaidhaController.walletKaidhaModel!.wallet!;
            final currentCreditLimit = wallet.creditLimit;
            final bool needsDefault = currentCreditLimit == null ||
                (currentCreditLimit is String &&
                    (currentCreditLimit.isEmpty ||
                        currentCreditLimit == '0')) ||
                (currentCreditLimit is num && currentCreditLimit == 0);

            if (needsDefault) {
              wallet.creditLimit = 5000.0;
              kaidhaController.update();
              if (kDebugMode) {
                debugPrint(
                    '⚡ MenuScreen: Defaulted creditLimit to 5000.0 (was null/empty) - preventing "0" display');
              }
            }
          }

          // User has Qidha wallet - fire get-wallet API in background to refresh credit limit
          // Don't await it - show balance/limit instantly, API will update in background
          // ⚡ TASK 2: NEVER show '0' if we know the user is a Qidha member
          kaidhaController.get_Wallet_Kaidh().catchError((e) {
            if (kDebugMode) {
              debugPrint(
                  '❌ MenuScreen: Background wallet API call failed (non-critical): $e');
            }
          });

          if (kDebugMode) {
            debugPrint(
                '⚡ MenuScreen: Fired background wallet API call to refresh credit limit');
            debugPrint('   - Balance from userInfo: ${qidhaBalance ?? 'N/A'}');
            debugPrint(
                '   - Credit limit: ${kaidhaController.walletKaidhaModel?.wallet?.creditLimit ?? '5000.0 (default)'}');
            debugPrint(
                '   - UI shows balance/limit instantly, API refreshes in background');
          }
        } else {
          // No Qidha wallet - check regular wallet balance
          final walletBalance = profileController.userInfoModel?.walletBalance;
          if (walletBalance == null) {
            // Regular wallet balance not in userInfo - need to load from wallet API
            final kaidhaController = Get.find<KaidhaSubscriptionController>();
            if (kaidhaController.walletKaidhaModel == null) {
              try {
                if (kDebugMode) {
                  debugPrint(
                      '🔄 MenuScreen: Wallet balance missing from userInfo - loading from wallet API...');
                }
                await kaidhaController.get_Wallet_Kaidh();
                if (kDebugMode) {
                  debugPrint('✅ MenuScreen: Wallet data loaded from API');
                }
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('❌ MenuScreen: Error loading wallet data: $e');
                }
              }
            } else {
              if (kDebugMode) {
                debugPrint(
                    '⏭️ MenuScreen: Wallet already loaded - skipping API call');
              }
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '⏭️ MenuScreen: Wallet balance found in userInfo ($walletBalance) - skipping wallet API call');
            }
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('ℹ️ MenuScreen: User not logged in - skipping data load');
        }
      }

      if (AuthHelper.isLoggedIn()) {
        debugPrint(
            '🔄 MenuScreen: Loading delegate, deliveryman, and store registration data...');
        Get.find<Delegate_Controller>().get_Delegate();
        await _refreshDeliveryRegistrationStatus();
        Get.find<StoreRegistrationController>().getZoneList();
        debugPrint('✅ MenuScreen: loadData() completed');
      } else {
        debugPrint(
            'ℹ️ MenuScreen: Guest user - skipping delegate/store registration calls');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('[ProfileMenu][DISCOUNT_ITEM_HIDDEN]');
    }
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        top: !ResponsiveHelper.isDesktop(context),
        bottom: false,
        left: false,
        right: false,
        minimum: EdgeInsets.zero,
        child: GetBuilder<ProfileController>(builder: (profileController) {
          final bool isLoggedIn = AuthHelper.isLoggedIn();

          if (isLoggedIn && profileController.userInfoModel == null) {
            if (profileController.hasProfileError) {
              return ErrorStateView(
                onRetry: () {
                  profileController.getUserInfo();
                  loadData(context);
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final splashController = Get.find<SplashController>();
          final config = splashController.configModel;
          final loyaltyPointStatus = config?.loyaltyPointStatus ?? 0;
          final customerWalletStatus = config?.customerWalletStatus ?? 0;
          final refEarningStatus = config?.refEarningStatus ?? 0;
          final refundPolicyStatus = config?.refundPolicyStatus ?? 0;
          final cancellationPolicyStatus =
              config?.cancellationPolicyStatus ?? 0;
          final shippingPolicyStatus = config?.shippingPolicyStatus ?? 0;
          final toggleDmRegistration = config?.toggleDmRegistration ?? false;
          final toggleStoreRegistration =
              config?.toggleStoreRegistration ?? false;

          return GetBuilder<KaidhaSubscriptionController>(
              builder: (KaidhaSubController) {
            // Log menu screen render state

            return ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom +
                    Dimensions.paddingSizeLarge,
              ),
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 130),
                  decoration:
                      BoxDecoration(color: Theme.of(context).primaryColor),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: Dimensions.paddingSizeExtremeLarge,
                      right: Dimensions.paddingSizeExtremeLarge,
                      top: 50,
                      bottom: Dimensions.paddingSizeDefault,
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(1),
                            child: ClipOval(child: Builder(
                              builder: (context) {
                                final String? imageUrl =
                                    (profileController.userInfoModel != null &&
                                            isLoggedIn &&
                                            profileController.userInfoModel!
                                                    .imageFullUrl !=
                                                null &&
                                            profileController.userInfoModel!
                                                .imageFullUrl!.isNotEmpty)
                                        ? profileController
                                            .userInfoModel!.imageFullUrl!
                                        : null;

                                if (imageUrl == null || imageUrl.isEmpty) {
                                  return Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .cardColor
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Theme.of(context).cardColor,
                                      size: 34,
                                    ),
                                  );
                                }

                                return CustomImage(
                                  placeholder: Images.guestIconLight,
                                  image: imageUrl,
                                  height: 60,
                                  width: 60,
                                );
                              },
                            )),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),
                          Expanded(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  isLoggedIn &&
                                          profileController.userInfoModel ==
                                              null
                                      ? Shimmer(
                                          child: Container(
                                            height: 15,
                                            width: 150,
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(context).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          isLoggedIn
                                              ? '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}'
                                              : 'guest_user'.tr,
                                          style: robotoBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeOverLarge,
                                              color: Colors.white),
                                        ),
                                  SizedBox(
                                      height: isLoggedIn &&
                                              profileController.userInfoModel ==
                                                  null
                                          ? Dimensions.paddingSizeSmall
                                          : Dimensions.paddingSizeExtraSmall),
                                  isLoggedIn &&
                                          profileController.userInfoModel ==
                                              null
                                      ? Shimmer(
                                          child: Container(
                                            height: 15,
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(context).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        )
                                      : isLoggedIn
                                          ?

                                          // داخل الـ Widget:
                                          Text(
                                              DateConverter.formatDate(
                                                  DateTime.now()),
                                              style: robotoMedium.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                color:
                                                    Theme.of(context).cardColor,
                                              ),
                                            )
                                          : InkWell(
                                              onTap: () async {
                                                if (!ResponsiveHelper.isDesktop(
                                                    context)) {
                                                  await Get.toNamed(RouteHelper
                                                      .getSignInRoute(
                                                          Get.currentRoute));
                                                  if (AuthHelper.isLoggedIn()) {
                                                    profileController
                                                        .getUserInfo();
                                                  }
                                                } else {
                                                  Get.dialog(const Center(
                                                      child: AuthDialogWidget(
                                                          exitFromApp: true,
                                                          backFromThis: true)));
                                                }
                                              },
                                              child: Text(
                                                'login_to_view_all_feature'.tr,
                                                style: robotoMedium.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    color: Theme.of(context)
                                                        .cardColor),
                                              ),
                                            ),
                                ]),
                          ),

                          // qr  =========================
                          (() {
                            final walletModel =
                                KaidhaSubController.walletKaidhaModel;
                            final wallet = walletModel?.wallet;
                            if (walletModel == null) return const SizedBox();
                            if (wallet != null) return const SizedBox();
                            return InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle),
                                padding: const EdgeInsets.all(1),
                                child: Image.asset(Images.qr,
                                    height: 50, width: 100),
                              ),
                              onTap: () {
                                Get.toNamed(RouteHelper.getQr_screen());
                              },
                            );
                          })(),
                        ]),
                  ),
                ),
                GetBuilder<KaidhaSubscriptionController>(
                    builder: (KaidhaSubController) {
                  return GetBuilder<Delegate_Controller>(
                      builder: (delegate_Controller) {
                    return GetBuilder<DeliverymanRegistrationController>(
                        builder: (DeliverymanReg_Controller) {
                      return Ink(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        padding: const EdgeInsets.only(
                            top: Dimensions.paddingSizeLarge),
                        child: Column(children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: Dimensions.paddingSizeDefault,
                                      right: Dimensions.paddingSizeDefault),
                                  child: Text(
                                    'general'.tr,
                                    style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.5)),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusDefault),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          spreadRadius: 1)
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeLarge,
                                      vertical: Dimensions.paddingSizeDefault),
                                  margin: const EdgeInsets.all(
                                      Dimensions.paddingSizeDefault),
                                  child: Column(children: [
                                    PortionWidget(
                                        icon: Images.profileIcon,
                                        title: 'profile'.tr,
                                        route: RouteHelper.getProfileRoute()),
                                    PortionWidget(
                                        icon: Images.addressIcon,
                                        title: 'my_address'.tr,
                                        route: RouteHelper.getAddressRoute()),
                                    PortionWidget(
                                        icon: Images.languageIcon,
                                        title: 'language'.tr,
                                        hideDivider: true,
                                        onTap: () =>
                                            _manageLanguageFunctionality(),
                                        route: ''),
                                  ]),
                                )
                              ]),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //

                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: Dimensions.paddingSizeDefault,
                                      right: Dimensions.paddingSizeDefault),
                                  child: Text(
                                    'promotional_activity'.tr,
                                    style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.5)),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusDefault),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          spreadRadius: 1)
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeLarge,
                                      vertical: Dimensions.paddingSizeDefault),
                                  margin: const EdgeInsets.all(
                                      Dimensions.paddingSizeDefault),
                                  child: Column(children: [
                                    //

                                    // coupon  --------------------------------------------------------------------------------

                                    PortionWidget(
                                      icon: Images.couponIcon,
                                      title: 'coupon'.tr,
                                      route: RouteHelper.getCouponRoute(),
                                      onTap: () => _runWithLoginRequired(() {
                                        Get.toNamed(
                                            RouteHelper.getCouponRoute());
                                      }),
                                      hideDivider: loyaltyPointStatus == 1 ||
                                              customerWalletStatus == 1
                                          ? false
                                          : true,
                                    ),
                                    // (Get.find<SplashController>().configModel!.refEarningStatus == 1)
                                    (1 == 1)
                                        ? PortionWidget(
                                            icon: Images.statistics,
                                            title: 'statistics'.tr,
                                            route: RouteHelper.getStatistics(),
                                            onTap: () =>
                                                _runWithLoginRequired(() {
                                              Get.toNamed(
                                                  RouteHelper.getStatistics());
                                            }),
                                            hideDivider: (toggleDmRegistration &&
                                                        !ResponsiveHelper
                                                            .isDesktop(
                                                                context)) ||
                                                    (toggleStoreRegistration &&
                                                        !ResponsiveHelper
                                                            .isDesktop(context))
                                                ? false
                                                : true,
                                          )
                                        : const SizedBox(),
                                    if (!isLoggedIn)
                                      PortionWidget(
                                        icon: Images.walletCreditIcon,
                                        title: 'KiadaWallet_Subscription'.tr,
                                        route: '',
                                        onTap: () => _runWithLoginRequired(() {
                                          _launchExternalUrl(
                                              AppConstants.qaydhaWebsiteUrl);
                                        }),
                                        hideDivider: (toggleDmRegistration &&
                                                    !ResponsiveHelper.isDesktop(
                                                        context)) ||
                                                (toggleStoreRegistration &&
                                                    !ResponsiveHelper.isDesktop(
                                                        context))
                                            ? false
                                            : true,
                                      ),

                                    // (Get.find<SplashController>().configModel!.refEarningStatus == 1)
                                    // Debug: Print wallet status for troubleshooting
                                    Builder(
                                      builder: (context) {
                                        try {
                                          // Show KiadaWallet_Subscription if no wallet exists, or wallet exists but not signed/active
                                          // ⚡ FIX: Check signatureStatus as int (1) or bool (true) for compatibility
                                          final walletModel =
                                              KaidhaSubController
                                                  .walletKaidhaModel;
                                          final wallet = walletModel?.wallet;
                                          final signatureStatus =
                                              wallet?.signatureStatus;
                                          final isSigned =
                                              signatureStatus == 1 ||
                                                  signatureStatus == true;
                                          final walletStatus = wallet?.status
                                              ?.toString()
                                              .toLowerCase();
                                          if (!AuthHelper.isGuestLoggedIn() &&
                                              (walletModel == null ||
                                                  wallet == null ||
                                                  !isSigned ||
                                                  walletStatus != 'active')) {
                                            return PortionWidget(
                                              icon: Images
                                                  .KiadaWalletSubscription,
                                              title:
                                                  'KiadaWallet_Subscription'.tr,
                                              route: RouteHelper
                                                  .getKiadaWalletSubscription(),
                                              hideDivider: (toggleDmRegistration &&
                                                          !ResponsiveHelper
                                                              .isDesktop(
                                                                  context)) ||
                                                      (toggleStoreRegistration &&
                                                          !ResponsiveHelper
                                                              .isDesktop(
                                                                  context))
                                                  ? false
                                                  : true,
                                            );
                                          }

                                          // Show Qidha Wallet only if wallet exists, is signed (signature_status = 1 or true) and active
                                          // ⚡ FIX: Check signatureStatus as int (1) or bool (true) for compatibility
                                          final walletSignatureStatus =
                                              wallet?.signatureStatus;
                                          final walletIsSigned =
                                              walletSignatureStatus == 1 ||
                                                  walletSignatureStatus == true;
                                          if (isLoggedIn &&
                                              !AuthHelper.isGuestLoggedIn() &&
                                              wallet != null &&
                                              walletIsSigned &&
                                              walletStatus == 'active') {
                                            return PortionWidget(
                                              icon: Images.walletIcon,
                                              title: 'kiadha_wallet'.tr,
                                              route:
                                                  RouteHelper.getKaidhaWallet(),
                                              hideDivider: (toggleDmRegistration &&
                                                          !ResponsiveHelper
                                                              .isDesktop(
                                                                  context)) ||
                                                      (toggleStoreRegistration &&
                                                          !ResponsiveHelper
                                                              .isDesktop(
                                                                  context))
                                                  ? false
                                                  : true,
                                              suffix:
                                                  PriceConverter.convertPrice(
                                                () {
                                                  final balance =
                                                      wallet.availableBalance;
                                                  if (balance == null) {
                                                    return 0.0;
                                                  }
                                                  if (balance is double) {
                                                    return balance;
                                                  }
                                                  if (balance is int) {
                                                    return balance.toDouble();
                                                  }
                                                  if (balance is String) {
                                                    return double.tryParse(
                                                            balance) ??
                                                        0.0;
                                                  }
                                                  return 0.0;
                                                }(),
                                              ),
                                            );
                                          }

                                          return const SizedBox();
                                        } catch (e) {
                                          // Fallback: show subscription option if there's an error
                                          return PortionWidget(
                                            icon:
                                                Images.KiadaWalletSubscription,
                                            title:
                                                'KiadaWallet_Subscription'.tr,
                                            route: RouteHelper
                                                .getKiadaWalletSubscription(),
                                            hideDivider: (toggleDmRegistration &&
                                                        !ResponsiveHelper
                                                            .isDesktop(
                                                                context)) ||
                                                    (toggleStoreRegistration &&
                                                        !ResponsiveHelper
                                                            .isDesktop(context))
                                                ? false
                                                : true,
                                          );
                                        }
                                      },
                                    ),

                                    (loyaltyPointStatus == 1)
                                        ? PortionWidget(
                                            icon: Images.pointIcon,
                                            title: 'loyalty_points'.tr,
                                            route:
                                                RouteHelper.getLoyaltyRoute(),
                                            hideDivider:
                                                customerWalletStatus == 1
                                                    ? false
                                                    : true,
                                            suffix: !isLoggedIn
                                                ? null
                                                : '${profileController.userInfoModel?.loyaltyPoint != null ? profileController.userInfoModel!.loyaltyPoint.toString() : '0'} ${'points'.tr}',
                                          )
                                        : const SizedBox(),

                                    (customerWalletStatus == 1 &&
                                            !AuthHelper.isGuestLoggedIn())
                                        ? PortionWidget(
                                            icon: Images.walletIcon,
                                            title: 'my_wallet'.tr,
                                            route: RouteHelper.getold_wallet(),
                                            suffix: !isLoggedIn
                                                ? null
                                                : PriceConverter.convertPrice(
                                                    profileController
                                                                .userInfoModel !=
                                                            null
                                                        ? profileController
                                                            .userInfoModel!
                                                            .walletBalance
                                                        : 0),
                                          )
                                        : const SizedBox(),

                                    // Send Funds button - HIDDEN per request (do not display)
                                    // (isLoggedIn &&
                                    //         !AuthHelper.isGuestLoggedIn())
                                    //     ? PortionWidget(
                                    //         icon: Images.sendMoneyIcon,
                                    //         title: 'send_funds'.tr,
                                    //         hideDivider: true,
                                    //         route:
                                    //             RouteHelper.getSendFundsRoute(),
                                    //       )
                                    //     : const SizedBox(),
                                    const SizedBox(),
                                  ]),
                                )
                              ]),
                          (refEarningStatus == 1) ||
                                  (toggleDmRegistration &&
                                      !ResponsiveHelper.isDesktop(context)) ||
                                  (toggleStoreRegistration &&
                                      !ResponsiveHelper.isDesktop(context))
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: Dimensions.paddingSizeDefault,
                                            right:
                                                Dimensions.paddingSizeDefault),
                                        child: Text(
                                          'earnings'.tr,
                                          style: robotoMedium.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.5)),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                              Dimensions.radiusDefault),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 5,
                                                spreadRadius: 1)
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.paddingSizeLarge,
                                            vertical:
                                                Dimensions.paddingSizeDefault),
                                        margin: const EdgeInsets.all(
                                            Dimensions.paddingSizeDefault),
                                        child: Column(children: [
                                          // مشاركه الاصدقاء

                                          // (Get.find<SplashController>().configModel!.refEarningStatus == 1)
                                          //     ?
                                          PortionWidget(
                                            icon: Images.referIcon,
                                            title: 'refer_and_earn'.tr,
                                            route: RouteHelper
                                                .getReferAndEarnRoute(),
                                            onTap: () =>
                                                _runWithLoginRequired(() {
                                              Get.toNamed(RouteHelper
                                                  .getReferAndEarnRoute());
                                            }),
                                            hideDivider: (toggleDmRegistration &&
                                                        !ResponsiveHelper
                                                            .isDesktop(
                                                                context)) ||
                                                    (toggleStoreRegistration &&
                                                        !ResponsiveHelper
                                                            .isDesktop(context))
                                                ? false
                                                : true,
                                          ),
                                          // : const SizedBox(),

                                          // رجل توصيل

                                          PortionWidget(
                                            icon: Images.dmIcon,
                                            title: 'join_as_a_delivery_man'.tr,
                                            route: _getDeliveryRoute(
                                                isLoggedIn,
                                                DeliverymanReg_Controller
                                                    .status_model),
                                            onTap: () =>
                                                _runWithLoginRequired(() {
                                              _handleDeliveryTap(
                                                true,
                                                DeliverymanReg_Controller
                                                    .status_model,
                                              );
                                            }),
                                            suffix: _getDeliverySuffix(
                                                isLoggedIn,
                                                DeliverymanReg_Controller
                                                    .status_model),
                                          ),

                                          // مندوب  delegate -----------------------------------------------------------------------

                                          PortionWidget(
                                            icon: Images.dmIcon,
                                            title: 'delegate'.tr,
                                            route: _getDelegateRoute(isLoggedIn,
                                                delegate_Controller),
                                            onTap: () =>
                                                _runWithLoginRequired(() {
                                              _handleDelegateTap(
                                                delegate_Controller,
                                              );
                                            }),
                                            suffix: _getDelegateSuffix(
                                                isLoggedIn,
                                                delegate_Controller),
                                          ),

                                          // ================================
                                          //

                                          // PortionWidget(
                                          //   icon: Images.shippingPolicy,
                                          //   title: 'QQQQQ QQQQ',
                                          //   route: "",
                                          //   hideDivider: true,
                                          //   onTap: () {
                                          //     //
                                          //   },
                                          // ),

                                          //

                                          (toggleStoreRegistration &&
                                                  !ResponsiveHelper.isDesktop(
                                                      context))
                                              ? PortionWidget(
                                                  icon: Images.storeIcon,
                                                  title: 'open_vendor'.tr,
                                                  hideDivider: true,
                                                  route: RouteHelper
                                                      .getRestaurantRegistrationRoute(),
                                                  onTap: () =>
                                                      _runWithLoginRequired(() {
                                                    Get.toNamed(RouteHelper
                                                        .getRestaurantRegistrationRoute());
                                                  }),
                                                )
                                              : const SizedBox(),
                                        ]),
                                      )
                                    ])
                              : const SizedBox(),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: Dimensions.paddingSizeDefault,
                                      right: Dimensions.paddingSizeDefault),
                                  child: Text(
                                    'help_and_support'.tr,
                                    style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.5)),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusDefault),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          spreadRadius: 1)
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeLarge,
                                      vertical: Dimensions.paddingSizeDefault),
                                  margin: const EdgeInsets.all(
                                      Dimensions.paddingSizeDefault),
                                  child: Column(children: [
                                    PortionWidget(
                                        icon: Images.chatIcon,
                                        title: 'live_chat'.tr,
                                        route:
                                            RouteHelper.getConversationRoute(),
                                        onTap: () => _runWithLoginRequired(() {
                                              Get.toNamed(RouteHelper
                                                  .getConversationRoute());
                                            })),
                                    PortionWidget(
                                        icon: Images.helpIcon,
                                        title: 'help_and_support'.tr,
                                        route: RouteHelper.getSupportRoute(),
                                        onTap: () => Get.toNamed(
                                            RouteHelper.getSupportRoute())),
                                    PortionWidget(
                                        icon: Images.helpIcon,
                                        title: 'check_for_updates'.tr,
                                        onTap: () =>
                                            Get.find<UpdateController>()
                                                .manualCheckForUpdates(),
                                        route: ''),
                                    PortionWidget(
                                        icon: Images.aboutIcon,
                                        title: 'about_us'.tr,
                                        route: RouteHelper.getHtmlRoute(
                                            'about-us')),
                                    PortionWidget(
                                        icon: Images.termsIcon,
                                        title: 'terms_conditions'.tr,
                                        route: RouteHelper.getHtmlRoute(
                                            'terms-and-condition')),
                                    PortionWidget(
                                        icon: Images.privacyIcon,
                                        title: 'privacy_policy'.tr,
                                        route: RouteHelper.getHtmlRoute(
                                            'privacy-policy')),
                                    (refundPolicyStatus == 1)
                                        ? PortionWidget(
                                            icon: Images.refundIcon,
                                            title: 'refund_policy'.tr,
                                            route: RouteHelper.getHtmlRoute(
                                                'refund-policy'),
                                          )
                                        : const SizedBox(),

                                    (cancellationPolicyStatus == 1)
                                        ? PortionWidget(
                                            icon: Images.cancelationIcon,
                                            title: 'cancellation_policy'.tr,
                                            route: RouteHelper.getHtmlRoute(
                                                'cancellation-policy'),
                                            hideDivider:
                                                (shippingPolicyStatus == 1)
                                                    ? false
                                                    : true,
                                          )
                                        : const SizedBox(),

                                    (shippingPolicyStatus == 1)
                                        ? PortionWidget(
                                            icon: Images.shippingIcon,
                                            title: 'shipping_policy'.tr,
                                            route: RouteHelper.getHtmlRoute(
                                                'shipping-policy'),
                                          )
                                        : const SizedBox(),

                                    //
                                  ]),
                                )
                              ]),
                          InkWell(
                            onTap: () async {
                              if (AuthHelper.isLoggedIn()) {
                                Get.dialog(
                                    ConfirmationDialog(
                                        icon: Images.support,
                                        description:
                                            'are_you_sure_to_logout'.tr,
                                        isLogOut: true,
                                        onYesPressed: () async {
                                          // E-commerce data is completely independent of user authentication
                                          // No need to invalidate anything - cache persists across login/logout

                                          Get.find<ProfileController>()
                                              .clearUserInfo();

                                          await Get.find<AuthController>()
                                              .socialLogout();

                                          await Get.find<CartController>()
                                              .clearCartList(
                                                  canRemoveOnline: false);

                                          Get.find<FavouriteController>()
                                              .removeFavourite();

                                          await Get.find<AuthController>()
                                              .clearSharedData();

                                          Get.find<HomeController>()
                                              .forcefullyNullCashBackOffers();

                                          await Get.find<TaxiCartController>()
                                              .getCarCartList();

                                          // E-commerce cache remains valid after logout
                                          // Ensure data is loaded before navigation
                                          await _ensureDataLoadedBeforeNavigation();

                                          // Passwordless flow: after logout land
                                          // on the Welcome entry screen.
                                          await Get.offAllNamed(
                                              RouteHelper.getWelcomeRoute());
                                        }),
                                    useSafeArea: false);
                              } else {
                                Get.find<FavouriteController>()
                                    .removeFavourite();

                                await Get.toNamed(RouteHelper.getSignInRoute(
                                    Get.currentRoute));

                                if (AuthHelper.isLoggedIn()) {
                                  await Get.find<FavouriteController>()
                                      .getFavouriteList();
                                  profileController.getUserInfo();
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeSmall),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red),
                                      child: Icon(
                                          Icons.power_settings_new_sharp,
                                          size: 18,
                                          color: Theme.of(context).cardColor),
                                    ),
                                    const SizedBox(
                                        width:
                                            Dimensions.paddingSizeExtraSmall),
                                    Text(
                                        AuthHelper.isLoggedIn()
                                            ? 'logout'.tr
                                            : 'sign_in'.tr,
                                        style: robotoMedium.copyWith(
                                            fontSize: Dimensions.fontSizeLarge))
                                  ]),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ]),
                      );
                    });
                  });
                }),
              ],
            );
          });
        }),
      ),
    );
  }

  Future<void> _refreshDeliveryRegistrationStatus() async {
    final ProfileController profileController = Get.find<ProfileController>();
    final DeliverymanRegistrationController deliveryController =
        Get.find<DeliverymanRegistrationController>();
    final String? phone = profileController.userInfoModel?.phone?.trim();
    final String? email = profileController.userInfoModel?.email?.trim();
    if (kDebugMode) {
      debugPrint(
          '[PROFILE_STATUS][DELIVERY_CHECK_START] phone=${phone ?? ''}');
    }
    setState(() {
      _deliveryCheckLoading = true;
    });
    Map<String, dynamic>? response;
    try {
      response = await deliveryController.fetchDeliveryRegistrationForProfile(
        phone: (phone == null || phone.isEmpty) ? null : phone,
        email: (email == null || email.isEmpty) ? null : email,
      );
      if (kDebugMode) {
        final Map<String, dynamic>? deliveryMan =
            response?['delivery_man'] is Map<String, dynamic>
                ? response!['delivery_man'] as Map<String, dynamic>
                : null;
        debugPrint(
            '[PROFILE_STATUS][DELIVERY_RESPONSE] is_registered=${response?['is_registered']} can_register=${response?['can_register']} application_status=${deliveryMan?['application_status']} status=${deliveryMan?['status']} active=${deliveryMan?['active']}');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _deliveryRegistrationResponse = response;
      });
    } finally {
      if (mounted) {
        setState(() {
          _deliveryCheckLoading = false;
        });
      }
    }
    if (!mounted) {
      return;
    }
    final String badge =
        _getDeliverySuffix(true, deliveryController.status_model);
    await _persistDmBadge(badge);
    if (kDebugMode) {
      debugPrint('[PROFILE_STATUS][DELIVERY_FINAL_BADGE] badge=$badge');
    }
  }

  String _getDeliveryRoute(bool isLoggedIn, StatusModel? model) {
    if (!isLoggedIn) {
      return '';
    }
    final Map<String, dynamic>? response = _deliveryRegistrationResponse;
    if (response == null) {
      // Fallback to legacy behavior when check-registration payload is unavailable.
      if (model == null) {
        return RouteHelper.getDeliverymanRegistrationRoute();
      }
      final String legacyStatus = (model.status ?? '').toLowerCase();
      if (legacyStatus == 'pending' || legacyStatus == 'rejected') {
        return '';
      }
      return RouteHelper.getDeliverymanRegistrationRoute();
    }
    final bool isRegistered = response['is_registered'] == true;
    final bool canRegister = response['can_register'] == true;
    final String applicationStatus = _getDeliveryApplicationStatus(response);
    if (!isRegistered && canRegister) {
      return RouteHelper.getDeliverymanRegistrationRoute();
    }
    if (applicationStatus == 'rejected') {
      return RouteHelper.getDeliverymanRegistrationRoute();
    }
    return '';
  }

  String _getDeliverySuffix(bool isLoggedIn, StatusModel? model) {
    if (!isLoggedIn) return '';
    final Map<String, dynamic>? response = _deliveryRegistrationResponse;
    if (response == null &&
        (_deliveryCheckLoading ||
            (model == null &&
                _persistedDeliveryBadge != null &&
                _persistedDeliveryBadge!.isNotEmpty))) {
      if (kDebugMode && _deliveryCheckLoading) {
        debugPrint('[PROFILE_STATUS][DELIVERY_LOADING_KEEP_PREVIOUS]');
      }
      return _persistedDeliveryBadge ?? '';
    }
    String badge = 'انضم الآن';
    if (response == null) {
      final String legacyStatus = (model?.status ?? '').toLowerCase();
      if (legacyStatus == 'active' || legacyStatus == 'approved') {
        badge = 'متاح';
      } else if (legacyStatus == 'rejected') {
        badge = 'مرفوض';
      } else if (legacyStatus == 'pending') {
        badge = 'قيد المراجعة';
      }
      return badge;
    }
    final bool isRegistered = response['is_registered'] == true;
    final bool canRegister = response['can_register'] == true;
    final String applicationStatus = _getDeliveryApplicationStatus(response);
    if (!isRegistered && canRegister) {
      badge = 'انضم الآن';
    } else if (applicationStatus == 'pending') {
      badge = 'قيد المراجعة';
    } else if (applicationStatus == 'approved') {
      badge = 'متاح';
    } else if (applicationStatus == 'rejected') {
      badge = 'مرفوض';
    } else if (isRegistered) {
      badge = 'متاح';
    }
    return badge;
  }

  String _getDeliveryApplicationStatus(Map<String, dynamic> response) {
    final Map<String, dynamic>? deliveryMan = response['delivery_man'] is Map<String, dynamic>
        ? response['delivery_man'] as Map<String, dynamic>
        : null;
    final String applicationStatus =
        (deliveryMan?['application_status'] ?? '').toString().toLowerCase();
    if (applicationStatus.isNotEmpty) {
      return applicationStatus;
    }
    final String statusRaw = (deliveryMan?['status'] ?? '').toString().toLowerCase();
    final String activeRaw = (deliveryMan?['active'] ?? '').toString().toLowerCase();
    if (statusRaw == '1' || statusRaw == 'active' || activeRaw == '1' || activeRaw == 'true') {
      return 'approved';
    }
    return statusRaw;
  }

  Future<void> _handleDeliveryTap(bool isLoggedIn, StatusModel? model) async {
    if (!isLoggedIn) {
      return;
    }
    final Map<String, dynamic>? response = _deliveryRegistrationResponse;
    final String applicationStatus = response == null
        ? (model?.status ?? '').toLowerCase()
        : _getDeliveryApplicationStatus(response);
    debugPrint('[PROFILE_STATUS][TAP] item=delivery status=$applicationStatus');
    final bool isRegistered = response?['is_registered'] == true;
    final bool canRegister = response?['can_register'] == true;
    if (response == null && model == null) {
      debugPrint(
          '[PROFILE_STATUS][ROUTE] item=delivery route=deliveryman_registration');
      Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute());
      return;
    }
    if (!isRegistered && canRegister) {
      debugPrint(
          '[PROFILE_STATUS][ROUTE] item=delivery route=deliveryman_registration');
      Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute());
      return;
    }
    if (applicationStatus == 'pending') {
      debugPrint(
          '[PROFILE_STATUS][POPUP] item=delivery message=pending_review');
      await Get.dialog<void>(
        AlertDialog(
          content: const Text(
              'طلبك قيد المراجعة حاليًا، يرجى انتظار رد الإدارة.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      return;
    }
    if (applicationStatus == 'approved' || applicationStatus == 'active') {
      debugPrint(
          '[PROFILE_STATUS][POPUP] item=delivery message=approved');
      await Get.dialog<void>(
        AlertDialog(
          title: const Text('تمت الموافقة على طلبك'),
          content: const Text('تم قبول طلبك كرجل توصيل.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      return;
    }
    if (applicationStatus == 'rejected') {
      debugPrint(
          '[PROFILE_STATUS][POPUP] item=delivery message=rejected');
      showCustomSnackBar('تم رفض طلبك، يمكنك إعادة التقديم.', isError: false);
      debugPrint(
          '[PROFILE_STATUS][ROUTE] item=delivery route=deliveryman_registration');
      Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute());
      return;
    }
    final String route = _getDeliveryRoute(isLoggedIn, model);
    if (route.isNotEmpty) {
      debugPrint('[PROFILE_STATUS][ROUTE] item=delivery route=$route');
      Get.toNamed(route);
    }
  }

  // Delegate  ==============================================================================================

  String _getDelegateRoute(bool isLoggedIn, Delegate_Controller controller) {
    if (!isLoggedIn || controller.isLoading) return '';

    final model = controller.delegate_model;
    if (model == null) return RouteHelper.getAdd_DelegateScreen();

    switch (model.delegateStatus) {
      case 'pending':
      case 'active':
      case 'rejected':
        return ''; // لا يمكن تعديل الطلب في هذه الحالات
      default:
        return '';
    }
  }

  String _getDelegateSuffix(bool isLoggedIn, Delegate_Controller controller) {
    if (!isLoggedIn) return '';
    if (controller.isLoading) return 'الحالة';

    final model = controller.delegate_model;
    if (model == null) return 'قدّم طلب';

    switch (model.delegateStatus) {
      case 'pending':
        return 'قيد المراجعة';
      case 'active':
        return 'متاح';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'الحالة';
    }
  }

  Future<void> _handleDelegateTap(Delegate_Controller controller) async {
    final String? status = controller.delegate_model?.delegateStatus;
    debugPrint('[PROFILE_STATUS][TAP] item=delegate status=$status');
    if (status == 'pending') {
      debugPrint(
          '[PROFILE_STATUS][BLOCKED] item=delegate reason=pending_review');
      debugPrint(
          '[PROFILE_STATUS][POPUP] item=delegate message=pending_review');
      await Get.dialog<void>(
        AlertDialog(
          title: const Text('طلبك قيد المراجعة'),
          content: const Text(
            'طلب الانضمام كمندوب تسويق قسائم شرائية قيد المراجعة حاليًا، يرجى انتظار رد الإدارة.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      return;
    }
    if (status == 'active' || status == 'approved') {
      showCustomSnackBar('تمت الموافقة على طلبك', isError: false);
      return;
    }
    final String route = RouteHelper.getAdd_DelegateScreen();
    debugPrint('[PROFILE_STATUS][ROUTE] item=delegate route=add_delegate_screen');
    Get.toNamed(route);
  }
  Future<void> _launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $uri';
    }
  }

  Future<void> _manageLanguageFunctionality() async {
    Get.find<LocalizationController>().saveCacheLanguage(null);
    Get.find<LocalizationController>().searchSelectedLanguage();

    final BuildContext buildContext = context;
    await showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radiusExtraLarge),
            topRight: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: const LanguageBottomSheetWidget(),
        );
      },
    );
    if (!buildContext.mounted) {
      return;
    }
    Get.find<LocalizationController>().setLanguage(
      buildContext,
      Get.find<LocalizationController>().getCacheLocaleFromSharedPref(),
    );
  }

  /// Ensure data is loaded before navigation after logout
  Future<void> _ensureDataLoadedBeforeNavigation() async {
    try {
      debugPrint('🔄 MenuScreen: Ensuring data is loaded before navigation...');

      // Check if cache is valid and restore data
      if (await ComprehensiveHomeCacheManager.isCacheValid()) {
        debugPrint('📦 MenuScreen: Cache is valid, restoring data...');

        // Load cached data
        final cachedData =
            await ComprehensiveHomeCacheManager.loadAllHomeData();

        if (cachedData.isNotEmpty) {
          // Restore data to controllers
          await ComprehensiveHomeCacheManager.restoreDataToControllers(
              cachedData);
          debugPrint('✅ MenuScreen: Data restored successfully');
        }
      } else {
        debugPrint(
            '⚠️ MenuScreen: Cache not valid, will load from API after navigation');
      }
    } catch (e) {
      debugPrint('❌ MenuScreen: Error ensuring data loaded - $e');
    }
  }
}
