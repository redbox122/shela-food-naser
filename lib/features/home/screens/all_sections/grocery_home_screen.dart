import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';

class GroceryHomeScreen extends StatefulWidget {
  const GroceryHomeScreen({super.key});
  
  @override
  State<GroceryHomeScreen> createState() => _GroceryHomeScreenState();
}

class _GroceryHomeScreenState extends State<GroceryHomeScreen> {
  bool _hasCachedData = false;
  // ⚡ TASK 2: Performance benchmarking
  late Stopwatch _renderStopwatch;
  bool _hasLoggedRenderTime = false;

  @override
  void initState() {
    super.initState();
    appLogger.logPageEntry('GroceryHomeScreen');
    appLogger.info('🏠 GroceryHomeScreen: Initializing');
    appLogger.debug('GroceryHomeScreen: Module Type = Grocery');
    appLogger.debug('GroceryHomeScreen: Starting initialization sequence');
    
    // ⚡ TASK 2: Start performance stopwatch
    _renderStopwatch = Stopwatch()..start();
    
    // ⚡ SWR: Load cached data IMMEDIATELY for zero-latency rendering
    _loadCachedDataForInstantUI();
  }
  
  @override
  void dispose() {
    appLogger.logPageExit();
    appLogger.info('🏠 GroceryHomeScreen: Disposed');
    super.dispose();
  }

  /// ⚡ SWR: Load cached data from HomeUnifiedController for instant UI rendering
  Future<void> _loadCachedDataForInstantUI() async {
    appLogger.debug('GroceryHomeScreen: _loadCachedDataForInstantUI() called');
    appLogger.debug('GroceryHomeScreen: useBffV2Endpoint = ${AppConstants.useBffV2Endpoint}');
    
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('GroceryHomeScreen: BFF v2 endpoint disabled, skipping cache load');
      return;
    }
    
    try {
      if (Get.isRegistered<HomeUnifiedController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        appLogger.debug('GroceryHomeScreen: HomeUnifiedController found, loading cached data');
        
        // ⚡ INSTANT: Load cached data synchronously
        final hasCache = await unifiedController.loadCachedDataForInstantUI();
        if (hasCache) {
          _hasCachedData = true;
          appLogger.info('⚡ GroceryHomeScreen: Cached data loaded - UI will render instantly');
          appLogger.debug('GroceryHomeScreen: Cache status - hasCachedData = true');
          
          // Trigger background refresh (SWR pattern)
          _refreshInBackground();
        } else {
          appLogger.warning('⚠️ GroceryHomeScreen: No cached data found, will show loading shimmer');
          appLogger.debug('GroceryHomeScreen: Cache status - hasCachedData = false');
          _refreshInBackground();
        }
      } else {
        appLogger.warning('GroceryHomeScreen: HomeUnifiedController not registered');
      }
    } catch (e, stackTrace) {
      appLogger.error('⚠️ GroceryHomeScreen: Error loading cached data', e, stackTrace);
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
    appLogger.debug('GroceryHomeScreen: _loadData() called with reload=$reload');
    
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('GroceryHomeScreen: BFF v2 endpoint disabled, skipping data load');
      return;
    }
    
    try {
      if (Get.isRegistered<HomeUnifiedController>() && 
          Get.isRegistered<SplashController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        final splashController = Get.find<SplashController>();
        
        final moduleId = splashController.module?.id;
        appLogger.debug('GroceryHomeScreen: Module ID = $moduleId');
        appLogger.info('GroceryHomeScreen: Starting V2 data load (top sections: Banners/Categories)');
        
        // 1. Trigger V2 for Top Sections (Banners/Categories)
        await unifiedController.loadHomeData(
          moduleId: moduleId,
          forceRefresh: reload,
          showLoading: false, // Silent refresh - no loading indicator
        );
        
        appLogger.info('✅ GroceryHomeScreen: V2 data loaded (top sections)');
        appLogger.debug('GroceryHomeScreen: V2 load complete - Banners and Categories should be available');
        
        // 2. HARD RESET & TRIGGER LEGACY for the bottom section
        // This ensures we get the real total_size (300+) every time we enter
        // V2 must NEVER touch storeModel - only popularStoreList for top sections
        if (Get.isRegistered<StoreController>()) {
          final storeController = Get.find<StoreController>();
          final homeController = Get.find<HomeController>();
          final settings = homeController.business_Settings;
          
          // Only load if "All Restaurants" section is enabled
          final allRestaurantsEnabled = settings?.allRestaurantsSection?.toString() == '1' ||
              (settings?.allRestaurantsSection is int && settings?.allRestaurantsSection == 1);
          
          appLogger.debug('GroceryHomeScreen: allRestaurantsSection enabled = $allRestaurantsEnabled');
          
          if (allRestaurantsEnabled) {
            if (AppConstants.useBffV2Endpoint) {
              appLogger.info(
                  '🛡️ GroceryHomeScreen: Unified-only policy - skipping legacy allStoreModel fetch');
              return;
            }
            appLogger.info('📡 GroceryHomeScreen: Initializing legacy pagination engine (allStoreModel)');
            appLogger.debug('GroceryHomeScreen: reload=true ensures clean state and correct totalSize (300+)');
            appLogger.debug('GroceryHomeScreen: Calling storeController.getStoreList(1, true)');
            
            // Use reload: true to ensure we get the TRUE totalSize from API (300+)
            // This clears old module data and fetches fresh data
            await storeController.getStoreList(1, true);
            
            // ⚡ TASK 1: Use allStoreModel instead of storeModel for paginated data
            final totalSize = storeController.allStoreModel?.totalSize;
            appLogger.info('✅ GroceryHomeScreen: Legacy pagination engine initialized (totalSize: $totalSize)');
            appLogger.debug('GroceryHomeScreen: Store list loaded - stores count: ${storeController.allStoreModel?.stores?.length ?? 0}');
          } else {
            appLogger.debug('GroceryHomeScreen: All Restaurants section disabled, skipping store list load');
          }
        } else {
          appLogger.warning('GroceryHomeScreen: StoreController not registered');
        }
      } else {
        appLogger.warning('GroceryHomeScreen: Required controllers not registered');
      }
    } catch (e, stackTrace) {
      appLogger.error('⚠️ GroceryHomeScreen: Data loading failed', e, stackTrace);
    }
  }

  /// ⚡ SWR: Refresh data in background (silent update)
  /// ⚡ PERFORMANCE: Skip refresh if cache is fresh (< 5 seconds old)
  /// Grocery module doesn't need aggressive refresh like Food module
  void _refreshInBackground() {
    appLogger.debug('GroceryHomeScreen: _refreshInBackground() called');
    appLogger.debug('GroceryHomeScreen: _hasCachedData = $_hasCachedData');
    
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('GroceryHomeScreen: BFF v2 endpoint disabled, skipping background refresh');
      return;
    }
    
    // ⚡ PERFORMANCE: If we have fresh cached data, delay or skip refresh
    // Grocery stores don't change frequently - no need for instant refresh
    if (_hasCachedData) {
      // Delay refresh by 5-10 seconds for Grocery (less urgent than Food)
      Future.delayed(const Duration(seconds: 5), () async {
        if (mounted) {
          appLogger.debug('GroceryHomeScreen: Delayed background refresh started (cache was fresh)');
          await _loadData(false); // Silent refresh - don't force reload
          appLogger.debug('GroceryHomeScreen: Delayed background refresh complete');
        }
      });
    } else {
      // No cache - refresh immediately
      Future.delayed(const Duration(milliseconds: 100), () async {
        if (mounted) {
          appLogger.debug('GroceryHomeScreen: Starting background refresh (no cache)');
          await _loadData(true); // Force reload if no cache
          appLogger.debug('GroceryHomeScreen: Background refresh complete');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    appLogger.debug('GroceryHomeScreen: build() called');
    
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
                  (settings.categoriesSection is int && settings.categoriesSection == 1)) {
                sectionCount++;
              }
            }
          } catch (e) {
            // Ignore errors in counting
          }
          
          appLogger.info('⚡ GroceryHomeScreen Sync-UI: Rendered with $sectionCount sections in ${renderTime}ms');
          _hasLoggedRenderTime = true;
        }
      });
    }
    
    // ⚡ BFF API v2: Wrap in GetBuilder for HomeUnifiedController
    // Shows shimmer only if no cached data AND loading
    return GetBuilder<HomeUnifiedController>(
      builder: (unifiedController) {
        appLogger.debug('GroceryHomeScreen: HomeUnifiedController state - hasCachedData=${unifiedController.hasCachedData}, isLoading=${unifiedController.isLoading}');

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
          appLogger.debug('GroceryHomeScreen: Showing loading indicator (no cache, still loading)');
          return const Center(child: CircularProgressIndicator());
        }

        return GetBuilder<HomeController>(builder: (homeController) {
          final settings = homeController.business_Settings;

          appLogger.debug('GroceryHomeScreen: Building UI sections');
          appLogger.debug('GroceryHomeScreen: Business settings - categoriesSection=${settings?.categoriesSection}');

          if (settings == null) {
            appLogger.warning('GroceryHomeScreen: Business settings is null - falling back to data-driven sections');
          }

          return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
          // Categories section - check business_settings flag
          GetBuilder<CategoryController>(
            builder: (categoryController) {
              final isEnabled = settings == null ||
                  (settings.categoriesSection?.toString() == '1' ||
                      (settings.categoriesSection is int &&
                          settings.categoriesSection == 1));
              final hasData = categoryController.categoryList != null && 
                  categoryController.categoryList!.isNotEmpty;
              return (isEnabled && hasData) ? const CategoryView() : const SizedBox.shrink();
            },
          ),

        ],
      );
        });
      },
    );
  }
}
