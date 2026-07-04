// ignore_for_file: non_constant_identifier_names, unnecessary_null_comparison, no_leading_underscores_for_local_identifiers

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/add_delegate/controllers/delegate_controller.dart';
import 'package:sixam_mart/features/auth/controllers/deliveryman_registration_controller.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/features/auth/domain/models/status_model.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/menu/widgets/profile_menu_widgets.dart';
import 'package:sixam_mart/features/profile/screens/language_select_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/responsive_size.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/features/update/controllers/update_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String _prefsDmBadgeKey = 'profile_dm_badge_suffix_v2';
  static const Color _iconColor = Color(0xFF555555);

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
      'pf_service_requires_login'.tr,
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
    return Scaffold(
      backgroundColor: ProfileMenuStyle.cardColor,
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

          final config = Get.find<SplashController>().configModel;
          final int loyaltyPointStatus = config?.loyaltyPointStatus ?? 0;
          final int customerWalletStatus = config?.customerWalletStatus ?? 0;
          final int cancellationPolicyStatus =
              config?.cancellationPolicyStatus ?? 0;
          final int shippingPolicyStatus = config?.shippingPolicyStatus ?? 0;
          final bool toggleStoreRegistration =
              config?.toggleStoreRegistration ?? false;
          final bool showStore =
              toggleStoreRegistration && !ResponsiveHelper.isDesktop(context);

          return GetBuilder<KaidhaSubscriptionController>(builder: (kaidha) {
            return GetBuilder<Delegate_Controller>(
                builder: (delegateController) {
              return GetBuilder<DeliverymanRegistrationController>(
                  builder: (dmController) {
                // ─── النشاط الترويجي والأرباح ───
                final List<Widget> promoRows = <Widget>[
                  ProfileMenuRow(
                    icon: _sectionImage(Images.couboun_icon),
                    title: 'pf_coupons'.tr,
                    onTap: () => _runWithLoginRequired(
                        () => Get.toNamed(RouteHelper.getCouponRoute())),
                  ),
                  ProfileMenuRow(
                    icon: _sectionImage(Images.status_up),
                    title: 'pf_statistics'.tr,
                    onTap: () => _runWithLoginRequired(
                        () => Get.toNamed(RouteHelper.getStatistics())),
                  ),
                ];
                // يظهر دائماً (موجود بالتصميم) بغضّ النظر عن إعدادات السيرفر.
                promoRows.add(ProfileMenuRow(
                  icon: _sectionImage(Images.profile_add),
                  title: 'pf_earn_referral'.tr,
                  onTap: () => _runWithLoginRequired(
                      () => Get.toNamed(RouteHelper.getReferAndEarnRoute())),
                ));
                if (!ResponsiveHelper.isDesktop(context)) {
                  final String badge =
                      _getDeliverySuffix(isLoggedIn, dmController.status_model);
                  promoRows.add(ProfileMenuRow(
                    icon: _sectionImage(Images.captin_delivery),
                    title: 'pf_join_as_driver'.tr,
                    trailing: badge.isEmpty
                        ? null
                        : ProfileStatusBadge(
                            text: badge, color: _badgeColor(badge)),
                    onTap: () => _runWithLoginRequired(() =>
                        _handleDeliveryTap(true, dmController.status_model)),
                  ));
                }
                // مندوب تسويق قسائم شرائية
                final String delegateBadge =
                    _getDelegateSuffix(isLoggedIn, delegateController);
                promoRows.add(ProfileMenuRow(
                  icon: _sectionImage(Images.Delivery_representative),
                  title: 'pf_voucher_agent'.tr,
                  trailing: delegateBadge.isEmpty
                      ? null
                      : ProfileStatusBadge(
                          text: delegateBadge,
                          color: _badgeColor(delegateBadge)),
                  onTap: () => _runWithLoginRequired(
                      () => _handleDelegateTap(delegateController)),
                ));
                if (showStore) {
                  promoRows.add(ProfileMenuRow(
                    icon: _sectionImage(Images.shop),
                    title: 'open_vendor'.tr,
                    onTap: () => _runWithLoginRequired(() => Get.toNamed(
                        RouteHelper.getRestaurantRegistrationRoute())),
                  ));
                }

                // ─── المستندات القانونية ───
                final List<Widget> legalRows = <Widget>[
                  ProfileMenuRow(
                    icon: _sectionImage(Images.privacyIcon),
                    title: 'pf_privacy'.tr,
                    onTap: () =>
                        Get.toNamed(RouteHelper.getHtmlRoute('privacy-policy')),
                  ),
                  ProfileMenuRow(
                    icon: _sectionImage(Images.termsIcon),
                    title: 'pf_terms'.tr,
                    onTap: () => Get.toNamed(
                        RouteHelper.getHtmlRoute('terms-and-condition')),
                  ),
                ];
                // يظهر دائماً (موجود بالتصميم) بغضّ النظر عن إعدادات السيرفر.
                legalRows.add(ProfileMenuRow(
                  icon: _sectionImage(Images.refundIcon),
                  title: 'pf_refund_policy'.tr,
                  onTap: () =>
                      Get.toNamed(RouteHelper.getHtmlRoute('refund-policy')),
                ));
                if (cancellationPolicyStatus == 1) {
                  legalRows.add(ProfileMenuRow(
                    icon: _sectionImage(Images.cancelationIcon),
                    title: 'cancellation_policy'.tr,
                    onTap: () => Get.toNamed(
                        RouteHelper.getHtmlRoute('cancellation-policy')),
                  ));
                }
                if (shippingPolicyStatus == 1) {
                  legalRows.add(ProfileMenuRow(
                    icon: _sectionImage(Images.shippingIcon),
                    title: 'shipping_policy'.tr,
                    onTap: () => Get.toNamed(
                        RouteHelper.getHtmlRoute('shipping-policy')),
                  ));
                }

                return ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom +
                        Dimensions.paddingSizeLarge,
                  ),
                  children: <Widget>[
                    _buildHeader(),
                    Container(
                      color: ProfileMenuStyle.pageColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildProfileCard(
                              context, profileController, isLoggedIn),
                          _buildStatCards(
                              context,
                              profileController,
                              kaidha,
                              loyaltyPointStatus,
                              customerWalletStatus,
                              isLoggedIn),

                          // ─── حسابي ───
                          ProfileSectionCard(
                            label: 'pf_my_account'.tr,
                            children: <Widget>[
                              ProfileMenuRow(
                                icon: _sectionImage(Images.location_v2),
                                title: 'pf_delivery_addresses'.tr,
                                onTap: () => Get.toNamed(
                                    RouteHelper.getDeliveryAddressesRoute()),
                              ),
                              ProfileMenuRow(
                                icon: _sectionImage(Images.language_square),
                                title: 'pf_language'.tr,
                                subtitle: _currentLanguageLabel(),
                                onTap: _manageLanguageFunctionality,
                              ),
                              GetBuilder<AuthController>(
                                builder: (auth) => ProfileMenuRow(
                                  icon:
                                      _sectionImage(Images.headerNotification),
                                  title: 'pf_notifications'.tr,
                                  trailing: auth.notificationLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : _switch(
                                          auth.notification,
                                          (bool v) =>
                                              auth.setNotificationActive(v),
                                        ),
                                ),
                              ),
                            ],
                          ),

                          ProfileSectionCard(
                            label: 'pf_promotions_earnings'.tr,
                            children: promoRows,
                          ),

                          // ─── المساعدة والدعم ───
                          ProfileSectionCard(
                            label: 'pf_help_support'.tr,
                            children: <Widget>[
                              ProfileMenuRow(
                                icon: _sectionImage(Images.messages_v2),
                                title: 'pf_live_chat'.tr,
                                onTap: () => _runWithLoginRequired(() =>
                                    Get.toNamed(RouteHelper.getChatRoute(
                                      notificationBody: NotificationBodyModel(
                                        adminId: 0,
                                        name: 'pf_technical_support'.tr,
                                      ),
                                    ))),
                              ),
                              ProfileMenuRow(
                                icon: _sectionImage(Images.message_question),
                                title: 'pf_help_tech_support'.tr,
                                onTap: () =>
                                    Get.toNamed(RouteHelper.getSupportRoute()),
                              ),
                              ProfileMenuRow(
                                icon: _sectionIcon(Icons.refresh),
                                title: 'pf_check_updates'.tr,
                                onTap: () => Get.find<UpdateController>()
                                    .manualCheckForUpdates(),
                              ),
                              ProfileMenuRow(
                                icon: _sectionImage(Images.message_question),
                                title: 'pf_about_us'.tr,
                                onTap: () => Get.toNamed(
                                    RouteHelper.getHtmlRoute('about-us')),
                              ),
                            ],
                          ),

                          ProfileSectionCard(
                            label: 'pf_legal_docs'.tr,
                            children: legalRows,
                          ),

                          const SizedBox(height: 24),
                          _buildLogout(context, profileController),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ],
                      ),
                    ),
                  ],
                );
              });
            });
          });
        }),
      ),
    );
  }

  // ─────────────────────────────── UI builders ───────────────────────────────

  Widget _sectionImage(String image) {
    return Image.asset(image,
        width: 21.r(context), height: 21.r(context), color: _iconColor);
  }

  Widget _sectionIcon(IconData icon) {
    return Icon(icon, size: 21.r(context), color: _iconColor);
  }

  Widget _switch(bool value, ValueChanged<bool>? onChanged) {
    return SizedBox(
      height: 28.r(context),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.bgColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFD9DCDF),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: ProfileMenuStyle.cardColor,
      padding: EdgeInsets.only(top: 10.r(context), bottom: 8.r(context)),
      child: Center(
        child: Text(
          'pf_my_account'.tr,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18.r(context),
            height: 1.6,
            fontWeight: FontWeight.w700,
            color: ProfileMenuStyle.titleColor,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, ProfileController pc, bool isLoggedIn) {
    final String fName = pc.userInfoModel?.fName ?? '';
    final String greeting =
        isLoggedIn ? '${'pf_hi'.tr} ${fName.trim()}'.trim() : 'guest_user'.tr;

    Future<void> onTap() async {
      if (isLoggedIn) {
        Get.toNamed(RouteHelper.getUpdateProfileRoute());
      } else {
        await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
        if (AuthHelper.isLoggedIn()) {
          pc.getUserInfo();
        }
      }
    }

    return Container(
      height: 100.r(context),
      margin: EdgeInsets.fromLTRB(16.r(context), 6.r(context), 16.r(context),
          4.r(context)),
      decoration: BoxDecoration(
        color: ProfileMenuStyle.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileMenuStyle.borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 16.r(context), vertical: 14.r(context)),
          child: Row(
            children: <Widget>[
              _buildAvatar(context, pc, isLoggedIn),
              SizedBox(width: 14.r(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16.r(context),
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                        color: ProfileMenuStyle.titleColor,
                      ),
                    ),
                    SizedBox(height: 5.r(context)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.settings_outlined,
                            size: 20.r(context),
                            color: AppColors.primaryColor),
                        SizedBox(width: 4.r(context)),
                        Flexible(
                          child: Text(
                            isLoggedIn
                                ? 'pf_account_settings'.tr
                                : 'login_to_view_all_feature'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13.r(context),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
      BuildContext context, ProfileController pc, bool isLoggedIn) {
    final String? imageUrl = (pc.userInfoModel != null &&
            isLoggedIn &&
            pc.userInfoModel!.imageFullUrl != null &&
            pc.userInfoModel!.imageFullUrl!.isNotEmpty)
        ? pc.userInfoModel!.imageFullUrl!
        : null;

    return Container(
      width: 54.r(context),
      height: 54.r(context),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xffF6F5F8),
      ),
      child: ClipOval(
        child: (imageUrl == null || imageUrl.isEmpty)
            ? Image.asset(
                Images.navProfileActive,
                width: 30.r(context),
              )
            : CustomImage(
                image: imageUrl,
                width: 54.r(context),
                height: 54.r(context),
                fit: BoxFit.cover,
                placeholderWidget: Image.asset(
                  Images.navProfileActive,
                  width: 30.r(context),
                ),
                errorWidget: Image.asset(
                  Images.navProfileActive,
                  width: 30.r(context),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCards(
    BuildContext context,
    ProfileController pc,
    KaidhaSubscriptionController kaidha,
    int loyaltyPointStatus,
    int customerWalletStatus,
    bool isLoggedIn,
  ) {
    // Qidha wallet state (subscribed → show balance, else prompt to subscribe).
    final wallet = kaidha.walletKaidhaModel?.wallet;
    final sig = wallet?.signatureStatus;
    final bool qidhaSigned = sig == 1 || sig == true;
    final bool qidhaActive =
        wallet?.status?.toString().toLowerCase() == 'active';
    final bool qidhaSubscribed = wallet != null && qidhaSigned && qidhaActive;

    double qidhaBalance() {
      final balance = wallet?.availableBalance;
      if (balance == null) {
        return 0.0;
      }
      if (balance is num) {
        return balance.toDouble();
      }
      if (balance is String) {
        return double.tryParse(balance) ?? 0.0;
      }
      return 0.0;
    }

    final int loyaltyPoints = pc.userInfoModel?.loyaltyPoint ?? 0;
    final double walletBalance = pc.userInfoModel?.walletBalance ?? 0;

    // The three summary cards are always shown (per design), independent of
    // the server config flags. The call-to-action subtitle only shows when the
    // card has no balance/points yet — once there's a value, it's hidden.
    final List<Widget> cards = <Widget>[
      ProfileStatCard(
        background: const Color(0xFFCEF9CF),
        accent: Color(0xffCFFAD0),
        image: Images.quidha_wallet_profile,
        label: 'pf_qidha_wallet'.tr,
        value: qidhaSubscribed
            ? PriceConverter.convertPrice(qidhaBalance())
            : PriceConverter.convertPrice(0),
        subtitle: qidhaSubscribed ? null : 'pf_subscribe_now'.tr,
        onTap: () => _runWithLoginRequired(() => Get.toNamed(qidhaSubscribed
            ? RouteHelper.getKaidhaWallet()
            : RouteHelper.getKiadaWalletSubscription())),
      ),
      ProfileStatCard(
        background: const Color(0xFFEBFEEB),
        accent: Color(0xffEBFEEB),
        image: Images.my_wallet_profile,
        label: 'pf_my_wallet'.tr,
        value: PriceConverter.convertPrice(walletBalance),
        subtitle: walletBalance > 0 ? null : 'pf_add_balance_now'.tr,
        onTap: () => _runWithLoginRequired(
            () => Get.toNamed(RouteHelper.getold_wallet())),
      ),
      ProfileStatCard(
        background: const Color(0xFFEFE6FF),
        accent: const Color(0xFFEFE6FF),
        image: Images.my_points,
        label: 'pf_your_points'.tr,
        value: '$loyaltyPoints',
        subtitle: loyaltyPoints > 0 ? null : 'pf_earn_points_now'.tr,
        onTap: () => _runWithLoginRequired(
            () => Get.toNamed(RouteHelper.getLoyaltyRoute())),
      ),
    ];

    final List<Widget> spaced = <Widget>[];
    for (int i = 0; i < cards.length; i++) {
      spaced.add(cards[i]);
      if (i != cards.length - 1) {
        spaced.add(SizedBox(width: 8.r(context)));
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16.r(context), 10.r(context), 16.r(context), 2.r(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: spaced,
      ),
    );
  }

  Widget _buildLogout(
      BuildContext context, ProfileController profileController) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ProfileMenuStyle.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileMenuStyle.borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleLogoutTap(context, profileController),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.r(context)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Image.asset(
                Images.logout,
                width: 25.r(context),
                height: 25.r(context),
                color: const Color(0xff555555),
              ),
              SizedBox(width: 10.r(context)),
              Text(
                AuthHelper.isLoggedIn() ? 'logout'.tr : 'sign_in'.tr,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15.r(context),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _currentLanguageLabel() {
    try {
      final int index =
          Get.find<LocalizationController>().selectedLanguageIndex;
      final String code = (index >= 0 && index < AppConstants.languages.length)
          ? (AppConstants.languages[index].countryCode ?? 'SA')
          : 'SA';
      return code.toUpperCase() == 'US'
          ? 'English (United States)'
          : 'pf_lang_ar_sa'.tr;
    } catch (_) {
      return 'pf_lang_ar_sa'.tr;
    }
  }

  Color _badgeColor(String badge) {
    if (badge.contains('مرفوض')) {
      return AppColors.redColor;
    }
    if (badge.contains('مراجعة') || badge.contains('الحالة')) {
      return AppColors.secondaryColor;
    }
    return AppColors.primaryColor;
  }

  Future<void> _handleLogoutTap(
      BuildContext context, ProfileController profileController) async {
    if (AuthHelper.isLoggedIn()) {
      Future<void> doLogout() async {
        Get.back(); // Close the dialog.

        // NOTE: target has no AuthSessionGuard; the duplicate-tap guard is
        // already covered by closing the dialog above, so we proceed directly.

        // E-commerce data is completely independent of user authentication
        // No need to invalidate anything - cache persists across login/logout
        Get.find<ProfileController>().clearUserInfo();

        await Get.find<AuthController>().socialLogout();

        await Get.find<CartController>()
            .clearCartList(canRemoveOnline: false);

        Get.find<FavouriteController>().removeFavourite();

        await Get.find<AuthController>().clearSharedData();

        Get.find<HomeController>().forcefullyNullCashBackOffers();

        await Get.find<TaxiCartController>().getCarCartList();

        // E-commerce cache remains valid after logout
        // Ensure data is loaded before navigation
        await _ensureDataLoadedBeforeNavigation();

        // Passwordless flow: after logout land on the Welcome entry screen.
        await Get.offAllNamed(RouteHelper.getSignInRoute(RouteHelper.main));
      }

      Get.dialog(
        Dialog(
          backgroundColor: AppColors.wtColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'pf_confirm_logout'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3633),
                  ),
                ),
                const SizedBox(height: 22),
                _logoutDialogButton(
                  text: 'pf_yes_logout'.tr,
                  color: AppColors.primaryColor,
                  textColor: AppColors.wtColor,
                  onTap: doLogout,
                ),
                const SizedBox(height: 10),
                _logoutDialogButton(
                  text: 'pf_cancel'.tr,
                  color: const Color(0xFFF3F4F6),
                  textColor: const Color(0xFF2D3633),
                  onTap: () => Get.back(),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Get.find<FavouriteController>().removeFavourite();

      await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));

      if (AuthHelper.isLoggedIn()) {
        await Get.find<FavouriteController>().getFavouriteList();
        profileController.getUserInfo();
      }
    }
  }

  Widget _logoutDialogButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
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
      debugPrint('[PROFILE_STATUS][DELIVERY_CHECK_START] phone=${phone ?? ''}');
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
    String badge = 'pf_join_now'.tr;
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
      badge = 'pf_join_now'.tr;
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
    final Map<String, dynamic>? deliveryMan =
        response['delivery_man'] is Map<String, dynamic>
            ? response['delivery_man'] as Map<String, dynamic>
            : null;
    final String applicationStatus =
        (deliveryMan?['application_status'] ?? '').toString().toLowerCase();
    if (applicationStatus.isNotEmpty) {
      return applicationStatus;
    }
    final String statusRaw =
        (deliveryMan?['status'] ?? '').toString().toLowerCase();
    final String activeRaw =
        (deliveryMan?['active'] ?? '').toString().toLowerCase();
    if (statusRaw == '1' ||
        statusRaw == 'active' ||
        activeRaw == '1' ||
        activeRaw == 'true') {
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
          content:
              Text('pf_request_under_review_body'.tr),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: Text('pf_ok'.tr),
            ),
          ],
        ),
      );
      return;
    }
    if (applicationStatus == 'approved' || applicationStatus == 'active') {
      debugPrint('[PROFILE_STATUS][POPUP] item=delivery message=approved');
      await Get.dialog<void>(
        AlertDialog(
          title: Text('pf_request_approved'.tr),
          content: Text('pf_driver_accepted'.tr),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: Text('pf_ok'.tr),
            ),
          ],
        ),
      );
      return;
    }
    if (applicationStatus == 'rejected') {
      debugPrint('[PROFILE_STATUS][POPUP] item=delivery message=rejected');
      showCustomSnackBar('pf_request_rejected'.tr, isError: false);
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

  String _getDelegateSuffix(bool isLoggedIn, Delegate_Controller controller) {
    if (!isLoggedIn) return '';
    if (controller.isLoading) return 'الحالة';

    final model = controller.delegate_model;
    if (model == null) return 'pf_submit_request'.tr;

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
          title: Text('pf_request_under_review_title'.tr),
          content: Text(
            'pf_agent_under_review'.tr,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: Text('pf_ok'.tr),
            ),
          ],
        ),
      );
      return;
    }
    if (status == 'active' || status == 'approved') {
      showCustomSnackBar('pf_request_approved'.tr, isError: false);
      return;
    }
    final String route = RouteHelper.getAdd_DelegateScreen();
    debugPrint(
        '[PROFILE_STATUS][ROUTE] item=delegate route=add_delegate_screen');
    Get.toNamed(route);
  }

  Future<void> _manageLanguageFunctionality() async {
    Get.find<LocalizationController>().searchSelectedLanguage();
    await Get.to<void>(() => const LanguageSelectScreen());
    if (mounted) {
      setState(() {});
    }
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
