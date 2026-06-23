import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';

// class SplashRouteHelper{

// 🚫 FIX: Prevent double navigation - only route once
bool _hasRoutedFromSplash = false;
bool _isRoutingToHome = false;
DateTime? _lastHomeRouteAt;

/// Once we have committed to a final post-splash destination (cached module
/// or resolved module), this is set to true. Any later async splash callbacks
/// that try to route to MultiModuleHomeScreen or to '/' are ignored.
bool _splashRouteFinalized = false;

/// Public read-only accessor used by SplashScreen to skip late navigation
/// fallbacks once the cached-module direct route has fired.
bool get splashRouteFinalized => _splashRouteFinalized;

Future<void> _routeToDashboardOnce({bool force = false}) async {
  if (_isRoutingToHome) {
    return;
  }
  final DateTime now = DateTime.now();
  if (!force &&
      _lastHomeRouteAt != null &&
      now.difference(_lastHomeRouteAt!).inMilliseconds < 300) {
    return;
  }
  final splashController = Get.find<SplashController>();
  final moduleId = splashController.selectedModule.value?.id;
  final String targetRoute = force && moduleId != null
      ? '/?from-splash=false&module=$moduleId'
      : '/?from-splash=false';
  _isRoutingToHome = true;
  _lastHomeRouteAt = now;
  try {
    if (force || Get.currentRoute != targetRoute) {
      await Get.offAllNamed<void>(targetRoute);
    }
  } finally {
    Future.delayed(const Duration(milliseconds: 300), () {
      _isRoutingToHome = false;
    });
  }
}

/// 🎯 SPLASH_ROUTE: Direct route to a specific module (skips MultiModule detour).
///
/// Used when a cached module exists at startup so we can avoid the chain
/// `Splash -> MultiModule -> Dashboard -> MultiModule -> /module/N`.
Future<void> _routeDirectlyToModule(int moduleId) async {
  if (_isRoutingToHome) {
    if (kDebugMode) {
      debugPrint(
          '[SPLASH_ROUTE][BLOCK_DUPLICATE_NAV] current=${Get.currentRoute} target=${RouteHelper.getModuleHomeRoute(moduleId)}');
    }
    return;
  }
  final String targetRoute = RouteHelper.getModuleHomeRoute(moduleId);
  if (Get.currentRoute == targetRoute) {
    if (kDebugMode) {
      debugPrint(
          '[SPLASH_ROUTE][BLOCK_DUPLICATE_NAV] current=${Get.currentRoute} target=$targetRoute');
    }
    // Even if we're already on the target route, mark routing finalized so
    // late splash callbacks cannot push MultiModule on top.
    _hasRoutedFromSplash = true;
    _splashRouteFinalized = true;
    return;
  }
  _isRoutingToHome = true;
  _lastHomeRouteAt = DateTime.now();
  // Mark splash routing as committed BEFORE the navigation completes so any
  // late `route()` / `_navigateToMultiModuleHomeScreen()` callbacks that fire
  // during the navigation transition see the finalized flag and bail out.
  _hasRoutedFromSplash = true;
  _splashRouteFinalized = true;
  if (kDebugMode) {
    debugPrint('[SPLASH_ROUTE][DIRECT_TO_MODULE] id=$moduleId');
  }
  try {
    await Get.offAllNamed<void>(
      targetRoute,
      arguments: <String, dynamic>{
        'module_id': moduleId,
        'skip_splash': true,
        'from_splash_cached': true,
      },
    );
  } finally {
    Future.delayed(const Duration(milliseconds: 300), () {
      _isRoutingToHome = false;
    });
  }
}

/// Resolves the cached module ID into a `ModuleModel`. If the in-memory list
/// is empty, this method first tries the local cache and finally builds a
/// minimal stub `ModuleModel` so that we can still route directly to
/// `/module/<id>` instead of falling back to `MultiModuleHomeScreen`.
Future<ModuleModel?> _resolveCachedModuleForRouting({
  required SplashController splashController,
  required int cachedModuleId,
}) async {
  ModuleModel? findIn(List<ModuleModel>? list) {
    if (list == null || list.isEmpty) {
      return null;
    }
    for (final m in list) {
      if (m.id == cachedModuleId) {
        return m;
      }
    }
    return null;
  }

  ModuleModel? resolved = findIn(splashController.moduleList);
  if (resolved != null) {
    return resolved;
  }

  // 🔧 Fallback A: ask SplashController to load modules from local cache.
  try {
    await splashController
        .getModules(dataSource: DataSourceEnum.local)
        .timeout(const Duration(milliseconds: 600), onTimeout: () {});
  } catch (_) {
    // ignore — we'll handle nulls below.
  }
  resolved = findIn(splashController.moduleList);
  if (resolved != null) {
    return resolved;
  }

  // 🔧 Fallback B: build a minimal stub so direct module routing can still
  // proceed. SplashController.setModule will keep moduleType empty in this
  // case but routing to /module/<id> is enough to skip the MultiModule
  // detour. The full module model will arrive later through the regular
  // app-init refresh path.
  if (kDebugMode) {
    debugPrint(
        '[SPLASH_ROUTE][CACHED_MODULE_STUB] id=$cachedModuleId reason=module_list_unavailable');
  }
  return ModuleModel(id: cachedModuleId);
}

Future<void> routeToDashboardOnce({bool force = false}) async {
  await _routeToDashboardOnce(force: force);
}

/// 🏗️ MODULE-FIRST ARCHITECTURE: Route Guard
/// After splash screen, always show MultiModuleHomeScreen first for module selection
/// 🚫 FIX: Simplified - directly navigate using Get.offAllNamed to prevent loops
void _navigateToMultiModuleHomeScreen() {
  // 🚫 GUARD (Bug 2): If a direct module route already finalized splash, do
  // not let any late callback push MultiModuleHomeScreen on top of it.
  if (_splashRouteFinalized) {
    if (kDebugMode) {
      debugPrint(
          '[SPLASH_ROUTE][BLOCK_DUPLICATE_NAV] current=${Get.currentRoute} target=multi_module reason=route_finalized');
    }
    return;
  }
  // 🚫 FIX: Prevent double navigation - only route once
  if (_hasRoutedFromSplash) {
    if (kDebugMode) {
      debugPrint(
          '🏗️ [Module-First] Route Guard: Already routed, skipping duplicate navigation');
    }
    return; // Don't navigate again
  }
  _hasRoutedFromSplash = true;

  // 🏗️ MODULE-FIRST: Always show MultiModuleHomeScreen after splash
  // User must select a module before proceeding to Dashboard
  if (kDebugMode) {
    debugPrint(
        '🏗️ [Module-First] Route Guard: Routing to MultiModuleHomeScreen after splash');
  }

  // 🚫 FIX: Use Get.offAll() directly with widget to prevent navigation loops
  // This clears the entire navigation stack and navigates directly to MultiModuleHomeScreen
  // ⚠️ CRITICAL: Don't use Get.offAllNamed() with route name because route '/' opens DashboardScreen
  // We must use Get.offAll() with widget directly to bypass route system
  if (kDebugMode) {
    debugPrint(
        '🟥 SPLASH ROUTE EXECUTED at ${DateTime.now()} - Navigating to MultiModuleHomeScreen');
  }
  // 🎨 REDESIGN: land on the Dashboard (route '/') whose home tab is the new
  // unified HomeScreen (greeting + services grid + offers), instead of the
  // legacy module-first selection screen. Module selection now happens by
  // tapping a service tile on the home.
  Get.offAllNamed<dynamic>(RouteHelper.initial);
}

void route(BuildContext context,
    {NotificationBodyModel? body, bool forceDashboard = false}) {
  // 🚫 GUARD (Bug 2): If splash already routed directly to a cached module,
  // ignore any late `route()` call from SplashScreen safety nets / async
  // callbacks. They must not override the cached-module destination.
  if (_splashRouteFinalized && !forceDashboard) {
    if (kDebugMode) {
      debugPrint(
          '[SPLASH_ROUTE][BLOCK_DUPLICATE_NAV] current=${Get.currentRoute} target=route() reason=route_finalized');
    }
    return;
  }
  // Check if configModel is loaded first
  final splashController = Get.find<SplashController>();
  if (Get.isRegistered<HomeUnifiedController>()) {
    Get.find<HomeUnifiedController>().forceResetLoadingState();
  }
  if (splashController.configModel == null) {
    appLogger.warning(
        'ConfigModel not loaded yet - applying fallback config to prevent stuck splash');
    // 🔧 FIX: Apply fallback config instead of silently returning
    // This prevents the splash screen from getting stuck forever
    splashController.applyFallbackConfig(
        reason: 'route() called with null configModel');
    if (splashController.configModel == null) {
      // If fallback also failed (shouldn't happen), navigate to onboarding as last resort
      appLogger.warning(
          'Fallback config also failed - navigating to language selection');
      Get.offNamed<void>(RouteHelper.getLanguageRoute('splash'));
      return;
    }
  }

  final double? minimumVersion = _getMinimumVersion();
  final bool isMaintenanceMode =
      splashController.configModel!.maintenanceMode ?? false;
  final bool needsUpdate =
      minimumVersion != null && AppConstants.appVersion < minimumVersion;

  if (needsUpdate || isMaintenanceMode) {
    Get.offNamed<void>(
      RouteHelper.getUpdateRoute(needsUpdate),
      arguments: Get.arguments,
    );
  } else if (!GetPlatform.isWeb) {
    if (body != null) {
      _forNotificationRouteProcess(body);
    } else {
      _handleUserRouting(context, forceDashboard: forceDashboard);
    }
  }
}

double? _getMinimumVersion() {
  final splashController = Get.find<SplashController>();
  if (splashController.configModel == null) {
    return null;
  }

  if (GetPlatform.isAndroid) {
    return splashController.configModel!.appMinimumVersionAndroid;
  } else if (GetPlatform.isIOS) {
    return splashController.configModel!.appMinimumVersionIos;
  }
  return 0;
}

void _forNotificationRouteProcess(NotificationBodyModel? notificationBody) {
  final notificationType = notificationBody?.notificationType;

  final Map<NotificationType, VoidCallback> notificationActions = {
    NotificationType.order: () => Get.toNamed<void>(
        RouteHelper.getOrderDetailsRoute(notificationBody!.orderId,
            fromNotification: true)),
    NotificationType.block: () => Get.offNamed<void>(
        RouteHelper.getSignInRoute(RouteHelper.notification)),
    NotificationType.unblock: () => Get.offNamed<void>(
        RouteHelper.getSignInRoute(RouteHelper.notification)),
    NotificationType.message: () => Get.toNamed<void>(RouteHelper.getChatRoute(
        notificationBody: notificationBody,
        conversationID: notificationBody!.conversationId,
        fromNotification: true)),
    NotificationType.otp: () {},
    NotificationType.add_fund: () =>
        Get.toNamed<void>(RouteHelper.getWalletRoute(fromNotification: true)),
    NotificationType.referral_earn: () =>
        Get.toNamed<void>(RouteHelper.getWalletRoute(fromNotification: true)),
    NotificationType.cashback: () =>
        Get.toNamed<void>(RouteHelper.getWalletRoute(fromNotification: true)),
    NotificationType.loyalty_point: () =>
        Get.toNamed<void>(RouteHelper.getLoyaltyRoute(fromNotification: true)),
    NotificationType.general: () => Get.toNamed<void>(
        RouteHelper.getNotificationRoute(fromNotification: true)),
  };

  notificationActions[notificationType]?.call();
}

Future<void> _forLoggedInUserRouteProcess(
  BuildContext context, {
  required bool forceDashboard,
}) async {
  Get.find<AuthController>().updateToken();

  // ⚡ OPTIMIZATION: Allow home screen to render from cache even without GPS fix
  // Check if we have valid cache - if so, render home screen and update location in background
  final hasAddress = AddressHelper.getUserAddressFromSharedPref() != null;
  final hasValidCache = await ComprehensiveHomeCacheManager.isCacheValid();

  if (hasAddress || hasValidCache) {
    // Go directly to home screen - data is already loaded in splash or available in cache
    appLogger.info(
        'Routing logged in user to home screen (hasAddress: $hasAddress, hasValidCache: $hasValidCache)');

    // 🏗️ MODULE-FIRST ARCHITECTURE: Resolve module before routing
    final splashController = Get.find<SplashController>();
    final moduleList = splashController.moduleList;

    // 🔒 BOOTSTRAP PROTECTION: Check for cached module ID FIRST (before resolveInitialModule)
    // If cached module exists, use it and go directly to Home WITHOUT MultiModuleHomeScreen
    final cachedModuleId = await HiveHomeCacheService.getLastSelectedModuleId();

    // 🎯 CRITICAL FIX (Bug 2): If cached module ID is known, route directly to
    // /module/<id> EVEN IF moduleList is not yet populated. We resolve the
    // ModuleModel via local-cache fallback or build a stub if absolutely
    // required. The detour through MultiModuleHomeScreen used to fire here
    // only because moduleList was momentarily null.
    if (cachedModuleId != null) {
      if (kDebugMode) {
        debugPrint('[SPLASH_ROUTE][CACHED_MODULE_FOUND] id=$cachedModuleId');
      }
      final ModuleModel? cachedModule = await _resolveCachedModuleForRouting(
        splashController: splashController,
        cachedModuleId: cachedModuleId,
      );
      if (cachedModule != null && cachedModule.id != null) {
        // Set module synchronously BEFORE the route guard decides anything.
        // This ensures DashboardScreen._buildHomeRoot reads a non-null
        // selectedModule on its very first frame and never falls back to
        // MultiModuleHomeScreen.
        await splashController.setModule(cachedModule, notify: false);
        await _routeDirectlyToModule(cachedModule.id!);
        return; // Exit early – do NOT touch MultiModule or '/' route.
      }
    }

    // Only resolve initial module if no cached module was found
    if (moduleList != null && moduleList.isNotEmpty) {
      await splashController.resolveInitialModule(moduleList);
    }

    // 🏗️ MODULE-FIRST: Route Guard - only navigate to MultiModuleHomeScreen if no module selected
    // This handles cases where resolveInitialModule selected a module (single module scenario)
    final finalSelectedModule = splashController.selectedModule.value;
    if (finalSelectedModule != null && finalSelectedModule.id != null) {
      if (kDebugMode) {
        debugPrint(
            '[SPLASH_ROUTE][DIRECT_TO_MODULE] id=${finalSelectedModule.id} (resolved=auto)');
      }
      await _routeDirectlyToModule(finalSelectedModule.id!);
    } else {
      if (kDebugMode) {
        debugPrint(
            '[SPLASH_ROUTE][MULTI_MODULE_REQUIRED] reason=no_cached_module_and_no_resolved_module');
      }
      _navigateToMultiModuleHomeScreen();
    }

    // ⚡ OPTIMIZATION: Update location in background if no address but cache exists
    if (!hasAddress && hasValidCache) {
      appLogger.info(
          'Updating location in background for logged-in user (cache available, GPS can fix later)');
    }
  } else {
    // No address and no cache - need location before proceeding
    if (!context.mounted) {
      return;
    }
    Get.find<LocationController>()
        .navigateToLocationScreen(context, 'splash', offNamed: true);
  }
}

void _newlyRegisteredRouteProcess() {
  appLogger.info(
      'Newly registered route process - Available languages: ${AppConstants.languages.length}');

  if (AppConstants.languages.length > 1) {
    appLogger
        .info('Multiple languages available, routing to language selection');
    Get.offNamed<void>(RouteHelper.getLanguageRoute('splash'));
  } else {
    appLogger.info('Single language, routing to onboarding');
    Get.offNamed<void>(RouteHelper.getOnBoardingRoute());
  }
}

Future<void> _forGuestUserRouteProcess(
  BuildContext context, {
  required bool forceDashboard,
}) async {
  // ⚡ OPTIMIZATION: Allow home screen to render from cache even without GPS fix
  // Check if we have valid cache - if so, render home screen and update location in background
  final hasAddress = AddressHelper.getUserAddressFromSharedPref() != null;
  final hasValidCache = await ComprehensiveHomeCacheManager.isCacheValid();

  if (hasAddress || hasValidCache) {
    // Go directly to home screen - data is already loaded in splash or available in cache
    appLogger.info(
        'Routing guest user to home screen (hasAddress: $hasAddress, hasValidCache: $hasValidCache)');

    // 🏗️ MODULE-FIRST ARCHITECTURE: Resolve module before routing
    final splashController = Get.find<SplashController>();
    final moduleList = splashController.moduleList;

    // 🔒 BOOTSTRAP PROTECTION: Check for cached module ID FIRST (before resolveInitialModule)
    // If cached module exists, use it and go directly to Home WITHOUT MultiModuleHomeScreen
    final cachedModuleId = await HiveHomeCacheService.getLastSelectedModuleId();

    // 🎯 CRITICAL FIX (Bug 2): cached module path resolved via fallback even
    // if moduleList isn't ready yet. Same logic as the logged-in path.
    if (cachedModuleId != null) {
      if (kDebugMode) {
        debugPrint('[SPLASH_ROUTE][CACHED_MODULE_FOUND] id=$cachedModuleId');
      }
      final ModuleModel? cachedModule = await _resolveCachedModuleForRouting(
        splashController: splashController,
        cachedModuleId: cachedModuleId,
      );
      if (cachedModule != null && cachedModule.id != null) {
        await splashController.setModule(cachedModule, notify: false);
        await _routeDirectlyToModule(cachedModule.id!);
        return;
      }
    }

    // Only resolve initial module if no cached module was found
    if (moduleList != null && moduleList.isNotEmpty) {
      await splashController.resolveInitialModule(moduleList);
    }

    // 🏗️ MODULE-FIRST: Route Guard - only navigate to MultiModuleHomeScreen if no module selected
    final finalSelectedModule = splashController.selectedModule.value;
    if (finalSelectedModule != null && finalSelectedModule.id != null) {
      if (kDebugMode) {
        debugPrint(
            '[SPLASH_ROUTE][DIRECT_TO_MODULE] id=${finalSelectedModule.id} (resolved=auto)');
      }
      await _routeDirectlyToModule(finalSelectedModule.id!);
    } else {
      if (kDebugMode) {
        debugPrint(
            '[SPLASH_ROUTE][MULTI_MODULE_REQUIRED] reason=no_cached_module_and_no_resolved_module');
      }
      _navigateToMultiModuleHomeScreen();
    }

    if (!hasAddress && hasValidCache) {
      appLogger.info(
          'Updating location in background for guest user (cache available, GPS can fix later)');
    }
  } else {
    // No address and no cache - need location before proceeding
    if (!context.mounted) {
      return;
    }
    Get.find<LocationController>()
        .navigateToLocationScreen(context, 'splash', offNamed: true);
  }
}

Future<void> _handleUserRouting(
  BuildContext context, {
  required bool forceDashboard,
}) async {
  final splashController = Get.find<SplashController>();
  final showIntro = splashController.showIntro();
  final authController = Get.find<AuthController>();

  appLogger.info(
      'User routing - isLoggedIn: ${AuthHelper.isLoggedIn()}, showIntro: $showIntro, isGuestLoggedIn: ${AuthHelper.isGuestLoggedIn()}');

  // 🔧 FIX: Check GuestID/Token BEFORE checking showIntro
  // If GuestID or Token exists, never route to onboarding, even if address is missing
  final hasToken =
      AuthHelper.isLoggedIn() && authController.getUserToken().isNotEmpty;
  final hasGuestId =
      AuthHelper.isGuestLoggedIn() && authController.getGuestId().isNotEmpty;

  if (hasToken) {
    appLogger.info('Routing to logged in user flow (token exists)');
    await _forLoggedInUserRouteProcess(context, forceDashboard: forceDashboard);
  } else if (hasGuestId) {
    appLogger.info('Routing to guest user flow (guest ID exists)');
    await _forGuestUserRouteProcess(context, forceDashboard: forceDashboard);
  } else if (showIntro == true) {
    // Only route to onboarding if no token and no guest ID
    appLogger.info(
        'Routing to onboarding flow (language/onboarding) - no token/guest ID');
    _newlyRegisteredRouteProcess();
  } else {
    appLogger.info('No user state, performing guest login');
    await authController.guestLogin();
    if (!context.mounted) return;

    // تأكد إن المستخدم عنده موقع قبل ما يروح للـ Dashboard
    final hasAddress = AddressHelper.getUserAddressFromSharedPref() != null;
    if (!hasAddress) {
      appLogger.info('No address found - routing to location screen');
      Get.find<LocationController>()
          .navigateToLocationScreen(context, 'splash', offNamed: true);
      return;
    }

    await _forGuestUserRouteProcess(context, forceDashboard: forceDashboard);
  }
}
// }
