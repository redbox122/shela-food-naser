import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/notification/screens/notification_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/home/screens/multi_module/multi_module_home_screen.dart';

class ParcelAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final bool? backButton;
  const ParcelAppBarWidget({super.key, this.backButton = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      shape: Border(
        bottom: BorderSide(
            width: .4,
            color: Theme.of(context).primaryColorLight.withValues(alpha: .2)),
      ),
      elevation: 0,
      leadingWidth: backButton! ? Dimensions.paddingSizeLarge : 0,
      title: GetBuilder<SplashController>(builder: (splashController) {
        return Row(children: [
          (splashController.module != null &&
                  splashController.configModel!.module == null &&
                  splashController.moduleList != null &&
                  splashController.moduleList!.length != 1)
              ? InkWell(
                  onTap: () {
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
                      height: 25,
                      width: 25,
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                )
              : const SizedBox(),
          SizedBox(
              width: (splashController.module != null &&
                      splashController.configModel!.module == null &&
                      splashController.moduleList != null &&
                      splashController.moduleList!.length != 1)
                  ? Dimensions.paddingSizeSmall
                  : 0),
          Expanded(
              child: InkWell(
            onTap: () => Get.find<LocationController>()
                .navigateToLocationScreen(context, 'home'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeSmall,
                horizontal: Dimensions.paddingSizeSmall,
              ),
              child:
                  GetBuilder<LocationController>(builder: (locationController) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AddressHelper.getUserAddressFromSharedPref()!
                            .addressType!
                            .tr,
                        style: robotoMedium.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(children: [
                        Flexible(
                          child: Text(
                            AddressHelper.getUserAddressFromSharedPref()!
                                .address!,
                            style: robotoRegular.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodyLarge!.color,
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.expand_more,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            size: 18),
                      ]),
                    ]);
              }),
            ),
          )),
          InkWell(
            onTap: _openNotificationCenterFromParcel,
            child: _AnimatedNotificationIconParcel(
              iconColor:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ]);
      }),
    );
  }

  @override
  Size get preferredSize =>
      Size(Dimensions.webMaxWidth, GetPlatform.isDesktop ? 70 : 56);
}

Future<void> _openNotificationCenterFromParcel() async {
  final String route = RouteHelper.getNotificationRoute();
  debugPrint(
      '[ParcelNotificationIcon] tap currentRoute=${Get.currentRoute} targetRoute=$route');

  if (Get.currentRoute.startsWith(RouteHelper.notification)) {
    debugPrint(
        '[ParcelNotificationIcon] already on notification route - skip push');
    return;
  }

  try {
    await Get.toNamed<dynamic>(route);
  } catch (error, stackTrace) {
    debugPrint('[ParcelNotificationIcon] named route failed: $error');
    debugPrintStack(
        label: '[ParcelNotificationIcon] named route stack',
        stackTrace: stackTrace);
    await Get.to<dynamic>(
      () => const NotificationScreen(fromNotification: false),
    );
  }
}

class _AnimatedNotificationIconParcel extends StatefulWidget {
  final Color iconColor;

  const _AnimatedNotificationIconParcel({
    required this.iconColor,
  });

  @override
  State<_AnimatedNotificationIconParcel> createState() =>
      _AnimatedNotificationIconParcelState();
}

class _AnimatedNotificationIconParcelState
    extends State<_AnimatedNotificationIconParcel>
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
    return GetBuilder<NotificationController>(
      builder: (notificationController) {
        // Check if notification status changed
        if (notificationController.hasNotification != _hasNotification) {
          _hasNotification = notificationController.hasNotification;
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
                    child: Icon(
                      CupertinoIcons.bell,
                      size: 25,
                      color: widget.iconColor,
                    ),
                  ),
                );
              },
            ),
            if (notificationController.hasNotification)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _hasNotification ? _scaleAnimation.value : 1.0,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).cardColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
