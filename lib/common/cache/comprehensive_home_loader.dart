import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/common/cache/loading_state_manager.dart';
import 'package:sixam_mart/common/cache/preloaded_data_manager.dart';
import 'package:sixam_mart/features/home/controllers/optimized_home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive Home Data Loader
/// Pre-loads ALL home screen sections for truly instant display
class ComprehensiveHomeLoader {
  /// Load all home screen data with comprehensive caching
  static Future<void> loadAllHomeData(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    // ⚠️ CRITICAL: Skip comprehensive loading if we're showing multi-module screen
    // Multi-module screen doesn't need all sections (banners, categories, brands, etc.)
    final splashController = Get.find<SplashController>();
    final moduleList = splashController.moduleList;
    final moduleListLength = moduleList?.length ?? 0;
    final bool showMultiModuleScreen = splashController.module == null &&
        moduleList != null &&
        moduleListLength > 1;
    
    if (showMultiModuleScreen) {
      return; // Don't load any data - MultiModuleHomeScreen will handle its own loading
    }

    final loadingManager = LoadingStateManager();

    // Check if we can start comprehensive loading
    if (!loadingManager.canStartComprehensiveLoading()) {
      return;
    }

    // Start comprehensive loading
    if (!loadingManager.startComprehensiveLoading()) {
      return;
    }

    try {
      // Check if we should use cache
      final useCache =
          !forceRefresh && await ComprehensiveHomeCacheManager.isCacheValid();
      if (!context.mounted) {
        return;
      }

      if (useCache) {
        await _loadFromCache(context);

        // Verify data was actually restored to controllers
        final bool dataRestored = await _verifyDataRestoration();
        if (!dataRestored) {
          if (!context.mounted) {
            return;
          }
          await _loadAllSectionsFromAPI(context);
        } else {
          // Refresh in background only if not already refreshing
          if (!loadingManager.isBackgroundRefreshing) {
            if (!context.mounted) {
              return;
            }
            _refreshAllSectionsInBackground(context);
          }
        }
      } else {
        if (!context.mounted) {
          return;
        }
        await _loadAllSectionsFromAPI(context);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ComprehensiveHomeLoader: Error - $e');
      }
      // Fallback to API loading
      if (!context.mounted) {
        return;
      }
      await _loadAllSectionsFromAPI(context);
    } finally {
      loadingManager.completeComprehensiveLoading();
    }
  }

  /// Load all data from cache
  static Future<void> _loadFromCache(BuildContext context) async {
    try {
      final cachedData = await ComprehensiveHomeCacheManager.loadAllHomeData();
      if (!context.mounted) {
        return;
      }

      if (cachedData.isNotEmpty) {
        // Restore data to controllers directly
        await ComprehensiveHomeCacheManager.restoreDataToControllers(
            cachedData);

      } else {
        await _loadAllSectionsFromAPI(context);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ComprehensiveHomeLoader: Error loading from cache - $e');
      }
      if (!context.mounted) {
        return;
      }
      await _loadAllSectionsFromAPI(context);
    }
  }

  /// Load all sections from API
  static Future<void> _loadAllSectionsFromAPI(BuildContext context) async {
    try {
      // Use individual API calls directly (bootstrap endpoint removed - too slow)

      // ⚡ OPTIMIZATION: Load business settings only if not using v2/home-unified
      // v2/home-unified returns business_settings, so we skip the separate API call
      final homeController = Get.find<HomeController>();
      const usingUnified = AppConstants.useBffV2Endpoint;
      
      if (homeController.business_Settings == null && !usingUnified) {
        await homeController.getBusiness_Settings();
      }

      // ⚡ CRITICAL: Only load sections that are enabled in business settings
      // For module 7, user wants ONLY stores and categories (explicit requirement)
      final splashController = Get.find<SplashController>();
      final businessSettings = homeController.business_Settings;
      
      final sectionsToLoad = <String>[];
      
      // ⚡ MODULE 7 SPECIFIC: Only stores and categories (user's explicit requirement)
      if (splashController.module?.id == 7) {
        if (businessSettings?.categoriesSection?.toString() == '1') {
          sectionsToLoad.add('categories');
        }
        // Stores are always needed for module 7
        sectionsToLoad.add('stores');
      } else {
        // Other modules: load based on business settings ONLY (no bypasses),
        // but never allow a state where *nothing* is loaded for a primary module.
        final String? moduleType =
            splashController.module?.moduleType.toString();
        final bool isEcommerce =
            moduleType == AppConstants.ecommerce;
        final int? moduleId = splashController.module?.id;

        // ⚡ ECOMMERCE MODULE 3: Always try to load categories and stores (check data exists)
        // Then UI will hide if not enabled in business settings or if empty
        if (isEcommerce && moduleId == 3) {
          // Always load both - UI will check business settings and data before showing
          sectionsToLoad.add('categories');
          sectionsToLoad.add('stores');

        } else {
          // Other modules: strict business settings check (no bypasses)
          if (businessSettings?.categoriesSection?.toString() == '1') {
            sectionsToLoad.add('categories');
          }
          if (businessSettings?.popularStoresSection?.toString() == '1') {
            sectionsToLoad.add('stores');
          }
          if (businessSettings?.bannersSection?.toString() == '1') {
            sectionsToLoad.add('banners');
          }
          if (businessSettings?.brandSection?.toString() == '1') {
            sectionsToLoad.add('brands');
          }
          if (businessSettings?.topStoresOffersNearMeSection?.toString() == '1') {
            sectionsToLoad.add('offers');
          }

          // ⚠️ SAFETY NET: If strict business settings disable everything for a core module
          // (food/grocery/pharmacy/ecommerce), fall back to a sensible default so the
          // home screen is never completely empty.
          if (sectionsToLoad.isEmpty &&
              (moduleType == AppConstants.food ||
                  moduleType == AppConstants.grocery ||
                  moduleType == AppConstants.pharmacy ||
                  moduleType == AppConstants.ecommerce)) {
            sectionsToLoad.addAll(<String>['categories', 'banners', 'stores']);
          }
        }
      }

      // Don't load offers, items, campaigns, profile by default for home screen
      // These are only loaded if explicitly needed elsewhere in the app
      
      if (sectionsToLoad.isEmpty) {
        return;
      }

      // ⚡ PERFORMANCE: Sequential loading for ecommerce module 3
      // Categories first (critical), then stores (critical)
      // For other modules, load in priority order
      final isEcommerce = splashController.module?.moduleType.toString() == AppConstants.ecommerce;
      final moduleId = splashController.module?.id;
      const reload = true; // Force reload when loading from API
      const fromModule = false;

      if (isEcommerce && moduleId == 3) {
        // Ecommerce module 3: Parallel loading - categories and stores together (FASTER!)
        final futures = <Future<void>>[];
        if (sectionsToLoad.contains('categories')) {
          futures.add(OptimizedHomeDataLoader.loadCategories(reload));
        }
        if (sectionsToLoad.contains('stores')) {
          futures.add(OptimizedHomeDataLoader.loadStores(reload, fromModule));
        }
        
        if (futures.isNotEmpty) {
          await Future.wait(futures);
        }
      } else {
        // Other modules: Load critical sections first, then non-critical
        final criticalSections = <String>[];
        final nonCriticalSections = <String>[];

        for (final section in sectionsToLoad) {
          if (['categories', 'banners', 'stores'].contains(section)) {
            criticalSections.add(section);
          } else {
            nonCriticalSections.add(section);
          }
        }

        // Phase 1: Load CRITICAL sections (banners + categories) - blocking
        // 🔧 PERF FIX: Stores are at bottom of screen (Section 5), delay them 2 seconds
        // This prevents store 500 errors from blocking banner/category image downloads
        final immediateFutures = <Future<void>>[];
        for (final section in criticalSections) {
          switch (section) {
            case 'banners':
              immediateFutures.add(OptimizedHomeDataLoader.loadBanners(reload));
              break;
            case 'categories':
              immediateFutures.add(OptimizedHomeDataLoader.loadCategories(reload));
              break;
            case 'stores':
              // 🔧 PERF FIX: Delay stores by 2 seconds - they're at bottom of screen
              // Let banners/categories load first (critical first 2 seconds)
              break;
          }
        }

        if (immediateFutures.isNotEmpty) {
          await Future.wait(immediateFutures);
        }

        // 🔧 PERF FIX: Load stores after 2-second delay (Section 5 at bottom)
        if (sectionsToLoad.contains('stores')) {
          Future.delayed(const Duration(seconds: 2), () async {
            try {
              await OptimizedHomeDataLoader.loadStores(reload, fromModule);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ ComprehensiveHomeLoader: Error loading stores (delayed): $e');
              }
            }
          });
        }

        // Phase 2: Load non-critical sections in background (non-blocking)
        if (nonCriticalSections.isNotEmpty) {
          Future.microtask(() async {
            try {
              final nonCriticalFutures = <Future<void>>[];
              for (final section in nonCriticalSections) {
                switch (section) {
                  case 'brands':
                    nonCriticalFutures.add(OptimizedHomeDataLoader.loadBrands(reload));
                    break;
                  case 'offers':
                    nonCriticalFutures.add(OptimizedHomeDataLoader.loadOffers(reload));
                    break;
                }
              }
              if (nonCriticalFutures.isNotEmpty) {
                await Future.wait(nonCriticalFutures);
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ ComprehensiveHomeLoader: Error loading non-critical sections: $e');
              }
            }
          });
        }
      }

      // Save all data to cache
      await ComprehensiveHomeCacheManager.saveAllHomeData();

      // Mark data as preloaded
      PreloadedDataManager().markDataPreloaded();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ComprehensiveHomeLoader: Error loading from API - $e');
      }
    }
  }

  /// Refresh all sections in background
  static void _refreshAllSectionsInBackground(BuildContext context) {
    final loadingManager = LoadingStateManager();

    // Check if background refresh can start
    if (!loadingManager.startBackgroundRefresh()) {
      return;
    }

    Future.delayed(const Duration(seconds: 3), () async {
      try {
        // Use individual API calls for background refresh
        if (!context.mounted) {
          return;
        }
        await _loadAllSectionsFromAPI(context);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ComprehensiveHomeLoader: Background refresh failed - $e');
        }
      } finally {
        loadingManager.completeBackgroundRefresh();
      }
    });
  }

  /// Pre-load specific sections
  static Future<void> preloadSections(
      BuildContext context, List<String> sections) async {
    try {

      // Use the optimized home controller for pre-loading
      if (!context.mounted) {
        return;
      }
      await OptimizedHomeDataLoader.loadData(
        context,
        false, // reload
        specificSections: sections,
      );

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ComprehensiveHomeLoader: Error pre-loading sections - $e');
      }
    }
  }

  /// Clear cache and force refresh
  static Future<void> clearCacheAndRefresh(BuildContext context) async {
    await ComprehensiveHomeCacheManager.clearComprehensiveCache();
    if (!context.mounted) {
      return;
    }
    await loadAllHomeData(context, forceRefresh: true);
  }

  /// Verify that data was actually restored to controllers
  /// Returns true if critical data (categories/stores) is restored
  /// Optional data (banners/brands/offers) missing is acceptable
  static Future<bool> _verifyDataRestoration() async {
    try {
      bool hasCriticalData = false;
      
      // Check critical data: Categories (required for most modules)
      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        if (categoryController.categoryList != null &&
            categoryController.categoryList!.isNotEmpty) {
          hasCriticalData = true;
        }
      }

      // Check critical data: Stores (required for most modules)
      if (Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        if (storeController.storeModel != null &&
            storeController.storeModel!.stores != null &&
            storeController.storeModel!.stores!.isNotEmpty) {
          hasCriticalData = true;
        }
      }

      // Optional data: Banners (not critical - can load from API in background)
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        if (bannerController.bannerImageList != null &&
            bannerController.bannerImageList!.isNotEmpty) {
        }
      }

      // Optional data: Brands (not critical)
      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        if (brandsController.brandList != null &&
            brandsController.brandList!.isNotEmpty) {
        }
      }

      // Optional data: Offers (not critical)
      if (Get.isRegistered<OffersController>()) {
        final offersController = Get.find<OffersController>();
        if (offersController.offersMode != null &&
            offersController.offersMode!.data.isNotEmpty) {
        }
      }

      if (hasCriticalData) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ComprehensiveHomeLoader: Error verifying data restoration - $e');
      }
      return false;
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    return await ComprehensiveHomeCacheManager.getCacheStats();
  }

  /// Check if specific section is cached
  static Future<bool> isSectionCached(String section) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      switch (section) {
        case 'banners':
          return prefs.containsKey('comprehensive_banner_cache');
        case 'categories':
          return prefs.containsKey('comprehensive_category_cache');
        case 'brands':
          return prefs.containsKey('comprehensive_brand_cache');
        case 'offers':
          return prefs.containsKey('comprehensive_offer_cache');
        case 'stores':
          return prefs.containsKey('comprehensive_store_cache');
        case 'businessSettings':
          return prefs.containsKey('comprehensive_business_settings_cache');
        default:
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ComprehensiveHomeLoader: Error checking section cache - $e');
      }
      return false;
    }
  }
}
