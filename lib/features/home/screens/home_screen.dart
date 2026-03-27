// ignore_for_file: avoid_unnecessary_containers, deprecated_member_use, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/screens/all_sections/food_home_screen.dart';
import 'package:sixam_mart/features/home/screens/all_sections/pharmacy_home_screen.dart';
import 'package:sixam_mart/features/home/widgets/cashback_logo_widget.dart';
import 'package:sixam_mart/features/home/widgets/cashback_dialog_widget.dart';
import 'package:sixam_mart/features/home/widgets/custom_appBar_widget.dart';
import 'package:sixam_mart/features/home/widgets/refer_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/home/widgets/professional_module_strip.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/home/screens/all_sections/grocery_home_screen.dart';
import 'package:sixam_mart/features/home/screens/all_sections/shop_home_screen.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/screens/taxi_home_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/home/screens/web_new_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/module_view.dart';
import 'package:sixam_mart/features/home/widgets/flattened_app_bar_content.dart';
import 'package:sixam_mart/features/home/widgets/flattened_module_content.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_category_screen.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_loader.dart';
import 'package:sixam_mart/common/cache/loading_state_manager.dart';
import 'package:sixam_mart/common/cache/preloaded_data_manager.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static bool _isBackgroundRefreshInProgress = false;
  static DateTime? _lastBackgroundRefreshAt;
  static const Duration _backgroundRefreshThrottle = Duration(seconds: 5);

  /// ✅ FIX: Reset static flags when switching modules
  /// This prevents stale state from previous module
  static void resetModuleState() {
    _HomeScreenState._hasLoadedOnce = false;
    debugPrint('🔄 HomeScreen: Module state reset - _hasLoadedOnce = false');
  }

  static Future<void> loadData(context, bool reload,
      {bool fromModule = false}) async {
    final loadingManager = LoadingStateManager();
    final BuildContext buildContext = context as BuildContext;

    // Check if we can start home loading
    if (!loadingManager.canStartHomeLoading()) {
      return;
    }

    // ⚡ CRITICAL FIX: When switching modules, check cache FIRST before loading
    // This ensures instant display when switching between modules with valid cache
    if (fromModule && !reload) {
      try {
        final cacheValid = await ComprehensiveHomeCacheManager.isCacheValid();
        if (cacheValid) {
          if (kDebugMode) {
            print(
                '⚡ HomeScreen.loadData: Module switch detected, restoring from cache instantly');
          }

          // Load cached data immediately WITHOUT clearing controllers
          final cachedData =
              await ComprehensiveHomeCacheManager.loadAllHomeData();
          if (cachedData.isNotEmpty) {
            // Restore data to controllers (this updates controllers in place, doesn't clear them)
            await ComprehensiveHomeCacheManager.restoreDataToControllers(
                cachedData);

            // Verify critical data was restored (categories or stores)
            bool hasCriticalData = false;
            if (Get.isRegistered<CategoryController>()) {
              final categoryController = Get.find<CategoryController>();
              hasCriticalData = categoryController.categoryList != null &&
                  categoryController.categoryList!.isNotEmpty;
            }
            if (!hasCriticalData && Get.isRegistered<StoreController>()) {
              final storeController = Get.find<StoreController>();
              hasCriticalData = storeController.storeModel != null &&
                  storeController.storeModel!.stores != null &&
                  storeController.storeModel!.stores!.isNotEmpty;
            }

            if (hasCriticalData) {
              bool hasBannerData = true;
              if (Get.isRegistered<BannerController>()) {
                final bannerController = Get.find<BannerController>();
                hasBannerData = bannerController.featuredBannerList != null &&
                    bannerController.featuredBannerList!.isNotEmpty;
                if (!hasBannerData) {
                  if (kDebugMode) {
                    print(
                        '⚠️ HomeScreen.loadData: Critical cache present but banners missing, forcing banner reload');
                  }
                  // Trigger immediate banner fetch for current module.
                  bannerController.getFeaturedBanner();
                }
              }

              if (!hasBannerData) {
                if (kDebugMode) {
                  print(
                      '⚠️ HomeScreen.loadData: Skipping early return because banners are missing');
                }
                // Fall through to normal loading to recover missing sections.
              } else {
                if (kDebugMode) {
                  print(
                      '✅ HomeScreen.loadData: Cache restored successfully, skipping API calls');
                }
                // Refresh in background only (without clearing controllers)
                if (!buildContext.mounted) {
                  return;
                }
                _refreshInBackground(buildContext);
                return; // Exit early - data is already loaded from cache
              }
            } else {
              if (kDebugMode) {
                print(
                    '⚠️ HomeScreen.loadData: Cache restored but no critical data, falling back to API');
              }
              // Fall through to normal loading
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              '⚠️ HomeScreen.loadData: Cache check failed, falling back to normal load - $e');
        }
        // Fall through to normal loading
      }
    }

    // Start home loading
    if (!loadingManager.startHomeLoading(force: reload)) {
      return;
    }

    try {
      // Check if data is already preloaded and valid
      if (!reload) {
        final preloadedManager = PreloadedDataManager();
        if (await preloadedManager.shouldSkipLoading()) {
          return; // NO API CALLS! 🎉
        }
      }

      // Only load if not preloaded or force refresh
      if (!buildContext.mounted) {
        return;
      }
      await ComprehensiveHomeLoader.loadAllHomeData(
        buildContext,
        forceRefresh: reload,
      );
    } finally {
      loadingManager.completeHomeLoading();
    }
  }

  /// Refresh data in background without blocking UI
  /// ⚡ BFF API v2: Use unified endpoint if enabled
  static void _refreshInBackground(BuildContext context) {
    if (_isBackgroundRefreshInProgress) {
      return;
    }
    final now = DateTime.now();
    if (_lastBackgroundRefreshAt != null &&
        now.difference(_lastBackgroundRefreshAt!) <
            _backgroundRefreshThrottle) {
      return;
    }
    _isBackgroundRefreshInProgress = true;
    _lastBackgroundRefreshAt = now;

    // Run in background without blocking
    Future.microtask(() async {
      try {
        // ⚡ BFF API v2: Use unified endpoint if enabled
        if (AppConstants.useBffV2Endpoint &&
            Get.isRegistered<HomeUnifiedController>()) {
          final unifiedController = Get.find<HomeUnifiedController>();
          await unifiedController.loadHomeData(
            showLoading: false,
          );
          return;
        }

        // Fallback to legacy loader if unified endpoint disabled
        if (!context.mounted) {
          return;
        }
        await ComprehensiveHomeLoader.loadAllHomeData(
          context,
          forceRefresh: true, // Force refresh in background
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ HomeScreen: Background refresh failed - $e');
        }
      } finally {
        _isBackgroundRefreshInProgress = false;
      }
    });
  }

  /// Hard refresh for pull-to-refresh gesture.
  /// This explicitly invalidates module cache + ETag, then fetches fresh API data.
  static Future<void> performHardRefresh(BuildContext context) async {
    final splashController = Get.find<SplashController>();
    final int? moduleId = splashController.module?.id;

    if (AppConstants.useBffV2Endpoint &&
        Get.isRegistered<HomeUnifiedController>()) {
      final unifiedController = Get.find<HomeUnifiedController>();

      if (moduleId != null) {
        await unifiedController.clearCacheAndForceRefresh(moduleId: moduleId);
        if (Get.isRegistered<BannerController>()) {
          Get.find<BannerController>().invalidateModule(moduleId);
        }
        unifiedController.allowImmediateFetchForModule(moduleId);
      }

      final bool success = await unifiedController.loadHomeData(
        forceRefresh: true,
        showLoading: false,
      );

      if (!success && Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().loadHomeData(forceRefresh: true);
      }
      return;
    }

    if (!context.mounted) {
      return;
    }
    await ComprehensiveHomeLoader.loadAllHomeData(
      context,
      forceRefresh: true,
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController scrollController = ScrollController();
  bool searchBgShow = false;
  final GlobalKey headerKey = GlobalKey();
  Timer? _deferredLoadTimer;
  bool _deferredLoadQueued = false;
  int? _lastConnectivityRecoveryModuleId;

  // ⚡ Cache-First Fix: Track if first load completed
  static bool _hasLoadedOnce = false;
  DateTime? _lastUiDiagAt;
  String? _lastUiDiagSignature;

  @override
  void initState() {
    super.initState();
    appLogger.logPageEntry('HomeScreen');
    appLogger.info('🏠 HomeScreen: Initializing');

    // Check if data is already loaded using instant loading manager
    _checkAndLoadData();

    // Load cart data only if not already loaded or stale
    // This prevents redundant API calls on home screen
    Future.microtask(() async {
      if (AuthHelper.isLoggedIn() && Get.isRegistered<CartController>()) {
        final cartController = Get.find<CartController>();

        // Only load if cart data is not available or is stale (older than 5 minutes)
        if (cartController.cartList.isEmpty ||
            cartController.lastSuccessfulCartLoad == null ||
            DateTime.now().difference(cartController.lastSuccessfulCartLoad!) >
                const Duration(minutes: 5)) {
          // Wait for guest cart transfer to complete (if any)
          await Future.delayed(const Duration(milliseconds: 2000));
          debugPrint(
              '🔄 HomeScreen: Loading cart data on init (stale or empty)');
          cartController.getCartDataOnline(forceRefresh: true);
        } else {
          debugPrint('💾 HomeScreen: Using cached cart data');
        }
      }
    });

    if (!ResponsiveHelper.isWeb()) {
      Future.microtask(() {
        if (Get.isRegistered<LocationController>()) {
          // Check if we should skip zone validation (when using current location)
          final locationController = Get.find<LocationController>();
          if (locationController.skipZoneValidation) {
            debugPrint(
                '🏠 HomeScreen: Skipping zone validation due to current location usage');
            // Don't reset the flag here - let it be reset after all data loading is complete
            return;
          }

          // 🔧 FIX: Null-safe address access - prevent crash for new users without address
          final AddressModel? userAddress =
              AddressHelper.getUserAddressFromSharedPref();
          if (userAddress?.latitude != null && userAddress?.longitude != null) {
            Get.find<LocationController>().getZone(
                userAddress!.latitude, userAddress.longitude, false,
                updateInAddress: true);
          } else {
            debugPrint(
                '⚠️ HomeScreen: No saved address found - skipping zone validation');
          }
        }
      });
    }

    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (Get.find<HomeController>().showFavButton) {
          Get.find<HomeController>().changeFavVisibility();
          Future.delayed(const Duration(milliseconds: 800),
              () => Get.find<HomeController>().changeFavVisibility());
        }
      } else {
        if (Get.find<HomeController>().showFavButton) {
          Get.find<HomeController>().changeFavVisibility();
          Future.delayed(const Duration(milliseconds: 800),
              () => Get.find<HomeController>().changeFavVisibility());
        }
      }
    });
  }

  @override
  void dispose() {
    appLogger.logPageExit();
    _deferredLoadTimer?.cancel();
    super.dispose();
    scrollController.dispose();
  }

  void _scheduleDeferredLoadCheck() {
    if (_deferredLoadQueued || !mounted) {
      return;
    }
    _deferredLoadQueued = true;
    _deferredLoadTimer?.cancel();
    _deferredLoadTimer = Timer(const Duration(milliseconds: 700), () async {
      _deferredLoadQueued = false;
      if (!mounted) {
        return;
      }

      final loadingManager = LoadingStateManager();
      if (loadingManager.isComprehensiveLoading ||
          loadingManager.isHomeLoading) {
        _scheduleDeferredLoadCheck();
        return;
      }

      final hasData = await _checkControllersHaveData();
      if (!hasData) {
        await _checkAndLoadData();
      }
    });
  }

  /// ⚡ PERFORMANCE: Load stores after first frame
  /// This ensures first frame renders quickly with banners, categories, offers
  /// Stores are loaded separately after UI is visible
  void _loadStoresAfterFirstFrame() {
    if (AppConstants.useBffV2Endpoint) {
      if (kDebugMode) {
        print(
            '🛡️ HomeScreen: Unified-only policy - skipping post-frame legacy store fetch');
      }
      return;
    }

    if (!Get.isRegistered<StoreController>()) {
      return;
    }

    final storeController = Get.find<StoreController>();

    // ⚡ PERFORMANCE: Only load if stores are not already loaded
    if (storeController.allStoreModel == null && !storeController.isLoading) {
      if (kDebugMode) {
        print(
            '📡 HomeScreen: Loading stores after first frame (post-frame callback)');
      }

      // ⚡ PERFORMANCE: Load with small limit (7) for first frame
      // Pagination will load more as user scrolls
      storeController.getStoreList(1, false, limit: 7);
    }
  }

  /// Check if data is loaded and load if needed
  Future<void> _checkAndLoadData() async {
    try {
      final splashController = Get.find<SplashController>();

      // ⚡ Cache-First Fix: If module is null, don't try to load data
      // Module must be selected first (will show skeleton until module is selected)
      if (splashController.module == null) {
        if (kDebugMode) {
          print(
              '[Cache-First] HomeScreen: Skipping data load - module is null (will show skeleton)');
        }
        return;
      }

      // ⚠️ CRITICAL: Skip all data loading if we're showing multi-module screen
      // Multi-module screen doesn't need banners, categories, brands, etc.
      // It only loads modules list, offers (for module 3), and wallet (if logged in)
      final moduleList = splashController.moduleList;
      final moduleListLength = moduleList?.length ?? 0;
      final bool showMultiModuleScreen = splashController.module == null &&
          moduleList != null &&
          moduleListLength > 1;

      if (showMultiModuleScreen) {
        if (kDebugMode) {
          print(
              '🚫 HomeScreen: Skipping data load - showing multi-module screen');
        }
        _handlePostLoadActions();
        return; // Don't load any data - MultiModuleHomeScreen will handle its own loading
      }

      // ⚠️ CRITICAL: If modules are not loaded yet, don't try to load home data
      // The build method will trigger module loading, and then we'll rebuild
      if (moduleList == null || moduleListLength == 0) {
        if (kDebugMode) {
          print('🚫 HomeScreen: Skipping data load - modules not loaded yet');
        }
        return;
      }

      // ⚡ Cache-First Fix: Track first load
      final isFirstLoad = !_hasLoadedOnce;

      if (isFirstLoad && splashController.module != null) {
        if (kDebugMode) {
          print(
              '[Cache-First] HomeScreen: First load detected - marking as loaded');
        }
        _hasLoadedOnce = true;
        // 🛡️ LOOP PREVENTION: Do NOT manually trigger loadHomeData here
        // The Worker in HomeController will handle data loading when module changes
        // Manual triggers cause Cold Start Loop for new users
      }

      // ⚠️ CRITICAL FIX: Avoid duplicate comprehensive loads
      final loadingManager = LoadingStateManager();
      if (loadingManager.isComprehensiveLoading ||
          loadingManager.isHomeLoading) {
        if (kDebugMode) {
          print(
              '⚠️ HomeScreen: Loading already in progress - skipping duplicate load');
        }
        _scheduleDeferredLoadCheck();
        return;
      }

      // ⚡ BFF API v2: Check HomeUnifiedController first (single source of truth)
      if (AppConstants.useBffV2Endpoint &&
          Get.isRegistered<HomeUnifiedController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        final int? currentModuleId = splashController.module?.id;
        final bool shouldForceRecoveryRefresh = splashController.hasConnection &&
            unifiedController.lastRequestStatusCode == 1 &&
            !unifiedController.isLoading &&
            currentModuleId != null &&
            _lastConnectivityRecoveryModuleId != currentModuleId;
        final int? recoveryModuleId =
            shouldForceRecoveryRefresh ? currentModuleId : null;

        // ⚡ PERFORMANCE: First frame - load from cache only (banners, categories, offers) without stores
        final cacheLoaded = await unifiedController.loadCachedDataForInstantUI(
            loadStores: false);
        if (cacheLoaded) {
          if (kDebugMode) {
            print(
                '⚡ HomeScreen: First frame loaded from cache (banners, categories, offers)');
          }

          // ⚡ PERFORMANCE: Trigger background refresh AFTER first frame
          // This ensures UI appears instantly while data refreshes in background
          Future.microtask(() {
            if (!mounted) {
              return;
            }
            if (recoveryModuleId != null) {
              _lastConnectivityRecoveryModuleId = recoveryModuleId;
              unifiedController.allowImmediateFetchForModule(recoveryModuleId);
              unifiedController.loadHomeData(
                forceRefresh: true,
                showLoading: false,
              );
            } else {
              HomeScreen._refreshInBackground(context);
            }
          });

          // ⚡ PERFORMANCE: Load stores AFTER first frame (post-frame callback)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _loadStoresAfterFirstFrame();
              }
            });
          });

          _handlePostLoadActions();
          return;
        }

        // If no cached data, trigger unified load (but still skip stores for first frame)
        if (!unifiedController.isLoading) {
          // ⚡ Cache-First Fix: Force fetch on first load
          final isFirstLoad = !_hasLoadedOnce;
          await unifiedController.loadHomeData(
            showLoading: false,
            forceRefresh: isFirstLoad, // Force fetch on first load
          );

          // Load stores after first frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _loadStoresAfterFirstFrame();
              }
            });
          });
        }
        _handlePostLoadActions();
        return;
      }

      // Fallback: Legacy individual controller checks (if unified endpoint disabled)
      // First check if data is already available in controllers
      final bool hasData = await _checkControllersHaveData();

      if (hasData) {
        _handlePostLoadActions();
        return;
      }

      // Check if we should force data restoration due to user state change
      final bool forceRestoration =
          await ComprehensiveHomeCacheManager.shouldForceDataRestoration();

      // Check if cache is valid and restore data from cache first
      final bool cacheValid =
          await ComprehensiveHomeCacheManager.isCacheValid();

      if (cacheValid || forceRestoration) {
        await _restoreDataFromCache();

        // Verify data was restored (non-blocking check)
        final bool dataRestored = await _checkControllersHaveData();
        if (dataRestored) {
          _handlePostLoadActions();
          return; // IMPORTANT: Don't call HomeScreen.loadData() after successful cache restoration
        }
      }

      // Try to load data normally only if cache restoration failed
      if (!mounted) {
        return;
      }
      await HomeScreen.loadData(context, false);

      // Check if data is actually loaded
      await _verifyDataLoaded();

      // If still no data, force load individual controllers
      final bool stillNoData = !(await _checkControllersHaveData());
      if (stillNoData) {
        await _forceLoadIndividualControllers();
      }

      _handlePostLoadActions();
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeScreen: Error loading data - $e');
      }
      // Fallback to direct API loading
      await _fallbackDataLoading();
      _handlePostLoadActions();
    }
  }

  /// Check if controllers already have data
  Future<bool> _checkControllersHaveData() async {
    try {
      // Check if controllers have data
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        if (bannerController.bannerImageList == null ||
            bannerController.bannerImageList!.isEmpty) {
          return false;
        }
      }

      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        if (categoryController.categoryList == null ||
            categoryController.categoryList!.isEmpty) {
          return false;
        }
      }

      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        if (brandsController.brandList == null ||
            brandsController.brandList!.isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeScreen: Error checking controller data - $e');
      }
      return false;
    }
  }

  /// Verify that data is actually loaded in controllers
  Future<void> _verifyDataLoaded() async {
    try {
      bool needsFallback = false;

      // Check if controllers have data
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        if (bannerController.bannerImageList == null ||
            bannerController.bannerImageList!.isEmpty) {
          needsFallback = true;
        }
      }

      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        if (categoryController.categoryList == null ||
            categoryController.categoryList!.isEmpty) {
          needsFallback = true;
        }
      }

      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        if (brandsController.brandList == null ||
            brandsController.brandList!.isEmpty) {
          needsFallback = true;
        }
      }

      if (needsFallback) {
        await _fallbackDataLoading();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeScreen: Error verifying data - $e');
      }
      await _fallbackDataLoading();
    }
  }

  /// Fallback data loading if cache restoration fails
  /// ⚡ BFF API v2: Use unified endpoint instead of individual API calls
  Future<void> _fallbackDataLoading() async {
    try {
      appLogger.logPageEntry('HomeScreen');
      appLogger.info('🔄 HomeScreen: Starting fallback data loading');

      // ⚡ BFF API v2: Use unified endpoint if enabled
      if (AppConstants.useBffV2Endpoint &&
          Get.isRegistered<HomeUnifiedController>()) {
        appLogger.info(
            '📡 HomeScreen: Using unified endpoint: ${AppConstants.homeUnifiedUri}');
        final stopwatch = Stopwatch()..start();
        try {
          final unifiedController = Get.find<HomeUnifiedController>();
          await unifiedController.loadHomeData(
            forceRefresh: true, // Force refresh since cache restoration failed
            showLoading: false, // Silent refresh
          );
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Unified endpoint completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          stopwatch.stop();
          appLogger.error('❌ HomeScreen: Unified endpoint failed', e);
        }
        return;
      }

      // Fallback to individual API calls if unified endpoint is disabled
      // ⚠️ CRITICAL: Ensure headers are valid with moduleId before making API calls
      final apiClient = Get.find<ApiClient>();
      apiClient.ensureHeadersAreValid();

      // Direct API calls to controllers to ensure data is loaded
      // Use individual try-catch to prevent one failure from stopping others
      if (Get.isRegistered<BannerController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling banner API: ${AppConstants.bannerUri}');
          await Get.find<BannerController>().getBannerList(true);
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Banner API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error('❌ HomeScreen: Error loading banners in fallback', e);
        }
      }
      if (Get.isRegistered<CategoryController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling category API: ${AppConstants.categoryUri}');
          await Get.find<CategoryController>().getCategoryList(true,
              expectedModuleId:
                  Get.find<SplashController>().selectedModule.value?.id);
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Category API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error(
              '❌ HomeScreen: Error loading categories in fallback', e);
        }
      }
      if (Get.isRegistered<BrandsController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info('📡 HomeScreen: Calling brands API');
          await Get.find<BrandsController>().getBrandList();
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Brands API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error('❌ HomeScreen: Error loading brands in fallback', e);
        }
      }
      if (Get.isRegistered<StoreController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling store API: ${AppConstants.storeUri}?offset=1&limit=12');
          await Get.find<StoreController>().getStoreList(1, true);
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Store API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error('❌ HomeScreen: Error loading stores in fallback', e);
        }
      }
      if (!AppConstants.useBffV2Endpoint &&
          Get.isRegistered<Offers_Controller>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling offers API: ${AppConstants.offersUri}');
          // getOffers() will use current module ID from SplashController
          await Get.find<Offers_Controller>().getOffers();
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Offers API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error('❌ HomeScreen: Error loading offers in fallback', e);
        }
      }
      // Only call auth APIs if user is logged in (NOT guest users)
      if (AuthHelper.isLoggedIn() && Get.isRegistered<ProfileController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling user info API: ${AppConstants.customerInfoUri}');
          await Get.find<ProfileController>().getUserInfo();
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: User info API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error(
              '❌ HomeScreen: Error loading user info in fallback', e);
        }
      }
    } catch (e) {
      appLogger.error('❌ HomeScreen: Fallback data loading failed', e);
    }
  }

  /// Force load individual controllers when data is missing
  Future<void> _forceLoadIndividualControllers() async {
    try {
      if (AppConstants.useBffV2Endpoint) {
        appLogger.info(
            '🛡️ HomeScreen: Unified-only policy - skipping force load of individual controllers');
        return;
      }

      appLogger.info('🔄 HomeScreen: Force loading individual controllers');

      // ⚠️ CRITICAL: Ensure headers are valid with moduleId before making API calls
      final apiClient = Get.find<ApiClient>();
      apiClient.ensureHeadersAreValid();

      // Force load each controller individually with API calls
      final futures = <Future<void>>[];

      if (Get.isRegistered<BannerController>()) {
        futures.add(Get.find<BannerController>()
            .getBannerList(true, dataSource: DataSourceEnum.client)
            .then((_) {
          appLogger.info('✅ HomeScreen: Banner controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading banners', e);
        }));
      }
      if (Get.isRegistered<CategoryController>()) {
        futures.add(Get.find<CategoryController>()
            .getCategoryList(true, dataSource: DataSourceEnum.client)
            .then((_) {
          appLogger
              .info('✅ HomeScreen: Category controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading categories', e);
        }));
      }
      if (Get.isRegistered<BrandsController>()) {
        futures.add(Get.find<BrandsController>()
            .getBrandList(dataSource: DataSourceEnum.client)
            .then((_) {
          appLogger.info('✅ HomeScreen: Brands controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading brands', e);
        }));
      }
      if (Get.isRegistered<StoreController>()) {
        futures.add(Get.find<StoreController>().getStoreList(1, true).then((_) {
          appLogger.info('✅ HomeScreen: Store controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading stores', e);
        }));
      }
      if (Get.isRegistered<Offers_Controller>()) {
        futures.add(Get.find<Offers_Controller>().getOffers().then((_) {
          appLogger.info('✅ HomeScreen: Offers controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading offers', e);
        }));
      }

      // Wait for all controllers to load
      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();
      appLogger.info(
          '✅ HomeScreen: All controllers loaded in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      appLogger.error(
          '❌ HomeScreen: Error force loading individual controllers',
          e,
          stackTrace);
    }
  }

  /// Restore data from cache to controllers
  Future<void> _restoreDataFromCache() async {
    try {
      // Load cached data
      final cachedData = await ComprehensiveHomeCacheManager.loadAllHomeData();

      if (cachedData.isNotEmpty) {
        // Restore data to controllers
        await ComprehensiveHomeCacheManager.restoreDataToControllers(
            cachedData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeScreen: Error restoring data from cache - $e');
      }
    }
  }

  /// Handle post-load actions
  void _handlePostLoadActions() {
    if (Get.isRegistered<SplashController>()) {
      Get.find<SplashController>().getReferBottomSheetStatus();

      if ((Get.find<ProfileController>().userInfoModel?.isValidForDiscount ??
              false) &&
          Get.find<SplashController>().showReferBottomSheet) {
        showReferBottomSheet();
      }
    }
  }

  void showReferBottomSheet() {
    ResponsiveHelper.isDesktop(context)
        ? Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusExtraLarge)),
              insetPadding: const EdgeInsets.all(22),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: const ReferBottomSheetWidget(),
            ),
            useSafeArea: false,
          ).then((value) =>
            Get.find<SplashController>().saveReferBottomSheetStatus(false))
        : showModalBottomSheet(
            isScrollControlled: true,
            useRootNavigator: true,
            context: Get.context!,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusExtraLarge),
                  topRight: Radius.circular(Dimensions.radiusExtraLarge)),
            ),
            builder: (context) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: const ReferBottomSheetWidget(),
              );
            },
          ).then((value) =>
            Get.find<SplashController>().saveReferBottomSheetStatus(false));
  }

  Future<void> loadTaxiApis() async {
    await Get.find<TaxiHomeController>().getTaxiBannerList(true);
    await Get.find<TaxiHomeController>().getTopRatedCarList(1, true);
    if (AuthHelper.isLoggedIn()) {
      await Get.find<AddressController>().getAddressList();
      await Get.find<TaxiHomeController>().getTaxiCouponList(true);
      await Get.find<TaxiCartController>().getCarCartList();
    }
  }

  void _logUiStateSnapshot(String source, SplashController splashController) {
    if (!kDebugMode) {
      return;
    }

    int bannerCount = -1;
    int categoryCount = -1;
    int offersCount = -1;
    if (Get.isRegistered<BannerController>()) {
      final bannerController = Get.find<BannerController>();
      bannerCount = bannerController.featuredBannerList?.length ??
          bannerController.bannerImageList?.length ??
          0;
    }
    if (Get.isRegistered<CategoryController>()) {
      categoryCount = Get.find<CategoryController>().categoryList?.length ?? 0;
    }
    if (Get.isRegistered<Offers_Controller>()) {
      offersCount = Get.find<Offers_Controller>().offersMode?.data.length ?? 0;
    }

    final signature = [
      'm=${splashController.module?.id}',
      'b=$bannerCount',
      'c=$categoryCount',
      'o=$offersCount',
    ].join('|');

    final now = DateTime.now();
    final shouldLog = _lastUiDiagSignature != signature ||
        _lastUiDiagAt == null ||
        now.difference(_lastUiDiagAt!) > const Duration(seconds: 3);
    if (!shouldLog) {
      return;
    }

    _lastUiDiagAt = now;
    _lastUiDiagSignature = signature;
    debugPrint(
        '[Diag][$source] UI => module=${splashController.module?.id}, banners=$bannerCount, categories=$categoryCount, offers=$offersCount');
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      // 🏗️ MODULE-FIRST ARCHITECTURE: Defensive Layer
      // This is a safety net - Route Guard should prevent this, but defense in depth
      final selectedModule = splashController.selectedModule.value;
      if (selectedModule == null && splashController.module == null) {
        if (kDebugMode) {
          debugPrint(
              '🏗️ [Module-First] HomeScreen: Module is null - showing skeleton (defensive layer)');
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'loading'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      }

      // FIRST: Check if we should show multi-module selection screen (MAIN ENTRY POINT)
      // Multi-module screen is ALWAYS the main home screen when multiple modules exist
      // This check must happen BEFORE any auto-switching or config module logic
      final moduleList = splashController.moduleList;
      final moduleListLength = moduleList?.length ?? 0;

      // CRITICAL: Load modules if not loaded yet or if list is empty
      if (moduleList == null || moduleListLength == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          splashController.getModules();
        });
        // When API returns empty module list, show empty state instead of spinner.
        return NoDataScreen(
          text: 'home_no_places_available'.tr,
          subtitle: 'home_no_places_available_subtitle'.tr,
          actionWidget: ElevatedButton(
            onPressed: () {
              splashController.getModules(dataSource: DataSourceEnum.client);
            },
            child: Text('retry'.tr),
          ),
          showFooter: false,
        );
      }

      // 🏗️ MODULE-FIRST ARCHITECTURE: Check Single Source of Truth
      // Show multi-module screen when:
      // 1. No module is currently selected (selectedModule == null)
      // 2. Multiple modules exist (moduleListLength > 1)
      // This takes priority over configModel.module to ensure user always sees module selection
      // Note: selectedModule already defined above (line 800)
      final bool showMultiModuleScreen = selectedModule == null &&
          splashController.module == null &&
          moduleListLength > 1;

      // Multi-module screen is handled by DashboardScreen.
      if (showMultiModuleScreen) {
        return const SizedBox.shrink();
      }

      // 🏗️ MODULE-FIRST ARCHITECTURE: Handle single module auto-selection
      // Only auto-select if there's exactly 1 module (skip selection screen)
      if (splashController.moduleList != null &&
          splashController.moduleList!.length == 1 &&
          selectedModule == null &&
          splashController.module == null) {
        final singleModule = splashController.moduleList!.first;
        splashController.selectModule(singleModule, context: context);
      }

      // Only use config module if:
      // 1. No module is selected
      // 2. Module list is null or has only 1 module (so we're not bypassing multi-module screen)
      // This ensures configModel doesn't override the multi-module screen choice
      if (splashController.module == null &&
          splashController.configModel != null &&
          splashController.configModel!.module != null &&
          (moduleListLength <= 1)) {
        splashController.setModule(splashController.configModel!.module);
      }

      // ⚡ Cache-First Fix: Show Skeleton if module == null (no module selected)
      // This prevents empty screen on first load when module hasn't been selected yet
      if (splashController.module == null) {
        if (kDebugMode) {
          print('[Cache-First] HomeScreen: Module is null - showing skeleton');
        }
        // Show skeleton while waiting for module selection
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'loading'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      }

      // Show loading screen if module is being determined
      // But only if we don't have data loaded yet
      if (splashController.module == null &&
          splashController.configModel != null &&
          splashController.configModel!.module != null) {
        // Check if we have data loaded - if we do, don't show loading screen
        bool hasData = false;
        try {
          if (Get.isRegistered<BannerController>()) {
            final bannerController = Get.find<BannerController>();
            if (bannerController.bannerImageList != null &&
                bannerController.bannerImageList!.isNotEmpty) {
              hasData = true;
            }
          }
        } catch (e) {
          // Controller not ready yet
        }

        if (!hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(Images.logo_gif, width: 200),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
      }

      final bool showMobileModule = !ResponsiveHelper.isDesktop(context) &&
          splashController.module == null &&
          splashController.configModel!.module == null &&
          !showMultiModuleScreen;

      // Use config module as fallback if module is null
      final ModuleModel? currentModule =
          splashController.module ?? splashController.configModel?.module;

      // bool isParcel = splashController.module != null && splashController.configModel!.moduleConfig!.module!.isParcel!;
      final bool isParcel = currentModule != null &&
          currentModule.moduleType.toString() == AppConstants.parcel;
      final bool isPharmacy = currentModule != null &&
          currentModule.moduleType.toString() == AppConstants.pharmacy;
      final bool isFood = currentModule != null &&
          currentModule.moduleType.toString() == AppConstants.food;
      final bool isShop = currentModule != null &&
          currentModule.moduleType.toString() == AppConstants.ecommerce;

      // Debug logging disabled for performance
      // if (kDebugMode && currentModule != null) {
      //   print('🔍 DEBUG: Module Type: ${currentModule!.moduleType}');
      //   print('🔍 DEBUG: isFood: $isFood');
      //   print('🔍 DEBUG: isShop: $isShop');
      // }
      final bool isGrocery = currentModule != null &&
          currentModule.moduleType.toString() == AppConstants.grocery;
      final bool isTaxi = currentModule != null &&
          currentModule.moduleType.toString() == AppConstants.taxi;

      _logUiStateSnapshot('HomeScreen.build', splashController);

      return GetBuilder<HomeController>(builder: (homeController) {
        final bool showUnifiedHomeError = !isParcel &&
            AppConstants.useBffV2Endpoint &&
            Get.isRegistered<HomeUnifiedController>() &&
            Get.find<HomeUnifiedController>().hasError &&
            !Get.find<HomeUnifiedController>().isLoading &&
            !Get.find<HomeUnifiedController>().hasCachedData;
        return Scaffold(
          appBar: ResponsiveHelper.isDesktop(context)
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(120.0),
                  child: WebMenuBar(),
                )
              : PreferredSize(
                  preferredSize: const Size.fromHeight(140.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.95),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 4,
                      bottom: 2,
                    ),
                    child: FlattenedAppBarContent(
                      // ⚡ TASK 1: Flattened widget tree
                      searchWidget:
                          build_Search(context, showMobileModule, isTaxi),
                      addressWidget: build_Address(context, splashController),
                    ),
                  ),
                ),

          // endDrawer: const MenuDrawer(),
          endDrawerEnableOpenDragGesture: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: isParcel
              ? const ParcelCategoryScreen()
              : showUnifiedHomeError
                  ? ErrorStateView(
                      onRetry: () {
                        if (Get.isRegistered<HomeUnifiedController>()) {
                          Get.find<HomeUnifiedController>().loadHomeData(
                                forceRefresh: true,
                                showLoading: true,
                              );
                        }
                      },
                    )
              : SafeArea(
                  top: false,
                  bottom: true,
                  left: false,
                  right: false,
                  minimum: EdgeInsets.zero,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      splashController.setRefreshing(true);
                      try {
                        await HomeScreen.performHardRefresh(context);
                      } finally {
                        splashController.setRefreshing(false);
                      }
                    },
                    child: ResponsiveHelper.isDesktop(context)
                        ? WebNewHomeScreen(
                            scrollController: scrollController,
                          )
                        : CustomScrollView(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              // Collapsible Module Switcher (only show when module selected and multiple modules exist)
                              GetBuilder<SplashController>(
                                builder: (splashController) {
                                  final hasMultipleModules =
                                      splashController.module != null &&
                                          splashController.moduleList != null &&
                                          splashController.moduleList!.length >
                                              1;

                                  if (!hasMultipleModules || showMobileModule) {
                                    return const SliverToBoxAdapter(
                                        child: SizedBox.shrink());
                                  }

                                  return SliverToBoxAdapter(
                                    child: const ProfessionalModuleStrip(),
                                  );
                                },
                              ),

                              // Module-specific home screens content
                              SliverToBoxAdapter(
                                child: FlattenedModuleContent(
                                  // ⚡ TASK 1: Flattened widget tree
                                  moduleWidget: !showMobileModule
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            isGrocery
                                                ? GroceryHomeScreen()
                                                : isPharmacy
                                                    ? PharmacyHomeScreen()
                                                    : isFood
                                                        ? const FoodHomeScreen()
                                                        : isShop
                                                            ? ShopHomeScreen()
                                                            : isTaxi
                                                                ? TaxiHomeScreen()
                                                                : const SizedBox(),
                                          ],
                                        )
                                      : ModuleView(
                                          splashController: splashController),
                                ),
                              ),

                              // ⚡ UNIFIED: "All Stores" section moved to ShopHomeScreen
                              // This keeps all module-specific content in one place
                            ],
                          ),
                  ),
                ),
          floatingActionButton: AuthHelper.isLoggedIn() &&
                  homeController.cashBackOfferList != null &&
                  homeController.cashBackOfferList!.isNotEmpty
              ? homeController.showFavButton
                  ? Padding(
                      padding: EdgeInsets.only(
                          bottom: 50.0,
                          right: ResponsiveHelper.isDesktop(context) ? 50 : 0),
                      child: InkWell(
                        onTap: () => Get.dialog(const CashBackDialogWidget()),
                        child: const CashBackLogoWidget(),
                      ),
                    )
                  : null
              : null,
        );
      });
    });
  }

  //

  //
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;
  Function(bool isPinned)? callback;
  bool isPinned = false;

  SliverDelegate({required this.child, this.height = 50, this.callback});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    isPinned = shrinkOffset == maxExtent /*|| shrinkOffset < maxExtent*/;
    callback!(isPinned);
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}
