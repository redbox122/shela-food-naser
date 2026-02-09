import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import 'package:sixam_mart/features/home/screens/multi_module/multi_module_home_screen.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';

// class SplashRouteHelper{

// 🚫 FIX: Prevent double navigation - only route once
bool _hasRoutedFromSplash = false;
bool _isRoutingToHome = false;
DateTime? _lastHomeRouteAt;

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

Future<void> routeToDashboardOnce({bool force = false}) async {
  await _routeToDashboardOnce(force: force);
}

/// 🏗️ MODULE-FIRST ARCHITECTURE: Route Guard
/// After splash screen, always show MultiModuleHomeScreen first for module selection
/// 🚫 FIX: Simplified - directly navigate using Get.offAllNamed to prevent loops
void _navigateToMultiModuleHomeScreen() {
  // 🚫 FIX: Prevent double navigation - only route once
  if (_hasRoutedFromSplash) {
    if (kDebugMode) {
      debugPrint('🏗️ [Module-First] Route Guard: Already routed, skipping duplicate navigation');
    }
    return; // Don't navigate again
  }
  _hasRoutedFromSplash = true;
  
  // 🏗️ MODULE-FIRST: Always show MultiModuleHomeScreen after splash
  // User must select a module before proceeding to Dashboard
  if (kDebugMode) {
    debugPrint('🏗️ [Module-First] Route Guard: Routing to MultiModuleHomeScreen after splash');
  }
  
  // 🚫 FIX: Use Get.offAll() directly with widget to prevent navigation loops
  // This clears the entire navigation stack and navigates directly to MultiModuleHomeScreen
  // ⚠️ CRITICAL: Don't use Get.offAllNamed() with route name because route '/' opens DashboardScreen
  // We must use Get.offAll() with widget directly to bypass route system
  if (kDebugMode) {
    debugPrint('🟥 SPLASH ROUTE EXECUTED at ${DateTime.now()} - Navigating to MultiModuleHomeScreen');
  }
  Get.offAll<dynamic>(
    () => const MultiModuleHomeScreen(),
    transition: Transition.fadeIn,
    duration: const Duration(milliseconds: 300),
  );
}

void route(BuildContext context, {NotificationBodyModel? body, bool forceDashboard = false}) {
  // Check if configModel is loaded first
  final splashController = Get.find<SplashController>();
  if (Get.isRegistered<HomeUnifiedController>()) {
    Get.find<HomeUnifiedController>().forceResetLoadingState();
  }
  if (splashController.configModel == null) {
    appLogger.warning('ConfigModel not loaded yet, skipping route');
    return;
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
    NotificationType.order: () => Get.toNamed<void>(RouteHelper.getOrderDetailsRoute(
        notificationBody!.orderId,
        fromNotification: true)),
    NotificationType.block: () =>
        Get.offNamed<void>(RouteHelper.getSignInRoute(RouteHelper.notification)),
    NotificationType.unblock: () =>
        Get.offNamed<void>(RouteHelper.getSignInRoute(RouteHelper.notification)),
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
    NotificationType.general: () =>
        Get.toNamed<void>(RouteHelper.getNotificationRoute(fromNotification: true)),
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
    appLogger.info('Routing logged in user to home screen (hasAddress: $hasAddress, hasValidCache: $hasValidCache)');
    
    // 🏗️ MODULE-FIRST ARCHITECTURE: Resolve module before routing
    final splashController = Get.find<SplashController>();
    final moduleList = splashController.moduleList;
    
    // 🔒 BOOTSTRAP PROTECTION: Check for cached module ID FIRST (before resolveInitialModule)
    // If cached module exists, use it and go directly to Home WITHOUT MultiModuleHomeScreen
    final cachedModuleId = await HiveHomeCacheService.getLastSelectedModuleId();
    
    // 🎯 CRITICAL FIX: If cached module exists, set it immediately and go to Dashboard
    // This prevents the unnecessary detour to MultiModuleHomeScreen
    if (cachedModuleId != null && moduleList != null && moduleList.isNotEmpty) {
      // Find cached module in module list
      ModuleModel? cachedModule;
      for (final module in moduleList) {
        if (module.id == cachedModuleId) {
          cachedModule = module;
          break;
        }
      }
      
      if (cachedModule != null) {
        // Set module immediately from cache using setModule (which updates both selectedModule and _module)
        await splashController.setModule(
          cachedModule,
          notify: forceDashboard,
        );
        
        if (kDebugMode) {
          debugPrint('🚀 [Module-First] Route Guard: Cached module found (id=$cachedModuleId) - routing directly to Dashboard');
        }
        // Go directly to Dashboard - skip MultiModuleHomeScreen entirely
        await _routeToDashboardOnce(force: forceDashboard);
        return; // Exit early - no need to check anything else
      }
    }
    
    // Only resolve initial module if no cached module was found
    if (moduleList != null && moduleList.isNotEmpty) {
      await splashController.resolveInitialModule(moduleList);
    }
    
    // 🏗️ MODULE-FIRST: Route Guard - only navigate to MultiModuleHomeScreen if no module selected
    // This handles cases where resolveInitialModule selected a module (single module scenario)
    final finalSelectedModule = splashController.selectedModule.value;
    if (finalSelectedModule != null) {
      // Module resolved (single module or auto-selected) - navigate directly to Dashboard
      if (kDebugMode) {
        debugPrint('🏗️ [Module-First] Route Guard: Module resolved (id=${finalSelectedModule.id}) - routing to Dashboard');
      }
      await _routeToDashboardOnce(force: forceDashboard);
    } else {
      // No module selected - show MultiModuleHomeScreen for selection
      if (kDebugMode) {
        debugPrint('🏗️ [Module-First] Route Guard: No module selected - routing to MultiModuleHomeScreen');
      }
      _navigateToMultiModuleHomeScreen();
    }
    
    // ⚡ OPTIMIZATION: Update location in background if no address but cache exists
    if (!hasAddress && hasValidCache) {
      appLogger.info('Updating location in background for logged-in user (cache available, GPS can fix later)');
      // Location will be updated in background when GPS is fixed
      // Home screen can render from cache immediately
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
  appLogger.info('Newly registered route process - Available languages: ${AppConstants.languages.length}');

  if (AppConstants.languages.length > 1) {
    appLogger.info('Multiple languages available, routing to language selection');
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
    appLogger.info('Routing guest user to home screen (hasAddress: $hasAddress, hasValidCache: $hasValidCache)');
    
    // 🏗️ MODULE-FIRST ARCHITECTURE: Resolve module before routing
    final splashController = Get.find<SplashController>();
    final moduleList = splashController.moduleList;
    
    // 🔒 BOOTSTRAP PROTECTION: Check for cached module ID FIRST (before resolveInitialModule)
    // If cached module exists, use it and go directly to Home WITHOUT MultiModuleHomeScreen
    final cachedModuleId = await HiveHomeCacheService.getLastSelectedModuleId();
    
    // 🎯 CRITICAL FIX: If cached module exists, set it immediately and go to Dashboard
    // This prevents the unnecessary detour to MultiModuleHomeScreen
    if (cachedModuleId != null && moduleList != null && moduleList.isNotEmpty) {
      // Find cached module in module list
      ModuleModel? cachedModule;
      for (final module in moduleList) {
        if (module.id == cachedModuleId) {
          cachedModule = module;
          break;
        }
      }
      
      if (cachedModule != null) {
        // Set module immediately from cache using setModule (which updates both selectedModule and _module)
        await splashController.setModule(
          cachedModule,
          notify: forceDashboard,
        );
        
        if (kDebugMode) {
          debugPrint('🚀 [Module-First] Route Guard: Cached module found (id=$cachedModuleId) - routing directly to Dashboard');
        }
        // Go directly to Dashboard - skip MultiModuleHomeScreen entirely
        await _routeToDashboardOnce(force: forceDashboard);
        return; // Exit early - no need to check anything else
      }
    }
    
    // Only resolve initial module if no cached module was found
    if (moduleList != null && moduleList.isNotEmpty) {
      await splashController.resolveInitialModule(moduleList);
    }
    
    // 🏗️ MODULE-FIRST: Route Guard - only navigate to MultiModuleHomeScreen if no module selected
    // This handles cases where resolveInitialModule selected a module (single module scenario)
    final finalSelectedModule = splashController.selectedModule.value;
    if (finalSelectedModule != null) {
      // Module resolved (single module or auto-selected) - navigate directly to Dashboard
      if (kDebugMode) {
        debugPrint('🏗️ [Module-First] Route Guard: Module resolved (id=${finalSelectedModule.id}) - routing to Dashboard');
      }
      await _routeToDashboardOnce(force: forceDashboard);
    } else {
      // No module selected - show MultiModuleHomeScreen for selection
      if (kDebugMode) {
        debugPrint('🏗️ [Module-First] Route Guard: No module selected - routing to MultiModuleHomeScreen');
      }
      _navigateToMultiModuleHomeScreen();
    }
    
    // ⚡ OPTIMIZATION: Update location in background if no address but cache exists
    if (!hasAddress && hasValidCache) {
      appLogger.info('Updating location in background for guest user (cache available, GPS can fix later)');
      // Location will be updated in background when GPS is fixed
      // Home screen can render from cache immediately
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

  appLogger.info('User routing - isLoggedIn: ${AuthHelper.isLoggedIn()}, showIntro: $showIntro, isGuestLoggedIn: ${AuthHelper.isGuestLoggedIn()}');

  // 🔧 FIX: Check GuestID/Token BEFORE checking showIntro
  // If GuestID or Token exists, never route to onboarding, even if address is missing
  final hasToken = AuthHelper.isLoggedIn() && authController.getUserToken().isNotEmpty;
  final hasGuestId = AuthHelper.isGuestLoggedIn() && authController.getGuestId().isNotEmpty;

  if (hasToken) {
    appLogger.info('Routing to logged in user flow (token exists)');
    await _forLoggedInUserRouteProcess(context, forceDashboard: forceDashboard);
  } else if (hasGuestId) {
    appLogger.info('Routing to guest user flow (guest ID exists)');
    await _forGuestUserRouteProcess(context, forceDashboard: forceDashboard);
  } else if (showIntro == true) {
    // Only route to onboarding if no token and no guest ID
    appLogger.info('Routing to onboarding flow (language/onboarding) - no token/guest ID');
    _newlyRegisteredRouteProcess();
  } else {
    appLogger.info('No user state, performing guest login');
    await authController.guestLogin();
    if (!context.mounted) {
      return;
    }
    await _forGuestUserRouteProcess(context, forceDashboard: forceDashboard);
  }
}
// }
