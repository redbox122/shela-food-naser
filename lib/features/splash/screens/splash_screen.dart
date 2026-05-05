import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/no_internet_screen.dart';
import 'package:sixam_mart/common/cache/cached_splash_loader.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/features/home/controllers/optimized_home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/helper/splash_route_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? body;
  const SplashScreen({super.key, required this.body});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  bool _hasInitiatedRouting = false;
  bool _hasNavigatedAway = false;
  Timer? _safetyNetTimer;

  @override
  void initState() {
    super.initState();

    // Safety net: keep as a last-resort fallback only.
    // Do not force fallback navigation aggressively while startup is progressing.
    _safetyNetTimer = Timer(const Duration(seconds: 14), () {
      if (!_hasNavigatedAway && mounted) {
        final splashController = Get.find<SplashController>();
        if (splashController.isSplashCacheReady) {
          debugPrint(
              '🛟 SplashScreen SAFETY NET: Safety net skipped because cacheReady=true');
          debugPrint('🚀 SplashScreen: First navigation released');
          _hasNavigatedAway = true;
          splashController.markFirstNavigationReleased();
          splashController.markSplashFlowStopped();
          route(context, body: widget.body);
          return;
        }
        _hasNavigatedAway = true;
        final bool hasMinimumStartupData =
            splashController.moduleList != null &&
                splashController.moduleList!.isNotEmpty &&
                splashController.configModel != null;
        if (hasMinimumStartupData) {
          debugPrint(
              '🛟 SplashScreen SAFETY NET: startup data ready after extended wait - routing without fallback');
        } else {
          debugPrint(
              '🚨 SplashScreen SAFETY NET: startup still not ready after 14s - forcing fallback navigation');
          splashController.applyFallbackConfig(
              reason: 'safety-net timer (14s)');
        }
        debugPrint('🚀 SplashScreen: First navigation released');
        splashController.markFirstNavigationReleased();
        splashController.markSplashFlowStopped();
        route(context, body: widget.body);
      }
    });

    // Don't start stopwatch here - wait for logo to actually render
    // This ensures we count from when the GIF animation actually starts

    bool firstTime = true;
    _onConnectivityChanged = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) async {
      final bool isConnected = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);

      // Only handle connectivity changes after initial splash loading is complete
      if (!firstTime) {
        isConnected
            ? ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar()
            : const SizedBox();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 2 : 5000),
          content: Text(isConnected ? 'connected'.tr : 'no_connection'.tr,
              textAlign: TextAlign.center),
        ));
        if (isConnected && !_hasInitiatedRouting) {
          debugPrint(
              '🔄 SplashScreen: Connectivity restored, refreshing data...');
          if (!mounted) {
            return;
          }
          CachedSplashLoader.loadSplashData(
            context,
            notificationBody: widget.body,
            loadModuleData: true,
            forceRefresh: true,
          );
        }
      }
      firstTime = false;
    });

    // Initialize shared data FIRST to ensure showIntro() works correctly
    final splashController = Get.find<SplashController>();
    splashController.markSplashFlowActive();
    splashController.initSharedData();

    // ✅ OPTIMIZATION: Removed premature API calls
    // Previously called:
    // - HomeController.getBusiness_Settings() → caused /api/v1/business-settings/mobile-app-home-screen-setup
    // - OffersController.getOffers() → caused /api/v1/offers/active
    // - CartController.getCartDataOnline() → caused /api/v1/customer/cart/list
    //
    // These should NOT be called on splash screen because:
    // 1. User hasn't selected a module yet
    // 2. Data is not needed until user navigates to specific screens
    // 3. Causes unnecessary API calls and slows down startup
    //
    // ✅ These will be loaded LAZILY when user navigates to:
    // - Module home screen → loads business settings, offers
    // - Cart screen → loads cart data
    // This reduces startup API calls from 13+ to ~2-3

    // Use cached splash loader for instant startup
    // ⚡ PERF FIX: Reduced from 500ms to 50ms. The original 500ms was pure
    // dead time before any API call. 50ms is enough for the event loop to
    // schedule the logo frame render.
    Future.delayed(const Duration(milliseconds: 50), () async {
      // Prevent multiple routing calls
      if (_hasInitiatedRouting) {
        debugPrint(
            '🚫 SplashScreen: Routing already initiated, skipping duplicate call');
        return;
      }

      _hasInitiatedRouting = true;
      debugPrint('🚀 SplashScreen: Starting initial splash loading...');

      // Load splash data (config, modules list) - this is needed for routing decision
      final BuildContext buildContext = context;
      if (!buildContext.mounted) {
        return;
      }
      await CachedSplashLoader.loadSplashData(
        buildContext,
        notificationBody: widget.body,
        loadModuleData: true,
        allowBackgroundRefresh: false,
      );
      if (!buildContext.mounted) {
        return;
      }

      // ⚡ PERF FIX: Yield to let GIF animation frames render after heavy cache loading
      await Future<void>.delayed(Duration.zero);

      // 🏗️ MODULE-FIRST ARCHITECTURE: Resolve initial module selection
      // This determines which module should be selected based on cache, single module, or user choice
      final splashController = Get.find<SplashController>();
      final moduleList = splashController.moduleList;
      final moduleListLength = moduleList?.length ?? 0;

      if (moduleList != null && moduleListLength > 0) {
        // Resolve initial module (checks cache, auto-selects if single, or leaves null for user choice)
        final moduleResolved =
            await splashController.resolveInitialModule(moduleList);

        if (kDebugMode) {
          if (moduleResolved) {
            debugPrint(
                '✅ SplashScreen: Module resolved (id=${splashController.selectedModule.value?.id})');
          } else {
            debugPrint(
                '🔄 SplashScreen: Module selection required - user will choose');
          }
        }
      }

      // ⚡ PERF FIX: Yield to let GIF animation frames render after module resolution
      await Future<void>.delayed(Duration.zero);

      // Core module preloading is allowed only when a startup module is already resolved.
      // For multi-module/no-selection flow we intentionally skip all module prefetch.
      final startupAddress = AddressHelper.getUserAddressFromSharedPref();
      final hasAddressForPrefetch = startupAddress?.zoneIds != null &&
          startupAddress!.zoneIds!.isNotEmpty &&
          (startupAddress.latitude ?? '').trim().isNotEmpty &&
          (startupAddress.longitude ?? '').trim().isNotEmpty;
      final hasResolvedStartupModule =
          splashController.selectedModule.value != null ||
              splashController.module != null ||
              moduleListLength == 1;
      // ⚡ PERF FIX: Do NOT preload other modules during splash.
      // preloadCoreModulesForFastSwitch loads [3, 6, 9] etc. which competes
      // for network/CPU with the critical splash data fetch and inflates
      // splash time from ~3s to ~14s.  Deferred to DashboardScreen instead.
      if (hasResolvedStartupModule && hasAddressForPrefetch) {
        if (kDebugMode) {
          debugPrint(
              '⚡ SplashScreen: Deferring preloadCoreModulesForFastSwitch to post-splash');
        }
      } else if (kDebugMode) {
        debugPrint(
            '⚡ SplashScreen: Skipping preloadCoreModulesForFastSwitch — module or zone/location headers not ready');
      }

      // If no module is selected and multiple modules exist, go DIRECTLY to multi-module screen
      // 🏗️ MODULE-FIRST ARCHITECTURE: No prefetch without module
      // Prefetch will happen after user selects module in MultiModuleHomeScreen
      if (moduleListLength > 1 && splashController.module == null) {
        if (kDebugMode) {
          debugPrint(
              '🏗️ [Module-First] SplashScreen: Multiple modules available, no prefetch without module selection');
          debugPrint('   Prefetch will happen after user selects module');
        }

        // ✅ مدة splash ثابتة = 2.5 ثانية minimum
        final startTime = DateTime.now();

        // دع اللوجو يظهر مباشرة
        await Future.delayed(const Duration(milliseconds: 16));

        // 🏗️ MODULE-FIRST: Wait for module list to be ready, but don't prefetch
        // Prefetch is only allowed after module is selected
        // ⚡ PERF FIX: Removed shadowed `splashController` re-declaration that was hiding the outer one
        if (kDebugMode) {
          debugPrint('⏳ SplashScreen: Waiting for module list to be ready...');
        }
        await splashController.waitUntilReady().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint(
                '⏱️ SplashScreen: Module list wait timed out - proceeding with available data');
          },
        );

        // احسب الوقت
        final elapsed = DateTime.now().difference(startTime);

        // مدة splash ثابتة = 1.5 ثانية (cache already loaded, keep it snappy)
        const minSplashDuration = Duration(milliseconds: 1500);

        if (elapsed < minSplashDuration) {
          final remainingTime = minSplashDuration - elapsed;
          debugPrint(
              '⏱️ SplashScreen: Waiting ${remainingTime.inMilliseconds}ms to complete minimum splash duration (${elapsed.inMilliseconds}ms elapsed)');
          await Future.delayed(remainingTime);
        } else {
          debugPrint(
              '✅ SplashScreen: Minimum splash duration already satisfied (${elapsed.inMilliseconds}ms)');
        }

        debugPrint('✅ SplashScreen: Data ready, proceeding to route');

        // ⚡ PERF FIX: Notification popup check deferred to post-routing.
        // Running 2 API calls here was blocking splash → home transition.

        // Route directly to multi-module screen - it's the main entry point
        splashController.markSplashFlowStopped();
        splashController.markFirstNavigationReleased();
        debugPrint('🚀 SplashScreen: First navigation released');
        _hasNavigatedAway = true;
        _safetyNetTimer?.cancel();
        // ignore: use_build_context_synchronously
        route(context, body: widget.body);

        // ⚡ Check notification popup AFTER routing (non-blocking)
        _checkAndShowNotificationPopup();
        return;
      }

      // Only load module-specific data if a module is already selected
      // This happens when:
      // 1. User has a cached module preference
      // 2. Only one module exists (auto-selected)
      // 3. Config has a default module set

      // ✅ مدة splash ثابتة = 1.5 ثانية minimum (cache is loaded)
      final startTime = DateTime.now();

      // دع اللوجو يظهر مباشرة
      await Future.delayed(const Duration(milliseconds: 16));

      // Create data loading future
      Future<void> dataLoadingFuture;

      // 🏗️ MODULE-FIRST ARCHITECTURE: Check if module is resolved
      final hasModuleSelected = splashController.selectedModule.value != null ||
          splashController.module != null;

      if (hasModuleSelected || moduleListLength == 1) {
        debugPrint(
            '🚀 SplashScreen: Module selected (or single module), loading module-specific data...');

        dataLoadingFuture = () async {
          await Future.microtask(() async {
            if (!buildContext.mounted) {
              return;
            }
            await _ensureSuperPayloadReady(buildContext);
            debugPrint(
                '✅ SplashScreen: Super-payload ready (memory + Hive) - proceed to route');
          });
        }();
      } else {
        debugPrint(
            '⚠️ SplashScreen: No module selected and module list not ready yet, proceeding to home screen anyway');
        dataLoadingFuture = Future.value();
      }

      // انتظر الجاهزية (API / Cache / Init)
      debugPrint('⏳ SplashScreen: Waiting for data to be ready...');
      try {
        await Future.wait([
          splashController.waitUntilReady(),
          dataLoadingFuture,
        ]).timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('⏱️ SplashScreen: Timeout - routing immediately');
            return [];
          },
        );
      } on TimeoutException {
        // Timeout guard: move on with cached data immediately
        debugPrint(
            '⏱️ SplashScreen: Timeout waiting for API, routing with cache');
        await _restoreDataFromCache();
      }
      if (!mounted) {
        return;
      }

      // احسب الوقت
      final elapsed = DateTime.now().difference(startTime);

      // مدة splash ثابتة = 1.5 ثانية (cache loaded, keep it snappy)
      const minSplashDuration = Duration(milliseconds: 1500);

      if (elapsed < minSplashDuration) {
        final remainingTime = minSplashDuration - elapsed;
        debugPrint(
            '⏱️ SplashScreen: Waiting ${remainingTime.inMilliseconds}ms to complete minimum splash duration (${elapsed.inMilliseconds}ms elapsed)');
        await Future.delayed(remainingTime);
      } else {
        debugPrint(
            '✅ SplashScreen: Minimum splash duration already satisfied (${elapsed.inMilliseconds}ms)');
      }

      debugPrint('✅ SplashScreen: Data ready, proceeding to route');

      // ⚡ PERF FIX: Notification popup check deferred to post-routing.
      // Running 2 API calls here was blocking splash → home transition.

      // Now perform the routing
      debugPrint('🚀 SplashScreen: Routing to home screen...');
      splashController.markSplashFlowStopped();
      splashController.markFirstNavigationReleased();
      debugPrint('🚀 SplashScreen: First navigation released');
      _hasNavigatedAway = true;
      _safetyNetTimer?.cancel();
      // ignore: use_build_context_synchronously
      route(context, body: widget.body);

      // ⚡ Check notification popup AFTER routing (non-blocking)
      _checkAndShowNotificationPopup();
    });
  }

  /// Verify that controllers have data before proceeding to home screen
  /// 🔧 FIX: Check cache first before waiting for API calls
  // ignore: unused_element
  Future<void> _verifyControllersHaveData() async {
    const int maxRetries = 10;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      bool allDataReady = true;

      // Check banner data - 🔧 FIX: Check cache first
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();

        // 🔧 FIX: Check if banners exist in cache (don't wait for API)
        bool hasBannersInCache = false;
        int cachedBannerCount = 0;
        if (Get.isRegistered<SplashController>()) {
          final splashController = Get.find<SplashController>();
          final moduleId = splashController.selectedModule.value?.id ??
              splashController.module?.id;
          if (moduleId != null) {
            try {
              final cacheService = HiveHomeCacheService();
              final cachedBanners = await cacheService.loadBanners(moduleId);
              if (cachedBanners != null) {
                final bannerCount = cachedBanners.banners?.length ?? 0;
                final campaignCount = cachedBanners.campaigns?.length ?? 0;
                cachedBannerCount = bannerCount + campaignCount;
                hasBannersInCache = cachedBannerCount > 0;
                if (hasBannersInCache && kDebugMode) {
                  debugPrint(
                      '✅ SplashScreen: Banners found in cache - $cachedBannerCount items');
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ SplashScreen: Error checking banner cache: $e');
              }
            }
          }
        }

        // 🔧 CRITICAL FIX: Don't consider banners "ready" if count is 0
        // This prevents UI from building with empty state when real banners arrive later
        final controllerBannerCount =
            bannerController.bannerImageList?.length ?? 0;
        final controllerFeaturedBannerCount =
            bannerController.featuredBannerList?.length ?? 0;
        final totalBannerCount =
            controllerBannerCount + controllerFeaturedBannerCount;

        // If cache has banners OR controller has banners (with count > 0), consider ready
        if (!hasBannersInCache && totalBannerCount == 0) {
          debugPrint(
              '⏳ SplashScreen: Banner data not ready yet (attempt ${retryCount + 1}) - count: 0');
          allDataReady = false;
        } else if (hasBannersInCache && cachedBannerCount > 0) {
          debugPrint(
              '✅ SplashScreen: Banner data ready from cache - $cachedBannerCount items');
        } else if (totalBannerCount > 0) {
          debugPrint(
              '✅ SplashScreen: Banner data ready - $totalBannerCount items (regular: $controllerBannerCount, featured: $controllerFeaturedBannerCount)');
        } else {
          // Cache says ready but count is 0 - don't consider ready
          debugPrint(
              '⏳ SplashScreen: Banner cache exists but count is 0 - waiting for real data (attempt ${retryCount + 1})');
          allDataReady = false;
        }
      }

      // Check category data
      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        if (categoryController.categoryList == null ||
            categoryController.categoryList!.isEmpty) {
          debugPrint(
              '⏳ SplashScreen: Category data not ready yet (attempt ${retryCount + 1})');
          allDataReady = false;
        } else {
          debugPrint(
              '✅ SplashScreen: Category data ready - ${categoryController.categoryList!.length} items');
        }
      }

      // Check brand data
      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        if (brandsController.brandList == null ||
            brandsController.brandList!.isEmpty) {
          debugPrint(
              '⏳ SplashScreen: Brand data not ready yet (attempt ${retryCount + 1})');
          allDataReady = false;
        } else {
          debugPrint(
              '✅ SplashScreen: Brand data ready - ${brandsController.brandList!.length} items');
        }
      }

      if (allDataReady) {
        debugPrint(
            '🎉 SplashScreen: ALL CONTROLLERS HAVE DATA - Ready for instant home screen!');
        return;
      }

      retryCount++;
      if (retryCount < maxRetries) {
        debugPrint(
            '⏳ SplashScreen: Waiting for data... ($retryCount/$maxRetries)');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    debugPrint(
        '⚠️ SplashScreen: Some data may not be ready, but proceeding to home screen');
  }

  /// Restore data from cache to controllers
  Future<void> _restoreDataFromCache() async {
    // Check if widget is still mounted
    if (!mounted) {
      debugPrint(
          '⚠️ SplashScreen: Widget unmounted, skipping cache restoration');
      return;
    }

    try {
      debugPrint(
          '📦 SplashScreen: Restoring data from cache to controllers...');

      // Load cached data and restore to controllers
      final cachedData = await ComprehensiveHomeCacheManager.loadAllHomeData();
      if (cachedData.isNotEmpty) {
        await ComprehensiveHomeCacheManager.restoreDataToControllers(
            cachedData);
        debugPrint(
            '✅ SplashScreen: Data restored from cache to controllers successfully');
      } else {
        debugPrint(
            '⚠️ SplashScreen: No cached data found, loading from API...');
        // Fallback to API loading if cache is empty
        if (!mounted) {
          return;
        }
        await _preloadHomeScreenData(context);
      }
    } catch (e) {
      debugPrint('⚠️ SplashScreen: Error restoring from cache - $e');
      // Fallback to API loading if cache restoration fails
      if (!mounted) {
        return;
      }
      await _preloadHomeScreenData(context);
    }
  }

  /// Ensure super-payload is ready in memory + Hive before routing
  Future<void> _ensureSuperPayloadReady(BuildContext context) async {
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.selectedModule.value?.id ??
        splashController.module?.id;
    if (moduleId == null || !Get.isRegistered<HomeUnifiedController>()) {
      return;
    }

    final homeUnifiedController = Get.find<HomeUnifiedController>();
    final cacheService = HiveHomeCacheService();

    // 1) Try memory cache -> distribute immediately (instant switch)
    final bool memoryLoaded = await homeUnifiedController
        .loadCachedDataForInstantUI(loadStores: false);

    // 2) Check Hive for super-payload
    final cached = await cacheService.loadHomeUnifiedData(moduleId);
    if (cached == null || !cached.isValid) {
      // ⚡ PERF FIX: Do NOT await a full API call on the splash critical path.
      // If Hive cache is missing, fire the network fetch in the background and
      // let the home screen show its own loading state instead of blocking
      // splash for potentially 10+ seconds.
      unawaited(homeUnifiedController.loadHomeData(
        moduleId: moduleId,
        forceRefresh: true,
        showLoading: false,
      ));
    } else if (!memoryLoaded) {
      // If cache exists but memory wasn't injected, inject directly
      if (cached.categories != null &&
          cached.categories!.isNotEmpty &&
          Get.isRegistered<CategoryController>()) {
        Get.find<CategoryController>().setCategoryListFromCache(
          cached.categories!,
          expectedModuleId: moduleId,
        );
      }
    }

    // 3) Background refresh (offline-first UX) — only if cache was valid
    if (cached != null && cached.isValid) {
      unawaited(homeUnifiedController.loadHomeData(
        moduleId: moduleId,
        forceRefresh: false,
        showLoading: false,
      ));
    }
  }

  /// Pre-load home screen data during splash for instant home screen
  /// This method iRs only called when cache is invalid or doesn't exist
  Future<void> _preloadHomeScreenData(BuildContext context) async {
    // Check if widget is still mounted
    if (!mounted) {
      debugPrint(
          '⚠️ SplashScreen: Widget unmounted, skipping home data preload');
      return;
    }

    try {
      debugPrint(
          '🚀 SplashScreen: Pre-loading home screen data (cache invalid)...');

      // Since this method is only called when cache is invalid, always load from API
      debugPrint(
          '🔄 SplashScreen: Calling OptimizedHomeDataLoader.loadData...');
      await OptimizedHomeDataLoader.loadData(
        context,
        true, // reload
        specificSections: [
          'banners',
          'categories',
          'brands',
          'offers',
          'stores',
          'items',
          'campaigns'
        ],
      );
      debugPrint('✅ SplashScreen: OptimizedHomeDataLoader.loadData completed');

      // Check if controllers have data after API loading
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        debugPrint(
            '🔍 SplashScreen: Banner data after API load: ${bannerController.bannerImageList?.length ?? 0} items');
      }
      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        debugPrint(
            '🔍 SplashScreen: Category data after API load: ${categoryController.categoryList?.length ?? 0} items');
      }
      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        debugPrint(
            '🔍 SplashScreen: Brand data after API load: ${brandsController.brandList?.length ?? 0} items');
      }

      // Save to cache
      await ComprehensiveHomeCacheManager.saveAllHomeData();
      debugPrint(
          '✅ SplashScreen: Data loaded from API and cached successfully');

      // CRITICAL: Restore data to controllers immediately after loading from API
      debugPrint(
          '🔄 SplashScreen: Restoring data to controllers after API load...');
      final cachedData = await ComprehensiveHomeCacheManager.loadAllHomeData();
      if (cachedData.isNotEmpty) {
        await ComprehensiveHomeCacheManager.restoreDataToControllers(
            cachedData);
        debugPrint(
            '✅ SplashScreen: Data restored to controllers after API load');
      } else {
        debugPrint('⚠️ SplashScreen: No data found in cache after API load');
      }

      // Promotional content preload is intentionally deferred to
      // MultiModuleHomeScreen after splash route transition.
    } catch (e) {
      debugPrint('⚠️ SplashScreen: Could not pre-load home data - $e');
    }
  }

  /// Pre-fetch multi-module home screen data during splash
  ///
  // 🏗️ MODULE-FIRST ARCHITECTURE: Removed _prefetchMultiModuleData
  // Prefetch is not allowed without a selected module
  // Prefetch will happen in MultiModuleHomeScreen after user selects a module

  /// Check and show notification popup if available
  Future<void> _checkAndShowNotificationPopup() async {
    try {
      // Only check for notification popup if user is logged in (NOT guest users)
      if (AuthHelper.isLoggedIn()) {
        debugPrint('🔔 SplashScreen: Checking for notification popup...');

        // Get notification controller
        if (Get.isRegistered<NotificationController>()) {
          final notificationController = Get.find<NotificationController>();

          // Process new notifications first
          await notificationController.processNewNotifications();

          // Check and show popup if available
          await notificationController.checkAndShowNotificationPopup();
        } else {
          debugPrint(
              '🔔 SplashScreen: NotificationController not registered yet');
        }
      } else {
        debugPrint(
            '🔔 SplashScreen: User not logged in (guest), skipping notification popup check');
      }
    } catch (e) {
      debugPrint('🔔 SplashScreen: Error checking notification popup: $e');
    }
  }

  @override
  void dispose() {
    _safetyNetTimer?.cancel();
    if (Get.isRegistered<SplashController>()) {
      Get.find<SplashController>().markSplashFlowStopped();
    }
    _onConnectivityChanged?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ PERF FIX: initSharedData() removed from build() — it already runs once
    // in initState(). Calling it here caused redundant SharedPreferences +
    // Hive work on every widget rebuild, adding jank during splash.
    if (AddressHelper.getUserAddressFromSharedPref() != null &&
        AddressHelper.getUserAddressFromSharedPref()!.zoneIds == null) {
      Get.find<AuthController>().clearSharedAddress();
    }

    return Scaffold(
      key: _globalKey,
      body: GetBuilder<SplashController>(builder: (splashController) {
        return Center(
          child: splashController.hasConnection
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(Images.logo_gif, width: 200),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                  ],
                )
              : NoInternetScreen(child: SplashScreen(body: widget.body)),
        );
      }),
    );
  }
}
