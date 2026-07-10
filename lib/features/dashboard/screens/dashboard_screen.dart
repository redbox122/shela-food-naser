import 'dart:async';
import 'dart:io';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/dashboard/widgets/store_registration_success_bottom_sheet.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/taxi_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/home/screens/module_home_router_screen.dart';
import 'package:sixam_mart/features/order/screens/order_screen.dart';
import 'package:sixam_mart/features/order/screens/my_orders_screen.dart';
import 'package:sixam_mart/features/cart/screens/cart_screen.dart';
// Transferred profile design (white "حسابي" sectioned menu) shown in the
// profile tab instead of the legacy green ProfileScreen.
import 'package:sixam_mart/features/menu/screens/menu_screen.dart';
// Favourites tab replaces the Discounts tab in the bottom nav.
import 'package:sixam_mart/features/favourite/screens/favourite_screen.dart';
import 'package:sixam_mart/features/dashboard/widgets/home_bottom_nav_bar.dart';
import 'package:sixam_mart/util/images.dart';
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
    // 🎨 REDESIGN: 5-tab nav — Home / Cart / Discounts / Orders / Profile
    _screens = [
      _buildHomeRoot(),
      const CartScreen(fromNav: true),
      const MyOrdersScreen(),
      const FavouriteScreen(),
      const MenuScreen(),
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
      final selectedModuleId =
          splashController.selectedModule.value?.id ?? widget.moduleId;

      // 🎨 REDESIGN: the home tab no longer uses the legacy module-first
      // MultiModuleHomeScreen. When no module is selected we land directly on
      // the unified new HomeScreen (greeting + services grid + offers); module
      // selection happens by tapping a service tile, not by swapping the home.
      return selectedModuleId != null
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
              // 🎨 REDESIGN: 5-tab nav — Home / Cart / Discounts / Orders / Profile
              // 🎨 REDESIGN: 5-tab nav — Home / Cart / Orders / Discounts / Profile
              _screens = [
                _buildHomeRoot(),
                const CartScreen(fromNav: true),
                // 🎨 REDESIGN: taxi keeps the legacy trips tabs; everyone else
                // gets the redesigned "طلباتي" screen.
                isTaxi
                    ? const OrderScreen(index: 1)
                    : const MyOrdersScreen(),
                const FavouriteScreen(),
                const MenuScreen(),
              ];

              const navItems = <HomeNavBarItem>[
                HomeNavBarItem(
                    icon: Images.home_v2,
                    activeIcon: Images.home_v2_active,
                    label: 'nav_home'),
                HomeNavBarItem(
                    icon: Images.bag_v2,
                    activeIcon: Images.bag_v2_active,
                    label: 'nav_cart',
                    isCart: true),
                HomeNavBarItem(
                    icon: Images.receipt_ext_v2,
                    activeIcon: Images.receipt_ext_v2_active,
                    label: 'nav_orders'),
                HomeNavBarItem(
                    icon: Images.heart_v2,
                    activeIcon: Images.heart_v2,
                    label: 'nav_favourite'),
                HomeNavBarItem(
                    icon: Images.profile_v2,
                    activeIcon: Images.profile_v2_active,
                    label: 'nav_profile'),
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
                              _setPage(2);
                              orderController.showRunningOrders();
                            },
                          ),
                        )
                      : const SizedBox(),
                ),
                // 🎨 REDESIGN: No centre FAB — cart is now a regular tab.
                floatingActionButton: null,
                bottomNavigationBar: !showBottomChrome
                    ? null
                    : HomeBottomNavBar(
                        items: navItems
                            .map((item) => HomeNavBarItem(
                                  icon: item.icon,
                                  activeIcon: item.activeIcon,
                                  label: item.label.tr,
                                  isCart: item.isCart,
                                ))
                            .toList(),
                        currentIndex: _pageIndex,
                        onTap: _setPage,
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
      _pageController!.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
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
