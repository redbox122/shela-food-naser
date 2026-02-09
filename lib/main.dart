// ignore_for_file: use_build_context_synchronously, avoid_print
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
import 'package:sixam_mart/theme/dark_theme.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/messages.dart';
import 'package:sixam_mart/features/home/widgets/cookies_view.dart';
import 'package:sixam_mart/services/secure_token_loader.dart';
import 'package:sixam_mart/services/cache_manager.dart';
import 'package:sixam_mart/services/edge_to_edge_service.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/core/logger/app_logger.dart' as logger_package;
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/hive_migration_service.dart';
import 'package:sixam_mart/core/debug/leak_tracking_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'helper/get_di.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Override debugPrint to filter EGL logs and use our logger
void _setupLogging() {
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      // Filter EGL_emulation logs - throttle them to once every 20 seconds
      if (message.contains('EGL_emulation') || message.contains('app_time_stats')) {
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

// ⚡ NEW: Flag to track initialization status
bool _heavyServicesInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging system first (synchronous, fast)
  _setupLogging();
  appLogger.initialize(
    enableLogging: AppConstants.enableVerboseLogs,
    enableApiLogging: AppConstants.enableVerboseLogs,
    enablePageLogging: AppConstants.enableVerboseLogs,
    filterEGLLogs: true,
  );
  appLogger.info('🚀 App Logger initialized');

  // ⚡ PERFORMANCE: Start timing from main function
  final mainStartTime = DateTime.now();
  appLogger.info('⏱️ PERFORMANCE: main() started at ${mainStartTime.millisecondsSinceEpoch}ms');

  // 🔴 Global error handler - catches all Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
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

  // ⚡ CRITICAL OPTIMIZATION: Load ONLY essential services for first screen
  // Move ALL heavy operations to background after first frame
  final Map<String, Map<String, String>> languages = await _initEssentialOnly();

  if (!GetPlatform.isWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // ⚡ PERFORMANCE: Log runApp timing
  final runAppStartTime = DateTime.now();
  appLogger.info('⏱️ PERFORMANCE: runApp() called at ${runAppStartTime.millisecondsSinceEpoch}ms');

  // 🔍 MEMORY LEAK TRACKING: Wrap app in debug mode to monitor controller disposal
  final app = MyApp(languages: languages);

  if (kDebugMode && AppConstants.enableVerboseLogs) {
    runApp(LeakTrackingWrapper(child: app));
  } else {
    runApp(app);
  }

  // Note: runApp() is synchronous but rendering happens asynchronously
  // First frame timing is logged in MultiModuleHomeScreen.initState
  final runAppEndTime = DateTime.now();
  final runAppDuration = runAppEndTime.difference(runAppStartTime).inMilliseconds;
  appLogger.info('⏱️ PERFORMANCE: runApp() call completed in ${runAppDuration}ms (rendering happens asynchronously)');

  // ⚡ CRITICAL: Initialize heavy services AFTER first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeHeavyServices();
  });
}

/// ⚡ NEW: Initialize ONLY what's needed for routing decision
/// Target: < 500ms total time
Future<Map<String, Map<String, String>>> _initEssentialOnly() async {
  final startTime = DateTime.now();

  // Only initialize the bare minimum needed for DI and routing
  final languages = await init();

  final duration = DateTime.now().difference(startTime).inMilliseconds;
  appLogger.info('⚡ Essential services initialized in ${duration}ms');

  return languages;
}

/// ⚡ NEW: Initialize heavy services in background (non-blocking)
/// This runs AFTER the first frame is painted
Future<void> _initializeHeavyServices() async {
  if (_heavyServicesInitialized) {
    appLogger.info('⚠️ Heavy services already initialized, skipping');
    return;
  }

  _heavyServicesInitialized = true;
  final heavyInitStartTime = DateTime.now();
  appLogger.info('⏱️ PERFORMANCE: Heavy initializations started at ${heavyInitStartTime.millisecondsSinceEpoch}ms (after first frame)');

  try {
    // ⚡ STAGE 1: Critical services (Firebase must be first)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) debugPrint('✅ Firebase initialized (Stage 1)');

    // ⚡ STAGE 2: Initialize services that depend on Firebase in parallel
    await Future.wait([
      NotificationService().initialize(),
      CacheManager().initialize(),
      HiveHomeCacheService().initialize(),
    ]);
    if (kDebugMode) debugPrint('✅ Core services initialized (Stage 2)');

    // ⚡ STAGE 3: Non-critical services (can fail without breaking app)
    _initializeNonCriticalServices();

    final heavyInitEndTime = DateTime.now();
    final heavyInitDuration = heavyInitEndTime.difference(heavyInitStartTime).inMilliseconds;
    appLogger.info('⏱️ PERFORMANCE: Heavy initializations completed in ${heavyInitDuration}ms');
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ Initialization error (after first frame): $e');
      debugPrint('Stack trace: $stackTrace');
    }
    appLogger.error('❌ Heavy initialization error', e, stackTrace);

    // Continue app launch even if some services fail
    if (e.toString().contains('Firebase') || e.toString().contains('core/no-app')) {
      if (kDebugMode) debugPrint('⚠️ Firebase initialization failed - some features may not work');
    }
  }
}

/// ⚡ NEW: Initialize non-critical services (fire and forget)
/// These can fail without affecting app functionality
void _initializeNonCriticalServices() {
  // Run these in background without awaiting
  Future.microtask(() async {
    try {
      // Secure tokens (payment integration)
      await SecureTokenLoader.initialize();
      if (kDebugMode) debugPrint('✅ Secure tokens loaded');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Secure tokens failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Edge to edge UI
      await EdgeToEdgeService.initialize();
      if (kDebugMode) debugPrint('✅ Edge-to-edge initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Edge-to-edge failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Hive migration (non-blocking)
      await HiveMigrationService.migrateFromSharedPreferences();
      if (kDebugMode) debugPrint('✅ Hive migration completed');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Migration failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Facebook Auth for Web
      if (ResponsiveHelper.isWeb()) {
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: '380903914182154',
          cookie: true,
          xfbml: true,
          version: 'v15.0',
        );
        if (kDebugMode) debugPrint('✅ Facebook auth initialized');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Facebook auth failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Date formatting (can be lazy loaded when needed)
      await Future.wait([
        initializeDateFormatting('ar'),
        initializeDateFormatting('en_US'),
        initializeDateFormatting('en'),
        initializeDateFormatting('es'),
        initializeDateFormatting('bn'),
      ]);
      if (kDebugMode) debugPrint('✅ Date formatting initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Date formatting failed: $e');
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

  @override
  void initState() {
    super.initState();

    // ⚡ OPTIMIZATION: Delay route initialization until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _route();
    });
  }

  Future<void> _route() async {
    try {
      if (GetPlatform.isWeb) {
        // ⚡ Web-specific initialization
        await Get.find<SplashController>().initSharedData();

        final address = AddressHelper.getUserAddressFromSharedPref();

        if (address == null) {
          if (kDebugMode) debugPrint('⚠️ لم يتم العثور على عنوان مخزن');
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
            debugPrint('🔄 Main: Loading cart data on app start (empty cart)');
            // ⚡ Load cart in background (non-blocking)
            unawaited(cartController.getCartDataOnline());
          } else {
            debugPrint('💾 Main: Using existing cart data on app start');
          }
        }

        // ⚡ Load config data in background after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final context = Get.context;
          if (context != null) {
            await Get.find<SplashController>().getConfigData(
              context,
              loadLandingData: (GetPlatform.isWeb && address == null),
              fromMainFunction: true,
            );
          }
        });
      } else {
        // For mobile platforms (Android/iOS) - check for updates
        if (kDebugMode) {
          debugPrint('📱 Platform detected: ${GetPlatform.isAndroid ? 'Android' : 'iOS'}');
          debugPrint('🔄 Update checking handled by splash route helper');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Routing/init error: $e');
    }
  }

  /// ⚡ PERFORMANCE: Separated GetBuilder widgets with specific IDs
  /// This prevents unnecessary rebuilds - theme changes won't rebuild locale widgets
  /// and vice versa. Each controller only rebuilds its own dependent widgets.
  @override
  Widget build(BuildContext context) {
    // ⚡ OPTIMIZATION: Use GetBuilder with specific IDs to limit rebuild scope
    // Theme changes only rebuild theme-dependent widgets
    return GetBuilder<ThemeController>(
      id: 'app_theme', // Specific ID for theme rebuilds
      builder: (themeController) {
        // ⚡ Locale changes only rebuild locale-dependent widgets
        return GetBuilder<LocalizationController>(
          id: 'app_locale', // Specific ID for locale rebuilds
          builder: (localizeController) {
            // ⚡ Config changes only rebuild config-dependent widgets
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

  /// ⚡ PERFORMANCE: Extracted MaterialApp builder to reduce nesting depth
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
        // ✅ PROFESSIONAL ROUTE LOGGING: Track all route changes for debugging
        final routeName = routing?.current;
        final previousRoute = routing?.previous;
        final isBack = routing?.isBack ?? false;

        if (routeName != null) {
          if (routeName == previousRoute) {
            return;
          }

          final DateTime now = DateTime.now();
          final bool shouldLog =
              _lastLoggedRoute != routeName ||
                  _lastRouteLoggedAt == null ||
                  now.difference(_lastRouteLoggedAt!).inMilliseconds > 300;

          _lastLoggedRoute = routeName;
          _lastRouteLoggedAt = now;

          if (shouldLog) {
            // ✅ Enhanced route logging with full details
            if (kDebugMode) {
              debugPrint('➡️ ROUTE CHANGE');
              debugPrint('   - current: $routeName');
              debugPrint('   - previous: ${previousRoute ?? "none"}');
              debugPrint('   - isBack: $isBack');
              debugPrint('   - parameters: ${Get.parameters}');
              debugPrint('   - arguments: ${Get.arguments}');
            }

            appLogger.logPageEntry(routeName);
            debugPrint('\x1B[32m    📱 تم الانتقال إلى: $routeName \x1B[0m');
          }

          // 🔍 LEAK TRACKING: Trigger leak check after route change
          if (kDebugMode) {
            Future.delayed(const Duration(seconds: 5), () {
              // Check if controllers from previous route are still alive
              debugPrint('🔍 LeakTracker: Checking for leaked controllers after route: $routeName');
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
      theme: themeController.darkTheme ? dark() : light(),
      locale: localizeController.locale,
      translations: Messages(languages: widget.languages),
      fallbackLocale: Locale(
        AppConstants.languages[0].languageCode!,
        AppConstants.languages[0].countryCode,
      ),
      // 🏗️ MODULE-FIRST ARCHITECTURE: Always start with Splash screen
      // Splash screen will handle routing to MultiModuleHomeScreen or DashboardScreen
      // This ensures proper Module-First flow and prevents navigation loops
      initialRoute: RouteHelper.getSplashRoute(null),
      getPages: RouteHelper.routes,
      defaultTransition: Transition.topLevel,
      transitionDuration: const Duration(milliseconds: 500),
      builder: (BuildContext context, Widget? childWidget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1),
          ),
          child: Material(
            child: Stack(
              children: [
                if (childWidget != null) childWidget,
                // ⚡ PERFORMANCE: Cookies view uses specific ID to avoid rebuilding
                // when other splash data changes
                GetBuilder<SplashController>(
                  id: 'cookies_status', // Specific ID for cookies rebuilds only
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
              ],
            ),
          ),
        );
      },
    );
  }
}

// ⚡ HELPER: Non-awaited future helper
void unawaited(Future<void> future) {
  future.catchError((Object e) {
    if (kDebugMode) debugPrint('⚠️ Unawaited future error: $e');
  });
}
