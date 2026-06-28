import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/helper/firebase/firebase_options.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/firebase/my_notification_service.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/messages.dart';
import 'package:sixam_mart/features/home/widgets/cookies_view.dart';
import 'package:sixam_mart/services/secure_token_loader.dart';
import 'package:sixam_mart/services/cache_manager.dart';
import 'package:sixam_mart/services/edge_to_edge_service.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/security/certificate_pinning.dart';
import 'package:sixam_mart/common/widgets/global_sticky_cart_overlay.dart';
import 'package:sixam_mart/core/logger/app_logger.dart' as logger_package;
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/hive_migration_service.dart';
import 'package:sixam_mart/core/cache/app_upgrade_cache_migration.dart';
import 'package:sixam_mart/core/debug/leak_tracking_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'helper/get_di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/auth/helper/qr_referral_install_referrer_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Override debugPrint to filter EGL logs and use our loggerrrr
void _setupLogging() {
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      // Filter EGL_emulation logs - throttle them to once every 20 seconds
      if (message.contains('EGL_emulation') ||
          message.contains('app_time_stats')) {
        // Use logger to handle throttling - only show if not throttled
        if (!appLogger.shouldThrottleLog('EGL_emulation')) {
          // Log throttled message summary instead of individual logs
          originalDebugPrint(message, wrapWidth: wrapWidth);
        }
        return;
      }
    }
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };
}

// âš¡ NEW: Flag to track initialization status
bool _heavyServicesInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ⚡ Background handler registration moved to _initializeHeavyServices()
  // after Firebase.initializeApp() to avoid "duplicate background isolate" warning

  // Initialize logging system first (synchronous, fast)
  _setupLogging();
  appLogger.initialize(
    enableLogging: AppConstants.enableVerboseLogs,
    enableApiLogging: AppConstants.enableVerboseLogs,
    enablePageLogging: AppConstants.enableVerboseLogs,
    filterEGLLogs: true,
  );
  if (kDebugMode) debugPrint('[APP_BASE_URL] ${AppConstants.baseUrl}');
  appLogger.info('ðŸš€ App Logger initialized');

  // âš¡ PERFORMANCE: Start timing from main function
  final mainStartTime = DateTime.now();
  appLogger.info(
      'â±ï¸ PERFORMANCE: main() started at ${mainStartTime.millisecondsSinceEpoch}ms');

  // ðŸ”´ Global error handler - catches all Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Suppress PathNotFoundException from image cache (orphaned file refs
    // that cached_network_image surfaces after OS clears the cache dir).
    if (details.exception is PathNotFoundException) {
      final String pathStr =
          (details.exception as PathNotFoundException).path ?? '';
      if (pathStr.contains('libCachedImageData')) {
        if (kDebugMode) {
          debugPrint(
              '🗑️ Suppressed image cache PathNotFoundException: $pathStr');
        }
        return; // swallow — errorWidget in CustomImage handles the UI
      }
    }
    // 🔎 TEMP DIAGNOSTIC: surface the offending widget + creation location for
    // layout overflow errors (remove after diagnosing).
    if (kDebugMode &&
        details.exception.toString().contains('overflowed')) {
      FlutterError.presentError(details);
    }
    logger_package.logger.e(
      "Flutter Error: ${details.exception}",
      error: details.exception,
      stackTrace: details.stack,
    );
    // Also log to appLogger for consistency
    appLogger.error(
      "Flutter Error: ${details.exception}",
      details.exception,
      details.stack,
    );
  };

  // TLS certificate pinning bootstrap. No-op while the flag is OFF (default).
  // When ON it loads the pinned CA assets and fails clearly here if they are
  // missing — before any network request is made.
  await CertificatePinning.init();

  // âš¡ CRITICAL OPTIMIZATION: Load ONLY essential services for first screen
  // Move ALL heavy operations to background after first frame
  final Map<String, Map<String, String>> languages = await _initEssentialOnly();

  // Date formatting must be ready before any UI calls DateFormat().
  await _initializeCriticalDateFormatting();

  if (!GetPlatform.isWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // âš¡ PERFORMANCE: Log runApp timing
  final runAppStartTime = DateTime.now();
  appLogger.info(
      'â±ï¸ PERFORMANCE: runApp() called at ${runAppStartTime.millisecondsSinceEpoch}ms');

  // ðŸ” MEMORY LEAK TRACKING: Wrap app in debug mode to monitor controller disposal
  final app = MyApp(languages: languages);

  if (kDebugMode && AppConstants.enableVerboseLogs) {
    runApp(LeakTrackingWrapper(child: app));
  } else {
    runApp(app);
  }

  // Note: runApp() is synchronous but rendering happens asynchronously
  // First frame timing is logged in MultiModuleHomeScreen.initState
  final runAppEndTime = DateTime.now();
  final runAppDuration =
      runAppEndTime.difference(runAppStartTime).inMilliseconds;
  appLogger.info(
      'â±ï¸ PERFORMANCE: runApp() call completed in ${runAppDuration}ms (rendering happens asynchronously)');

  // âš¡ CRITICAL: Initialize heavy services AFTER first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      _initializeHeavyServices();
    });
  });
}

Future<void> _initializeCriticalDateFormatting() async {
  final Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

  final Set<String> locales = <String>{
    'ar',
    'en',
    'en_US',
    'es',
    'bn',
    deviceLocale.toString(),
    deviceLocale.languageCode,
  }..removeWhere((value) => value.trim().isEmpty);

  await Future.wait(
    locales.map((locale) async {
      try {
        await initializeDateFormatting(locale);
      } catch (_) {
        // Ignore unsupported locale aliases and keep app startup resilient.
      }
    }),
  );
}

/// ⚡ NEW: Initialize ONLY what's needed for routing decision
/// Target: < 500ms total time
Future<Map<String, Map<String, String>>> _initEssentialOnly() async {
  final startTime = DateTime.now();

  // Only initialize the bare minimum needed for DI and routing
  final languages = await init();

  // 🔄 APP UPGRADE: The first launch after an APK upgrade must clear stale
  // layout/home cache (cached module selection, config, module list, home data)
  // BEFORE any config/module is read, so the new design loads exactly like a
  // fresh install. Auth token and saved address are preserved. No-op (single
  // SharedPreferences read) on every normal launch once the version is recorded.
  await AppUpgradeCacheMigration.runIfUpgraded();

  unawaited(
    QrReferralInstallReferrerService.captureFromInstallReferrer(
      Get.find<SharedPreferences>(),
    ),
  );

  final duration = DateTime.now().difference(startTime).inMilliseconds;
  appLogger.info('âš¡ Essential services initialized in ${duration}ms');

  return languages;
}

/// âš¡ NEW: Initialize heavy services in background (non-blocking)
/// This runs AFTER the first frame is painted
Future<void> _initializeHeavyServices() async {
  if (_heavyServicesInitialized) {
    appLogger.info('âš ï¸ Heavy services already initialized, skipping');
    return;
  }

  _heavyServicesInitialized = true;
  final heavyInitStartTime = DateTime.now();
  appLogger.info(
      'â±ï¸ PERFORMANCE: Heavy initializations started at ${heavyInitStartTime.millisecondsSinceEpoch}ms (after first frame)');

  try {
    // âš¡ STAGE 1: Critical services (Firebase must be first)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) debugPrint('âœ… Firebase initialized (Stage 1)');
    // ✅ Register background handler AFTER Firebase is initialized
    // Prevents "duplicate background isolate" warning that occurs when
    // registration happens before Firebase is ready and a stale native
    // isolate from a previous run still exists.
    try {
      NotificationService.registerBackgroundHandlerOnce();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Background handler registration note: $e');
    }
    // âš¡ STAGE 2: Stagger heavy service init to reduce frame drops on splash/onboarding
    await CacheManager().initialize();
    await HiveHomeCacheService().initialize();
    if (kDebugMode) debugPrint('âœ… Core cache services initialized (Stage 2)');

    unawaited(NotificationService().initialize());
    if (kDebugMode) {
      debugPrint('âœ… Notification service init queued (non-blocking Stage 2)');
    }

    // âš¡ STAGE 3: Non-critical services (can fail without breaking app)
    _initializeNonCriticalServices();

    final heavyInitEndTime = DateTime.now();
    final heavyInitDuration =
        heavyInitEndTime.difference(heavyInitStartTime).inMilliseconds;
    appLogger.info(
        'â±ï¸ PERFORMANCE: Heavy initializations completed in ${heavyInitDuration}ms');
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('âŒ Initialization error (after first frame): $e');
      debugPrint('Stack trace: $stackTrace');
    }
    appLogger.error('âŒ Heavy initialization error', e, stackTrace);

    // App continues — non-critical services unavailable
  }
}

/// âš¡ NEW: Initialize non-critical services (fire and forget)
/// These can fail without affecting app functionality
void _initializeNonCriticalServices() {
  // Run these in background without awaiting
  Future.microtask(() async {
    try {
      // Secure tokens (payment integration)
      await SecureTokenLoader.initialize();
      if (kDebugMode) debugPrint('âœ… Secure tokens loaded');
    } catch (e) {
      if (kDebugMode) debugPrint('âš ï¸ Secure tokens failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Edge to edge UI
      await EdgeToEdgeService.initialize();
      if (kDebugMode) debugPrint('âœ… Edge-to-edge initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('âš ï¸ Edge-to-edge failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Hive migration (non-blocking)
      await HiveMigrationService.migrateFromSharedPreferences();
      if (kDebugMode) debugPrint('âœ… Hive migration completed');
    } catch (e) {
      if (kDebugMode) debugPrint('âš ï¸ Migration failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Facebook Auth for Web
      if (ResponsiveHelper.isWeb()) {
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: AppConstants.facebookAppId,
          cookie: true,
          xfbml: true,
          version: 'v15.0',
        );
        if (kDebugMode) debugPrint('âœ… Facebook auth initialized');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('âš ï¸ Facebook auth failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Date formatting is initialized before runApp.
      if (kDebugMode) debugPrint('âœ… Date formatting already initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('âš ï¸ Date formatting failed: $e');
    }
  });
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>>? languages;

  const MyApp({super.key, required this.languages});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _lastLoggedRoute;
  DateTime? _lastRouteLoggedAt;
  BuildContext? _appContext; // ðŸ”§ FIX: Store context from build method

  @override
  void initState() {
    super.initState();

    // âš¡ OPTIMIZATION: Delay route initialization until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _route();
    });
  }

  Future<void> _route() async {
    try {
      if (GetPlatform.isWeb) {
        // âš¡ Web-specific initialization
        await Get.find<SplashController>().initSharedData();

        final address = AddressHelper.getUserAddressFromSharedPref();

        if (address == null) {
          if (kDebugMode) {
            debugPrint(
                'âš ï¸ Ù„Ù… ÙŠØªÙ… Ø§Ù„Ø¹Ø«ÙˆØ± Ø¹Ù„Ù‰ Ø¹Ù†ÙˆØ§Ù† Ù…Ø®Ø²Ù†');
          }
        } else if (address.zoneIds == null) {
          Get.find<AuthController>().clearSharedAddress();
        }

        if (!AuthHelper.isLoggedIn() && !AuthHelper.isGuestLoggedIn()) {
          await Get.find<AuthController>().guestLogin();
        }

        if ((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) &&
            Get.find<SplashController>().cacheModule != null) {
          // Only load cart data if not already loaded
          final cartController = Get.find<CartController>();
          if (cartController.cartList.isEmpty) {
            debugPrint(
                'ðŸ”„ Main: Loading cart data on app start (empty cart)');
            // âš¡ Load cart in background (non-blocking)
            unawaited(cartController.getCartDataOnline());
          } else {
            debugPrint('ðŸ’¾ Main: Using existing cart data on app start');
          }
        }

        // âš¡ Load config data will be called from routingCallback when GetMaterialApp is ready
        // This ensures context is available and GetMaterialApp is fully initialized
        if (kDebugMode) {
          debugPrint(
              'ðŸŒ Web: getConfigData will be called from routingCallback when app is ready');
        }
      } else {
        // For mobile platforms (Android/iOS) - check for updates
        if (kDebugMode) {
          debugPrint(
              'ðŸ“± Platform detected: ${GetPlatform.isAndroid ? 'Android' : 'iOS'}');
          debugPrint('ðŸ”„ Update checking handled by splash route helper');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ðŸ”¥ Routing/init error: $e');
    }
  }

  /// âš¡ PERFORMANCE: Separated GetBuilder widgets with specific IDs
  /// This prevents unnecessary rebuilds - theme changes won't rebuild locale widgets
  /// and vice versa. Each controller only rebuilds its own dependent widgets.
  @override
  Widget build(BuildContext context) {
    // âš¡ OPTIMIZATION: Use GetBuilder with specific IDs to limit rebuild scope
    // Theme changes only rebuild theme-dependent widgets
    return GetBuilder<ThemeController>(
      id: 'app_theme', // Specific ID for theme rebuilds
      builder: (themeController) {
        // âš¡ Locale changes only rebuild locale-dependent widgets
        return GetBuilder<LocalizationController>(
          id: 'app_locale', // Specific ID for locale rebuilds
          builder: (localizeController) {
            // âš¡ Config changes only rebuild config-dependent widgets
            return GetBuilder<SplashController>(
              id: 'app_config', // Specific ID for config rebuilds
              builder: (splashController) {
                return _buildMaterialApp(
                  themeController: themeController,
                  localizeController: localizeController,
                  splashController: splashController,
                );
              },
            );
          },
        );
      },
    );
  }

  /// âš¡ PERFORMANCE: Extracted MaterialApp builder to reduce nesting depth
  /// and improve code readability
  Widget _buildMaterialApp({
    required ThemeController themeController,
    required LocalizationController localizeController,
    required SplashController splashController,
  }) {
    final configModel = splashController.configModel;

    if (GetPlatform.isWeb && configModel == null) {
      return const SizedBox();
    }

    return GetMaterialApp(
      enableLog: false, // Disable GetX verbose logging
      routingCallback: (routing) {
        // ðŸ”§ FIX: On web, call getConfigData when first route is ready
        if (GetPlatform.isWeb &&
            routing?.current != null &&
            _appContext != null) {
          final context = _appContext;
          if (context != null && context.mounted) {
            // Only call once when app first loads
            if (splashController.configModel == null) {
              if (kDebugMode) {
                debugPrint(
                    'ðŸŒ Web: Calling getConfigData from routingCallback');
              }
              Get.find<SplashController>().getConfigData(
                context,
                loadLandingData: (GetPlatform.isWeb &&
                    AddressHelper.getUserAddressFromSharedPref() == null),
                fromMainFunction: true,
                shouldRoute: true,
              );
            }
          }
        }

        // âœ… PROFESSIONAL ROUTE LOGGING: Track all route changes for debugging
        final routeName = routing?.current;
        final previousRoute = routing?.previous;
        final isBack = routing?.isBack ?? false;

        StickyCartNavSession.syncRoutingCurrentFromGetCallback(routeName);
        syncStickyCartOverlayCartRouteFlagFromRouteName(routeName);

        if (routeName != null && routeName.trim().isNotEmpty) {
          if (routeName == previousRoute) {
            return;
          }

          final DateTime now = DateTime.now();
          final bool shouldLog = _lastLoggedRoute != routeName ||
              _lastRouteLoggedAt == null ||
              now.difference(_lastRouteLoggedAt!).inMilliseconds > 300;

          _lastLoggedRoute = routeName;
          _lastRouteLoggedAt = now;

          if (shouldLog) {
            // âœ… Enhanced route logging with full details
            if (kDebugMode) {
              debugPrint('âž¡ï¸ ROUTE CHANGE');
              debugPrint('   - current: $routeName');
              debugPrint('   - previous: ${previousRoute ?? "none"}');
              debugPrint('   - isBack: $isBack');
              debugPrint('   - parameters: ${Get.parameters}');
              debugPrint('   - arguments: ${Get.arguments}');
            }

            appLogger.logPageEntry(routeName);
            debugPrint('📱 تم الانتقال إلى: $routeName');
          }

          bumpStickyCartRouteTick();

          // ðŸ” LEAK TRACKING: Trigger leak check after route change
          if (kDebugMode) {
            Future.delayed(const Duration(seconds: 5), () {
              // Check if controllers from previous route are still alive
              debugPrint(
                  'ðŸ” LeakTracker: Checking for leaked controllers after route: $routeName');
            });
          }
        }
      },
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: Get.key,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),
      // Dark mode removed — always use the light theme.
      theme: light(),
      locale: localizeController.locale,
      translations: Messages(languages: widget.languages),
      fallbackLocale: Locale(
        AppConstants.languages[0].languageCode!,
        AppConstants.languages[0].countryCode,
      ),
      // ðŸ—ï¸ MODULE-FIRST ARCHITECTURE: Always start with Splash screen
      // Splash screen will handle routing to MultiModuleHomeScreen or DashboardScreen
      // This ensures proper Module-First flow and prevents navigation loops
      initialRoute: RouteHelper.getSplashRoute(null),
      getPages: RouteHelper.routes,
      defaultTransition: Transition.topLevel,
      transitionDuration: const Duration(milliseconds: 500),
      navigatorObservers: <NavigatorObserver>[
        stickyCartNavigatorObserver,
        cartRouteObserverForStickyOverlay,
      ],
      // Navigator + global overlays must live inside this builder (not outside
      // GetMaterialApp) so they share the same element tree, MediaQuery, and theme.
      builder: (BuildContext context, Widget? child) {
        final TextDirection textDirection =
            localizeController.isLtr ? TextDirection.ltr : TextDirection.rtl;
        final Widget navigatorChild = child ?? const SizedBox.shrink();
        return Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1),
            ),
            child: Material(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fill(child: navigatorChild),
                  // âš¡ PERFORMANCE: Cookies view uses specific ID to avoid rebuilding
                  // when other splash data changes
                  GetBuilder<SplashController>(
                    id: 'cookies_status',
                    builder: (splashController) {
                      final showCookies = !splashController.savedCookiesData &&
                          !splashController.getAcceptCookiesStatus(
                              splashController.configModel?.cookiesText ?? '');

                      if (showCookies && ResponsiveHelper.isWeb()) {
                        return const Align(
                          alignment: Alignment.bottomCenter,
                          child: CookiesView(),
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                  // 🎨 REDESIGN: floating cart button removed — the cart count
                  // now shows as a badge on the bottom nav bar.
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// âš¡ HELPER: Non-awaited future helper
void unawaited(Future<void> future) {
  future.catchError((Object e) {
    if (kDebugMode) debugPrint('âš ï¸ Unawaited future error: $e');
  });
}
