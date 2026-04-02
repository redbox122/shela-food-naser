import 'dart:async';
import 'dart:io';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/taxi_cart_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/store_registration_success_bottom_sheet.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/address/screens/address_screen.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/taxi_cart_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/screens/vehicle_favourite_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/taxi_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/cart_widget.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/dashboard/widgets/parcel_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/favourite/screens/favourite_screen.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/home/screens/multi_module/multi_module_home_screen.dart';
import 'package:sixam_mart/features/home/screens/module_home_router_screen.dart';
import 'package:sixam_mart/features/menu/screens/menu_screen.dart';
import 'package:sixam_mart/features/order/screens/order_screen.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import '../widgets/running_order_view_widget.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  final bool fromSplash;
  final bool skipSplash;
  final int? moduleId;
  final int? previousModuleId;
  const DashboardScreen({
    super.key,
    required this.pageIndex,
    this.fromSplash = false,
    this.skipSplash = false,
    this.moduleId,
    this.previousModuleId,
  });

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  PageController? _pageController;
  int _pageIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  GlobalKey<ExpandableBottomSheetState> key = GlobalKey();
  late bool _isLogin;
  bool active = false;
  DateTime? _runningOrdersHiddenUntil;
  String? _runningOrdersHiddenSignature;
  static const String _runningOrdersHiddenUntilKey =
      'running_orders_hidden_until_ms';
  static const String _runningOrdersHiddenSignatureKey =
      'running_orders_hidden_signature';
  static const Duration _runningOrdersHideDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();

    debugPrint('\x1B[32m     //////////////////////     \x1B[0m');

    // ⚡ TITAN BOARD: Skip splash animation if skipSplash flag is set
    // This enables direct navigation to HomeScreen without splash delay (100ms target)
    if (widget.skipSplash) {
      if (kDebugMode) {
        debugPrint(
            '⚡ DashboardScreen: skipSplash=true - bypassing splash animation');
      }
    }

    _isLogin = AuthHelper.isLoggedIn();
    _applyModuleOverrideIfNeeded();
    _showRegistrationSuccessBottomSheet();
    _loadRunningOrdersBarVisibilityState();
    if (_isLogin) {
      // Disable loyalty congratulation popup after order completion.
      if (Get.find<AuthController>().getEarningPint().isNotEmpty) {
        Get.find<AuthController>().saveEarningPoint('');
      }
      _loadRunningOrdersForGlobalBottomSheet();
    }
    _pageIndex = widget.pageIndex;
    _pageController = PageController(initialPage: widget.pageIndex);
    // ⚡ TASK 2: Conditional initialization - use MultiModuleHomeScreen if multiple modules exist
    // This prevents legacy HomeScreen from being initialized when MultiModuleHomeScreen is active
    _screens = [
      _buildHomeRoot(),
      const FavouriteScreen(),
      const SizedBox(),
      const OrderScreen(),
      const MenuScreen()
    ];

    // ⚡ PERF FIX: Preload other modules AFTER splash completes.
    // Previously this ran during splash, competing for network/CPU and
    // inflating splash time from ~3s to ~14s.  A 2s post-frame delay
    // ensures the home screen has rendered first.
    _deferCoreModulePreload();
  }

  void _deferCoreModulePreload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (Get.isRegistered<SplashController>()) {
          unawaited(Get.find<SplashController>()
              .preloadCoreModulesForFastSwitch()
              .catchError((Object _) {}));
        }
      });
    });
  }

  void _loadRunningOrdersForGlobalBottomSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || !_isLogin || !Get.isRegistered<OrderController>()) {
          return;
        }
        final OrderController orderController = Get.find<OrderController>();
        final bool hasRunningOrdersLoaded =
            orderController.runningOrderModel?.orders != null;
        if (!hasRunningOrdersLoaded) {
          orderController.getRunningOrders(1,
              isUpdate: false, fromDashboard: true);
        }
      });
    });
  }

  Future<void> _loadRunningOrdersBarVisibilityState() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final int? hiddenUntilMs = preferences.getInt(_runningOrdersHiddenUntilKey);
    final String? hiddenSignature =
        preferences.getString(_runningOrdersHiddenSignatureKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _runningOrdersHiddenUntil = hiddenUntilMs != null
          ? DateTime.fromMillisecondsSinceEpoch(hiddenUntilMs)
          : null;
      _runningOrdersHiddenSignature = hiddenSignature;
    });
  }

  Future<void> _hideRunningOrdersBarTemporarily(
      List<OrderModel> reversedRunningOrders) async {
    final DateTime hideUntil = DateTime.now().add(_runningOrdersHideDuration);
    final String signature =
        _buildRunningOrdersSignature(reversedRunningOrders);
    setState(() {
      _runningOrdersHiddenUntil = hideUntil;
      _runningOrdersHiddenSignature = signature;
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
        _runningOrdersHiddenUntilKey, hideUntil.millisecondsSinceEpoch);
    await preferences.setString(_runningOrdersHiddenSignatureKey, signature);
    showCustomSnackBar('تم إخفاء شريط الطلبات مؤقتًا', isError: false);
  }

  Future<void> _clearRunningOrdersBarHiddenState() async {
    if (_runningOrdersHiddenUntil == null &&
        _runningOrdersHiddenSignature == null) {
      return;
    }
    setState(() {
      _runningOrdersHiddenUntil = null;
      _runningOrdersHiddenSignature = null;
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_runningOrdersHiddenUntilKey);
    await preferences.remove(_runningOrdersHiddenSignatureKey);
  }

  String _buildRunningOrdersSignature(List<OrderModel> reversedRunningOrders) {
    return reversedRunningOrders
        .map((OrderModel order) =>
            '${order.id}:${order.orderStatus ?? ''}:${order.paymentStatus ?? ''}')
        .join('|');
  }

  bool _shouldShowRunningOrdersBar(List<OrderModel> reversedRunningOrders) {
    if (reversedRunningOrders.isEmpty) {
      return false;
    }
    final DateTime? hiddenUntil = _runningOrdersHiddenUntil;
    if (hiddenUntil == null) {
      return true;
    }
    final DateTime now = DateTime.now();
    final String currentSignature =
        _buildRunningOrdersSignature(reversedRunningOrders);
    final bool hasSignatureChanged = _runningOrdersHiddenSignature != null &&
        _runningOrdersHiddenSignature != currentSignature;
    final bool hasHideExpired = now.isAfter(hiddenUntil);
    if (hasSignatureChanged || hasHideExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clearRunningOrdersBarHiddenState();
      });
      return true;
    }
    return false;
  }

  void _applyModuleOverrideIfNeeded() {
    if (widget.moduleId == null) {
      return;
    }
    final splashController = Get.find<SplashController>();
    final ModuleModel? targetModule = _findModuleById(widget.moduleId);

    if (targetModule != null &&
        splashController.selectedModule.value?.id != targetModule.id) {
      Future.microtask(() async {
        await splashController.setModule(targetModule);
        if (targetModule.id != null &&
            Get.isRegistered<HomeUnifiedController>()) {
          await Get.find<HomeUnifiedController>()
              .onModuleReady(targetModule.id!);
        }
      });
    }
  }

  ModuleModel? _findModuleById(int? moduleId) {
    if (moduleId == null) {
      return null;
    }
    final moduleList = Get.find<SplashController>().moduleList;
    if (moduleList == null) {
      return null;
    }
    for (final module in moduleList) {
      if (module.id == moduleId) {
        return module;
      }
    }
    return null;
  }

  Widget _buildHomeRoot() {
    return Obx(() {
      final splashController = Get.find<SplashController>();
      final moduleListLength = splashController.moduleList?.length ?? 0;
      final selectedModuleId =
          splashController.selectedModule.value?.id ?? widget.moduleId;
      final bool showMultiModuleScreen =
          splashController.selectedModule.value == null &&
              splashController.module == null &&
              moduleListLength > 1;

      return showMultiModuleScreen
          ? MultiModuleHomeScreen(
              key: ValueKey('multi_$selectedModuleId'),
              showBottomNavigation: false,
            )
          : selectedModuleId != null
              ? ModuleHomeRouterScreen(
                  key: ValueKey('module_home_$selectedModuleId'),
                  moduleId: selectedModuleId,
                )
              : const HomeScreen();
    });
  }

  void _showRegistrationSuccessBottomSheet() {
    final bool canShowBottomSheet =
        Get.find<HomeController>().getRegistrationSuccessfulSharedPref();
    if (canShowBottomSheet) {
      Future.delayed(const Duration(seconds: 1), () {
        Get.context != null && ResponsiveHelper.isDesktop(Get.context!)
            ? Get.dialog(
                    const Dialog(child: StoreRegistrationSuccessBottomSheet()))
                .then((value) {
                Get.find<HomeController>()
                    .saveRegistrationSuccessfulSharedPref(false);
                Get.find<HomeController>()
                    .saveIsStoreRegistrationSharedPref(false);
                setState(() {});
              })
            : showModalBottomSheet(
                context: Get.context!,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (con) => const StoreRegistrationSuccessBottomSheet(),
              ).then((value) {
                Get.find<HomeController>()
                    .saveRegistrationSuccessfulSharedPref(false);
                Get.find<HomeController>()
                    .saveIsStoreRegistrationSharedPref(false);
                setState(() {});
              });
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return GetBuilder<SplashController>(builder: (splashController) {
      return PopScope(
        onPopInvokedWithResult: (didPop, result) async {
          if (GetPlatform.isAndroid) {
            SystemNavigator.pop();
          } else if (GetPlatform.isIOS) {
            exit(0);
          }
        },
        child: GetBuilder<OrderController>(builder: (orderController) {
          List<OrderModel> runningOrder = [];
          if (orderController.runningOrderModel != null &&
              orderController.runningOrderModel!.orders != null) {
            runningOrder = orderController.runningOrderModel!.orders!;
          }
          final List<OrderModel> reversOrder = List.from(runningOrder.reversed);

          return GetBuilder<SplashController>(
            builder: (splashController) {
              bool isParcel = splashController
                      .configModel?.moduleConfig?.module?.isParcel ??
                  false;
              final bool isTaxiWithCache = ((splashController.module?.moduleType
                              .toString() ==
                          AppConstants.taxi) ||
                      (splashController.cacheModule?.moduleType.toString() ==
                          AppConstants.taxi)) &&
                  TaxiHelper.haveTaxiModule();
              final bool isTaxi =
                  splashController.module?.moduleType.toString() ==
                      AppConstants.taxi;
              isParcel = isParcel && !isTaxiWithCache;

              // ⚡ TASK 2: Conditional initialization - use MultiModuleHomeScreen if multiple modules exist
              // This prevents legacy HomeScreen from being initialized when MultiModuleHomeScreen is active
              _screens = [
                _buildHomeRoot(),
                isParcel
                    ? const AddressScreen(fromDashboard: true)
                    : isTaxi
                        ? const VehicleFavouriteScreen()
                        : const FavouriteScreen(),
                const SizedBox(),
                OrderScreen(index: isTaxi ? 1 : 0),
                const MenuScreen()
              ];

              // Map page index to nav bar index (0,1,3,4 -> 0,1,2,3)
              final int navBarIndex =
                  _pageIndex < 2 ? _pageIndex : _pageIndex - 1;

              final iconList = <IconData>[
                Icons.home_outlined,
                isParcel ? Icons.location_on_outlined : Icons.favorite_border,
                Icons.list_alt,
                Icons.more_horiz,
              ];

              final bool showBottomChrome =
                  !(ResponsiveHelper.isDesktop(context) ||
                      (widget.fromSplash &&
                          Get.find<LocationController>()
                              .showLocationSuggestion &&
                          active) ||
                      keyboardVisible);
              final bool shouldShowRunningOrdersSheet = !((widget.fromSplash &&
                      Get.find<LocationController>().showLocationSuggestion &&
                      active &&
                      !ResponsiveHelper.isDesktop(context)) ||
                  !_isLogin ||
                  runningOrder.isEmpty ||
                  !orderController.showBottomSheet ||
                  !_shouldShowRunningOrdersBar(reversOrder));

              return Scaffold(
                key: _scaffoldKey,
                body: ExpandableBottomSheet(
                  background: Stack(children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _screens.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) => _screens[index],
                    ),
                  ]),
                  persistentContentHeight: shouldShowRunningOrdersSheet
                      ? (GetPlatform.isIOS ? 110 : 100)
                      : 0,
                  onIsContractedCallback: () {
                    if (!orderController.showOneOrder) {
                      orderController.showOrders();
                    }
                  },
                  onIsExtendedCallback: () {
                    if (orderController.showOneOrder) {
                      orderController.showOrders();
                    }
                  },
                  enableToggle: true,
                  expandableContent: shouldShowRunningOrdersSheet
                      ? Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) =>
                              orderController.showRunningOrders(),
                          child: RunningOrderViewWidget(
                            reversOrder: reversOrder,
                            onClose: () {
                              _hideRunningOrdersBarTemporarily(reversOrder);
                            },
                            onOrderTap: () {
                              _setPage(3);
                              orderController.showRunningOrders();
                            },
                          ),
                        )
                      : const SizedBox(),
                ),
                floatingActionButton: !showBottomChrome
                    ? null
                    : FloatingActionButton(
                        // 🔥 FIX: Add unique heroTag to prevent "multiple heroes" error
                        // This ensures each FloatingActionButton has a unique tag for hero animations
                        heroTag: null,
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: const CircleBorder(),
                        child: isTaxiWithCache
                            ? TaxiCartWidget(
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 22,
                              )
                            : isParcel
                                ? Icon(
                                    CupertinoIcons.add,
                                    size: 28,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  )
                                : CartWidget(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    size: 22,
                                  ),
                        onPressed: () {
                          // Handle cart navigation
                          if (isParcel) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (con) => ParcelBottomSheetWidget(
                                parcelCategoryList: Get.find<ParcelController>()
                                    .parcelCategoryList,
                              ),
                            );
                          } else if (isTaxiWithCache) {
                            Get.to(() => const TaxiCartScreen());
                          } else {
                            Get.toNamed(RouteHelper.getCartRoute());
                          }
                        },
                      ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: !showBottomChrome
                    ? null
                    : GetBuilder<FavouriteController>(
                        builder: (FavouriteController favController) {
                          final int favCount =
                              (favController.wishItemList?.length ?? 0) +
                                  (favController.wishStoreList?.length ?? 0);
                          final String favBadgeText =
                              favCount > 99 ? '99+' : favCount.toString();
                          final bool showFavBadge = !isParcel && favCount > 0;
                          return SafeArea(
                            top: false,
                            left: false,
                            right: false,
                            minimum: EdgeInsets.zero,
                            child: AnimatedBottomNavigationBar.builder(
                              itemCount: iconList.length,
                              tabBuilder: (int index, bool isActive) {
                                final Color iconColor = isActive
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.55);
                                final bool isFavTab = !isParcel && index == 1;
                                return SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: <Widget>[
                                      Center(
                                        child: Icon(iconList[index],
                                            size: 28, color: iconColor),
                                      ),
                                      if (isFavTab && showFavBadge)
                                        Positioned.fill(
                                          child: Center(
                                            child: Text(
                                              favBadgeText,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                              activeIndex: navBarIndex,
                              gapLocation: GapLocation.center,
                              notchSmoothness: NotchSmoothness.softEdge,
                              leftCornerRadius: 0,
                              rightCornerRadius: 0,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              shadow: BoxShadow(
                                offset: const Offset(0, 1),
                                blurRadius: 12,
                                spreadRadius: 0.5,
                                color: Theme.of(context)
                                    .shadowColor
                                    .withValues(alpha: 0.16),
                              ),
                              onTap: (int index) {
                                if (index == 0) {
                                  Get.offAll<dynamic>(
                                      () => MultiModuleHomeScreen(
                                            key: ValueKey(
                                                'multi_${Get.find<SplashController>().selectedModule.value?.id}'),
                                            showBottomNavigation: false,
                                          ));
                                  return;
                                }
                                final int pageIndex =
                                    index < 2 ? index : index + 1;
                                _setPage(pageIndex);
                              },
                            ),
                          );
                        },
                      ),
              );
            },
          );
        }),
      );
    });
  }

  void _setPage(int pageIndex) {
    setState(() {
      // Don't navigate to page 2 (cart) - it's handled separately
      if (pageIndex != 2) {
        _pageController!.jumpToPage(pageIndex);
        _pageIndex = pageIndex;
      }
    });
  }

  Widget trackView(BuildContext context, {required bool status}) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: status
            ? Theme.of(context).primaryColor
            : Theme.of(context).disabledColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
    );
  }
}
