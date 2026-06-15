import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart';
import 'package:sixam_mart/features/home/widgets/views/top_restaurants_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';

class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen> {
  // ⚡ BFF API v2: Simplified state - all loading handled by HomeUnifiedController
  bool _hasCachedData = false;
  Worker? _moduleWorker;
  int? _lastModuleId;
  // ⚡ TASK 2: Performance benchmarking
  late Stopwatch _renderStopwatch;
  bool _hasLoggedRenderTime = false;

  @override
  void initState() {
    super.initState();
    appLogger.logPageEntry('FoodHomeScreen');
    appLogger.info('🏠 FoodHomeScreen: Initializing');
    appLogger.debug('FoodHomeScreen: Module Type = Food');
    appLogger.debug('FoodHomeScreen: Starting initialization sequence');

    // ⚡ TASK 2: Start performance stopwatch
    _renderStopwatch = Stopwatch()..start();

    // ⚡ SWR: Load cached data IMMEDIATELY for zero-latency rendering
    _loadCachedDataForInstantUI();

    // Listen for module changes to refresh UI when switching between food modules
    if (Get.isRegistered<SplashController>()) {
      final splashController = Get.find<SplashController>();
      _lastModuleId = splashController.selectedModule.value?.id ??
          splashController.module?.id;
      _moduleWorker = ever(splashController.selectedModule, (module) {
        final newModuleId = module?.id ?? splashController.module?.id;
        if (newModuleId == null || newModuleId == _lastModuleId) {
          return;
        }
        _lastModuleId = newModuleId;
        if (mounted) {
          setState(() {
            _hasCachedData = false;
            _hasLoggedRenderTime = false;
            _renderStopwatch = Stopwatch()..start();
          });
        }
        _loadCachedDataForInstantUI();
      });
    }

    // ⚡ BFF API v2: All data loading is handled by HomeUnifiedController
    // No need for individual API calls - unified endpoint handles everything
  }

  @override
  void dispose() {
    _moduleWorker?.dispose();
    appLogger.logPageExit();
    appLogger.info('🏠 FoodHomeScreen: Disposed');
    super.dispose();
  }

  /// ⚡ SWR: Load cached data from HomeUnifiedController for instant UI rendering
  /// This runs synchronously in initState to show UI before first frame
  Future<void> _loadCachedDataForInstantUI() async {
    appLogger.debug('FoodHomeScreen: _loadCachedDataForInstantUI() called');
    appLogger.debug(
        'FoodHomeScreen: useBffV2Endpoint = ${AppConstants.useBffV2Endpoint}');

    // Only use unified endpoint if feature flag is enabled
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug(
          'FoodHomeScreen: BFF v2 endpoint disabled, skipping cache load');
      return;
    }

    try {
      if (Get.isRegistered<HomeUnifiedController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        appLogger.debug(
            'FoodHomeScreen: HomeUnifiedController found, loading cached data');

        // ⚡ INSTANT: Load cached data synchronously
        final hasCache = await unifiedController.loadCachedDataForInstantUI(
            loadStores: true);
        if (hasCache) {
          if (mounted) {
            setState(() {
              _hasCachedData = true;
            });
          } else {
            _hasCachedData = true;
          }
          appLogger.info(
              '⚡ FoodHomeScreen: Cached data loaded - UI will render instantly');
          appLogger
              .debug('FoodHomeScreen: Cache status - hasCachedData = true');

          // Trigger background refresh (SWR pattern)
          _refreshInBackground();
        } else {
          if (mounted) {
            setState(() {
              _hasCachedData = false;
            });
          } else {
            _hasCachedData = false;
          }
          appLogger.warning(
              '⚠️ FoodHomeScreen: No cached data found, will show loading shimmer');
          appLogger
              .debug('FoodHomeScreen: Cache status - hasCachedData = false');
          // No cache - trigger normal load
          _refreshInBackground();
        }
      } else {
        appLogger
            .warning('FoodHomeScreen: HomeUnifiedController not registered');
      }
    } catch (e, stackTrace) {
      appLogger.error(
          '⚠️ FoodHomeScreen: Error loading cached data', e, stackTrace);
      // Fallback to normal load
      _refreshInBackground();
    }
  }

  /// Standardized data loading method for module entry
  ///
  /// [reload] - If true, forces fresh data fetch bypassing cache
  ///
  /// This method ensures:
  /// 1. V2 loads top sections (Banners/Categories) via HomeUnifiedController
  /// 2. Legacy engine loads bottom section (All Restaurants) with correct totalSize (300+)
  /// 3. Each module entry is a clean slate - no state contamination
  Future<void> _loadData(bool reload) async {
    appLogger.debug('FoodHomeScreen: _loadData() called with reload=$reload');

    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug(
          'FoodHomeScreen: BFF v2 endpoint disabled, skipping data load');
      return;
    }

    try {
      if (Get.isRegistered<HomeUnifiedController>() &&
          Get.isRegistered<SplashController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        final splashController = Get.find<SplashController>();

        final moduleId = splashController.module?.id;
        appLogger.debug('FoodHomeScreen: Module ID = $moduleId');
        appLogger.info(
            'FoodHomeScreen: Starting V2 data load (top sections: Banners/Categories)');

        // 1. Trigger V2 for Top Sections (Banners/Categories)
        appLogger.info(
            '📡 FoodHomeScreen: Calling HomeUnifiedController.loadHomeData()');
        appLogger.debug(
            '   📋 Request params: moduleId=$moduleId, forceRefresh=$reload, showLoading=false');
        appLogger.debug(
            '   🎯 Target endpoint: ${AppConstants.useBffV2Endpoint ? "BFF v2 /home-unified" : "Legacy endpoints"}');

        final loadStartTime = DateTime.now();
        await unifiedController.loadHomeData(
          moduleId: moduleId,
          forceRefresh: reload,
          showLoading: false, // Silent refresh - no loading indicator
        );
        final loadDuration =
            DateTime.now().difference(loadStartTime).inMilliseconds;

        appLogger.info(
            '✅ FoodHomeScreen: V2 data loaded (top sections) in ${loadDuration}ms');
        appLogger.debug(
            'FoodHomeScreen: V2 load complete - Banners and Categories should be available');

        // 📊 DETAILED API RESPONSE LOGGING
        appLogger.debug('📊 FoodHomeScreen: V2 API Response Details:');
        appLogger.debug(
            '   - UnifiedController.hasCachedData: ${unifiedController.hasCachedData}');
        appLogger.debug(
            '   - UnifiedController.isLoading: ${unifiedController.isLoading}');
        appLogger.debug(
            '   - UnifiedController.unifiedData != null: ${unifiedController.unifiedData != null}');

        if (unifiedController.unifiedData != null) {
          final data = unifiedController.unifiedData!;
          appLogger.debug('   - UnifiedData structure:');
          appLogger.debug('     • banners: ${data.banners?.length ?? 0} items');
          appLogger.debug(
              '     • categories: ${data.categories?.length ?? 0} items');
          appLogger.debug(
              '     • popularStores: ${data.popularStores?.length ?? 0} items');

          // Log first few items of each section
          if (data.banners != null && data.banners!.isNotEmpty) {
            appLogger
                .debug('     • First banner: id=${data.banners!.first.id}');
          }
          if (data.categories != null && data.categories!.isNotEmpty) {
            appLogger.debug(
                '     • First category: id=${data.categories!.first.id}, name=${data.categories!.first.name}');
          }
          if (data.popularStores != null && data.popularStores!.isNotEmpty) {
            appLogger.debug(
                '     • First store: id=${data.popularStores!.first.id}, name=${data.popularStores!.first.name}');
          }
        }

        // Log controller states after V2 load
        appLogger.debug('📊 FoodHomeScreen: Controller States After V2 Load:');
        if (Get.isRegistered<BannerController>()) {
          final bannerController = Get.find<BannerController>();
          appLogger.debug('   - BannerController:');
          appLogger.debug(
              '     • bannerImageList: ${bannerController.bannerImageList?.length ?? 0} items');
          appLogger.debug(
              '     • featuredBannerList: ${bannerController.featuredBannerList?.length ?? 0} items');
        }
        if (Get.isRegistered<CategoryController>()) {
          final categoryController = Get.find<CategoryController>();
          appLogger.debug('   - CategoryController:');
          appLogger.debug(
              '     • categoryList: ${categoryController.categoryList?.length ?? 0} items');
        }

        // 2. Load store sections only when enabled by business settings.
        if (Get.isRegistered<StoreController>()) {
          final storeController = Get.find<StoreController>();
          final homeController = Get.find<HomeController>();
          final settings = homeController.business_Settings;

          final topRestaurantsEnabled = settings == null ||
              (settings.topRestaurantsSection?.toString() == '1' ||
                  (settings.topRestaurantsSection is int &&
                      settings.topRestaurantsSection == 1));
          appLogger
              .debug('FoodHomeScreen: topRestaurants=$topRestaurantsEnabled');

          if (topRestaurantsEnabled &&
              storeController.popularStoreList == null &&
              !storeController.isLoading) {
            appLogger
                .info('📡 FoodHomeScreen: Loading popular stores for Home');
            await storeController.getPopularStoreList(false, 'all', false);
          }
        } else {
          appLogger.warning('FoodHomeScreen: StoreController not registered');
        }
      } else {
        appLogger
            .warning('FoodHomeScreen: Required controllers not registered');
      }
    } catch (e, stackTrace) {
      appLogger.error('❌ FoodHomeScreen: Data loading failed', e, stackTrace);
      appLogger.debug('   📋 Error Details:');
      appLogger.debug('     • Error type: ${e.runtimeType}');
      appLogger.debug('     • Error message: $e');
      appLogger.debug('     • Stack trace: $stackTrace');

      // Log controller states on error
      appLogger.debug('   📊 Controller States on Error:');
      appLogger.debug(
          '     • HomeUnifiedController registered: ${Get.isRegistered<HomeUnifiedController>()}');
      appLogger.debug(
          '     • StoreController registered: ${Get.isRegistered<StoreController>()}');
      appLogger.debug(
          '     • SplashController registered: ${Get.isRegistered<SplashController>()}');
      if (Get.isRegistered<SplashController>()) {
        try {
          final splashController = Get.find<SplashController>();
          appLogger.debug('     • Module ID: ${splashController.module?.id}');
          appLogger.debug(
              '     • Module Type: ${splashController.module?.moduleType}');
        } catch (err) {
          appLogger.debug('     • Error getting module: $err');
        }
      }
    }
  }

  /// ⚡ SWR: Refresh data in background (silent update)
  void _refreshInBackground() {
    appLogger.debug('FoodHomeScreen: _refreshInBackground() called');
    appLogger.debug('FoodHomeScreen: _hasCachedData = $_hasCachedData');

    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug(
          'FoodHomeScreen: BFF v2 endpoint disabled, skipping background refresh');
      return;
    }

    // Delay to ensure UI has rendered first
    Future.delayed(const Duration(milliseconds: 100), () async {
      appLogger.debug(
          'FoodHomeScreen: Starting background refresh (reload=${!_hasCachedData})');
      await _loadData(!_hasCachedData);
      appLogger.debug('FoodHomeScreen: Background refresh complete');
    });
  }

  // ⚡ BFF API v2: Removed _loadInitialData() and _loadFeaturedBanners()
  // All data is now loaded via HomeUnifiedController using unified endpoint
  // Individual API calls are no longer needed

  @override
  Widget build(BuildContext context) {
    appLogger.debug('FoodHomeScreen: build() called');

    // ⚡ TASK 2: Log render time and section count after first frame
    if (!_hasLoggedRenderTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasLoggedRenderTime && mounted) {
          _renderStopwatch.stop();
          final renderTime = _renderStopwatch.elapsedMilliseconds;

          // Count enabled sections
          int sectionCount = 0;
          try {
            final homeController = Get.find<HomeController>();
            final settings = homeController.business_Settings;

            if (settings != null) {
              if (settings.categoriesSection?.toString() == '1' ||
                  (settings.categoriesSection is int &&
                      settings.categoriesSection == 1)) {
                sectionCount++;
              }
              if (settings.bannersSection?.toString() == '1' ||
                  (settings.bannersSection is int &&
                      settings.bannersSection == 1)) {
                sectionCount++;
              }
              if (settings.topRestaurantsSection?.toString() == '1' ||
                  (settings.topRestaurantsSection is int &&
                      settings.topRestaurantsSection == 1)) {
                sectionCount++;
              }
              if (settings.allRestaurantsSection?.toString() == '1' ||
                  (settings.allRestaurantsSection is int &&
                      settings.allRestaurantsSection == 1)) {
                sectionCount++;
              }
            }
          } catch (e) {
            // Ignore errors in counting
          }

          appLogger.info(
              '⚡ FoodHomeScreen Sync-UI: Rendered with $sectionCount sections in ${renderTime}ms');
          _hasLoggedRenderTime = true;
        }
      });
    }

    // ⚡ BFF API v2: Wrap in GetBuilder for HomeUnifiedController
    // Shows shimmer only if no cached data AND loading
    return GetBuilder<HomeUnifiedController>(
      assignId: true, // ⚡ TASK 1: Prevents rebuild storms
      builder: (unifiedController) {
        appLogger.debug(
            'FoodHomeScreen: HomeUnifiedController state - hasCachedData=${unifiedController.hasCachedData}, isLoading=${unifiedController.isLoading}');

        if (unifiedController.hasError && !unifiedController.isLoading) {
          return ErrorStateView(
            onRetry: () {
              unifiedController.loadHomeData(
                forceRefresh: true,
                showLoading: true,
              );
            },
          );
        }

        // Show shimmer if no cached data and still loading
        if (!unifiedController.hasCachedData && unifiedController.isLoading) {
          appLogger.debug(
              'FoodHomeScreen: Showing loading indicator (no cache, still loading)');
          return const Center(child: CircularProgressIndicator());
        }

        return GetBuilder<HomeController>(
          builder: (homeController) {
            return GetBuilder<SplashController>(
              builder: (splashController) {
                final settings = homeController.business_Settings;
                final topRestaurantsEnabled = settings == null ||
                    (settings.topRestaurantsSection?.toString() == '1' ||
                        (settings.topRestaurantsSection is int &&
                            settings.topRestaurantsSection == 1));

                appLogger.debug('FoodHomeScreen: Building UI sections');
                appLogger.debug(
                    'FoodHomeScreen: Business settings - categoriesSection=${settings?.categoriesSection}, bannersSection=${settings?.bannersSection}, topRestaurantsSection=${settings?.topRestaurantsSection}, allRestaurantsSection=${settings?.allRestaurantsSection}');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Categories - ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
                    // 2. Banners - ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
                    // ⚡ TASK 2: Defensive UI guard - check registration before access
                    // 🎨 REDESIGN: Banner moved to the top of HomeScreen (above
                    // services), so the module-level banner is hidden here to
                    // avoid showing it twice.
                    const SizedBox.shrink(),
                    // ⚡ TASK 2: Defensive UI guard - check registration before access
                    !Get.isRegistered<CategoryController>()
                        ? const CategoryShimmer()
                        : GetBuilder<CategoryController>(
                            id: 'category_section', // ⚡ TASK 1: Prevents rebuild storms
                            builder: (categoryController) {
                              // ⚡ SWR: Only show shimmer if no cached data AND data is null
                              if (categoryController.categoryList == null &&
                                  !_hasCachedData) {
                                return const CategoryShimmer();
                              }

                              final isEnabled = settings == null ||
                                  (settings.categoriesSection?.toString() ==
                                          '1' ||
                                      (settings.categoriesSection is int &&
                                          settings.categoriesSection == 1));
                              final hasData = categoryController.categoryList !=
                                      null &&
                                  categoryController.categoryList!.isNotEmpty;

                              // Show if enabled in business_settings AND has data
                              return (isEnabled && hasData)
                                  ? const CategoryView()
                                  : const SizedBox.shrink();
                            },
                          ),

                    // 3. Top Restaurants - show shimmer while loading, hide only if empty
                    // ⚡ TASK 2: Defensive UI guard - check registration before access
                    !Get.isRegistered<StoreController>()
                        ? const SizedBox.shrink()
                        : GetBuilder<StoreController>(
                            id: 'popular_restaurants', // ⚡ TASK 1: Prevents rebuild storms
                            builder: (storeController) {
                              if (!topRestaurantsEnabled) {
                                return const SizedBox.shrink();
                              }
                              final list = storeController.popularStoreList;
                              // If still loading, show light shimmer
                              if (list == null) {
                                return const TopRestaurantsViewWidget();
                              }
                              // If API returned empty list, hide section
                              if (list.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return const TopRestaurantsViewWidget();
                            },
                          ),

                    // 4. Promotional Banner - صور التخفيضات الصغيرة في الأسفل
                    // ⚡ TASK 2: Defensive UI guard - check registration before access
                    !Get.isRegistered<BannerController>()
                        ? const SizedBox.shrink()
                        : GetBuilder<BannerController>(
                            builder: (bannerController) {
                              final hasPromotionalBannerData =
                                  bannerController.promotionalBanner != null &&
                                      bannerController.promotionalBanner!
                                              .bottomSectionBannerFullUrl !=
                                          null;
                              return hasPromotionalBannerData
                                  ? const Padding(
                                      padding: EdgeInsets.only(
                                        top: Dimensions.paddingSizeDefault,
                                      ),
                                      child: PromotionalBannerView(),
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                    // Intentionally hidden: "All Restaurants" section removed from home
                    // to avoid heavy pagination jank. Users can still open full list via "See All".
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
