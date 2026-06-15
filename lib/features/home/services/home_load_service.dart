import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_loader.dart';
import 'package:sixam_mart/common/cache/loading_state_manager.dart';
import 'package:sixam_mart/common/cache/preloaded_data_manager.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// 🧹 REFACTOR: Self-contained home data-loading orchestration extracted from
/// `HomeScreen`. These were previously static methods on the widget; the public
/// `HomeScreen.loadData` / `HomeScreen.performHardRefresh` now delegate here so
/// external callers are unaffected. Behaviour is unchanged — pure extraction.
class HomeLoadService {
  HomeLoadService._();

  static bool _isBackgroundRefreshInProgress = false;
  static DateTime? _lastBackgroundRefreshAt;
  static const Duration _backgroundRefreshThrottle = Duration(seconds: 5);

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
            debugPrint(
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
                    debugPrint(
                        '⚠️ HomeScreen.loadData: Critical cache present but banners missing, forcing banner reload');
                  }
                  // Trigger immediate banner fetch for current module.
                  bannerController.getFeaturedBanner();
                }
              }

              if (!hasBannerData) {
                if (kDebugMode) {
                  debugPrint(
                      '⚠️ HomeScreen.loadData: Skipping early return because banners are missing');
                }
                // Fall through to normal loading to recover missing sections.
              } else {
                if (kDebugMode) {
                  debugPrint(
                      '✅ HomeScreen.loadData: Cache restored successfully, skipping API calls');
                }
                // Refresh in background only (without clearing controllers)
                if (!buildContext.mounted) {
                  return;
                }
                refreshInBackground(buildContext);
                return; // Exit early - data is already loaded from cache
              }
            } else {
              if (kDebugMode) {
                debugPrint(
                    '⚠️ HomeScreen.loadData: Cache restored but no critical data, falling back to API');
              }
              // Fall through to normal loading
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
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
  static void refreshInBackground(BuildContext context) {
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
          debugPrint('⚠️ HomeScreen: Background refresh failed - $e');
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
}
