// ignore_for_file: avoid_unnecessary_containers, deprecated_member_use, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/widgets/debug_popup_panel.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/notification/screens/notification_screen.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/screens/multi_module/multi_module_home_screen.dart';

// ================ Search Bar

Widget build_Search(BuildContext context, bool showMobileModule, bool isTaxi) {
  // if (showMobileModule || isTaxi) return const SizedBox();

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // ================ Search Bar 🔍
      Expanded(
        child: Container(
          height: 50,
          width: Dimensions.webMaxWidth,
          color: Theme.of(context).primaryColor,
          child: InkWell(
            onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall),
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 5, spreadRadius: 1)
                ],
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.search,
                      size: 25, color: Theme.of(context).primaryColor),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Expanded(
                    child: Text(
                      Get.find<SplashController>()
                                  .configModel
                                  ?.moduleConfig
                                  ?.module
                                  ?.showRestaurantText ==
                              true
                          ? 'search_food_or_restaurant'.tr
                          : 'search_item_or_store'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ), //

      //

      // ================ Debug Button (Debug Mode Only) 🐛
      if (kDebugMode)
        Padding(
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
          child: IconButton(
            icon: Icon(
              Icons.bug_report,
              size: 28,
              color: Theme.of(context).extension<CustomThemeExtension>()!.white_Color,
            ),
            onPressed: () {
              showDebugPopupPanel(context);
            },
            tooltip: 'Debug Popup Panel',
          ),
        ),

      // ================ Notification 🔔

      build_NotificationIcon(context),
    ],
  );
}

// ==================

class _AnimatedNotificationIcon extends StatefulWidget {
  final VoidCallback onPressed;
  final Color iconColor;

  const _AnimatedNotificationIcon({
    required this.onPressed,
    required this.iconColor,
  });

  @override
  State<_AnimatedNotificationIcon> createState() =>
      _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<_AnimatedNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNotification = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startRingingAnimation() {
    if (_hasNotification) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();
    
    // ⚡ TASK 1: Use Obx to reactively listen to hasUnread
    return Obx(() {
      final hasUnreadValue = notificationController.hasUnread.value;
      
      // Check if unread status changed
      if (hasUnreadValue != _hasNotification) {
        _hasNotification = hasUnreadValue;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startRingingAnimation();
        });
      }

      return Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _hasNotification ? _rotationAnimation.value : 0.0,
                child: Transform.scale(
                  scale: _hasNotification ? _scaleAnimation.value : 1.0,
                  child: IconButton(
                    icon: Icon(
                      CupertinoIcons.bell,
                      size: 28,
                      color: widget.iconColor,
                    ),
                    onPressed: widget.onPressed,
                  ),
                ),
              );
            },
          ),
          if (_hasNotification)
            Positioned(
              top: 5,
              right: 5,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _hasNotification ? _scaleAnimation.value : 1.0,
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .extension<CustomThemeExtension>()!
                              .white_Color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}

Widget build_NotificationIcon(BuildContext context) {
  return _AnimatedNotificationIcon(
    onPressed: () {
      _openNotificationCenter();
    },
    iconColor: Theme.of(context).extension<CustomThemeExtension>()!.white_Color,
  );
}

Future<void> _openNotificationCenter() async {
  final String route = RouteHelper.getNotificationRoute();
  debugPrint(
      '[NotificationIcon] tap currentRoute=${Get.currentRoute} targetRoute=$route');

  if (Get.currentRoute.startsWith(RouteHelper.notification)) {
    debugPrint('[NotificationIcon] already on notification route - skip push');
    return;
  }

  try {
    await Get.toNamed<dynamic>(route);
  } catch (error, stackTrace) {
    debugPrint('[NotificationIcon] named route failed: $error');
    debugPrintStack(
        label: '[NotificationIcon] named route stack', stackTrace: stackTrace);
    await Get.to<dynamic>(
      () => const NotificationScreen(fromNotification: false),
    );
  }
}

// ================== Address section with icons and text

Widget build_Address(BuildContext context, SplashController splashController) {
  final customTheme = Theme.of(context).extension<CustomThemeExtension>();
  final whiteColor = customTheme?.white_Color ?? Colors.white;
  final address = AddressHelper.getUserAddressFromSharedPref();

  return Center(
    child: Container(
      width: Dimensions.webMaxWidth,
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall, vertical: 10),
      child: Row(
        children: [
          if (splashController.module != null &&
              splashController.configModel!.module == null &&
              splashController.moduleList != null &&
              splashController.moduleList!.length != 1)
            InkWell(
              onTap: () {
                // 🏗️ MODULE-FIRST ARCHITECTURE: Clear module selection and navigate to module selection screen
                final storeController = Get.find<StoreController>();
                storeController.resetStoreData();
                
                // 🏗️ MODULE-FIRST ARCHITECTURE: Navigate to MultiModuleHomeScreen for module selection
                // Don't clear selectedModule - let user select a new module
                // MultiModuleHomeScreen will handle module selection
                final selectedModuleId =
                    Get.find<SplashController>().selectedModule.value?.id;
                Get.offAll<dynamic>(
                  () => MultiModuleHomeScreen(
                    key: ValueKey('multi_$selectedModuleId'),
                  ),
                  transition: Transition.fadeIn,
                  duration: const Duration(milliseconds: 300),
                );
              },
              child: Image.asset(Images.moduleIcon,
                  height: 25, width: 25, color: whiteColor),
            ),

          const SizedBox(width: Dimensions.paddingSizeSmall),

          // ================ Address Section 📍

          Expanded(
            child: InkWell(
              onTap: () {
                // Use the proper location screen navigation that shows saved addresses
                debugPrint(
                    '🔍 Location arrow clicked - calling navigateToLocationScreen');
                Get.find<LocationController>()
                    .navigateToLocationScreen(context, 'home');

                debugPrint('\x1B[32m  /${address!.latitude} \x1B[0m');
                debugPrint('\x1B[32m  /${address.longitude} \x1B[0m');
              },
              child: GetBuilder<LocationController>(
                builder: (locationController) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          address?.address != null &&
                                  address!.address!.isNotEmpty
                              ? '${"your_location".tr} : ${AddressHelper().removeEnglishAndNumbers(address.address!)}'
                              : 'your_location'.tr,
                          style: robotoBold.copyWith(
                              color: whiteColor,
                              fontSize: Dimensions.fontSizeDefault),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, color: whiteColor, size: 18),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isBackButtonExist;
  final Function? onBackPressed;
  final bool showCart;

  const CustomAppBarWidget({
    super.key,
    required this.title,
    this.isBackButtonExist = true,
    this.onBackPressed,
    this.showCart = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      return Container(
        width: Dimensions.webMaxWidth,
        color: Theme.of(context).primaryColor,
        padding: const EdgeInsets.only(
          top: 10, 
          bottom: 10, 
          left: Dimensions.paddingSizeSmall, 
          right: Dimensions.paddingSizeSmall
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              build_Address(context, splashController),
              const SizedBox(height: 5),
              build_Search(context, false, false),
            ],
          ),
        ),
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
