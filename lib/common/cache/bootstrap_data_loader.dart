import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/bootstrap_model.dart';
import 'package:sixam_mart/common/services/bootstrap_service.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';

/// ⚠️ DEPRECATED: This loader is no longer used.
/// Bootstrap endpoint (/api/v1/bootstrap) has been replaced by:
/// - /api/v1/app-init (for startup config)
/// - /api/v2/home-unified (for home screen data)
/// 
/// Bootstrap Data Loader
/// Loads all home screen data from the consolidated bootstrap endpoint
/// and distributes it to appropriate controllers
@Deprecated('Use AppInitService for startup and HomeUnifiedController for home data')
class BootstrapDataLoader {
  /// Load all home screen data from bootstrap endpoint
  ///
  /// Returns true if bootstrap was successful, false if it failed (should fallback to individual calls)
  static Future<bool> loadBootstrapData({
    bool forceRefresh = false,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 BootstrapDataLoader: Starting bootstrap data load');
      }

      final apiClient = Get.find<ApiClient>();
      final bootstrapService = BootstrapService(apiClient: apiClient);

      // Call bootstrap endpoint
      final bootstrapModel = await bootstrapService.getBootstrapData(
        forceRefresh: forceRefresh,
      );

      // Handle bootstrap failure (404, 500, etc.) - null indicates error
      if (bootstrapModel == null) {
        if (kDebugMode) {
          debugPrint(
              '❌ BootstrapDataLoader: Bootstrap endpoint failed (404/500/etc.) - falling back to individual calls');
        }
        return false; // Signal failure - should fallback to individual calls
      }

      // Handle 304 Not Modified (empty model with no critical sections indicates 304)
      // 304 returns an empty BootstrapModel() instance, not null
      if (!bootstrapModel.hasCriticalSections() &&
          bootstrapModel.businessSettings == null &&
          bootstrapModel.banners == null &&
          bootstrapModel.categories == null &&
          bootstrapModel.storesPopular == null &&
          !forceRefresh) {
        if (kDebugMode) {
          debugPrint(
              '✅ BootstrapDataLoader: 304 Not Modified - data unchanged, using cached data');
        }
        return true; // Signal success - cached data should be used
      }

      if (kDebugMode) {
        debugPrint('✅ BootstrapDataLoader: Bootstrap data received successfully');
        debugPrint(
            '   - Business Settings: ${bootstrapModel.businessSettings != null ? "✓" : "✗"}');
        debugPrint('   - Banners: ${bootstrapModel.banners != null ? "✓" : "✗"}');
        debugPrint('   - Categories: ${bootstrapModel.categories?.length ?? 0}');
        debugPrint(
            '   - Stores Popular: ${bootstrapModel.storesPopular?.stores?.length ?? 0}');
        debugPrint('   - Stores: ${bootstrapModel.stores?.stores?.length ?? 0}');
        debugPrint('   - Brands: ${bootstrapModel.brands?.length ?? 0}');
        debugPrint('   - Offers: ${bootstrapModel.offers?.data.length ?? 0}');
      }

      // Distribute data to controllers
      await _distributeDataToControllers(bootstrapModel);

      if (kDebugMode) {
        debugPrint(
            '✅ BootstrapDataLoader: Data distributed to controllers successfully');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ BootstrapDataLoader: Error loading bootstrap data');
        debugPrint('   - Error: $e');
        debugPrint('   - Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Distribute bootstrap data to appropriate controllers
  static Future<void> _distributeDataToControllers(
      BootstrapModel bootstrapModel) async {
    try {
      // Phase 1: Critical sections (load immediately)
      await _loadCriticalSections(bootstrapModel);

      // Phase 2: Secondary sections (load after critical)
      await _loadSecondarySections(bootstrapModel);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ BootstrapDataLoader: Error distributing data to controllers: $e');
      }
    }
  }

  /// Load critical sections (business settings, banners, categories, popular stores)
  /// ⚡ PERFORMANCE: These are synchronous operations, execute immediately
  static Future<void> _loadCriticalSections(
      BootstrapModel bootstrapModel) async {
    try {
      // ⚡ BFF API v2: Business Settings should come from /api/v2/home-unified
      // The bootstrap/app-init endpoint is missing new section flags:
      // - offers_section, all_stores_section, top_restaurants_section, all_restaurants_section
      // HomeUnifiedController will set business_settings from v2 API response
      // DO NOT load business_settings from bootstrap to avoid overwriting v2 data
      // if (bootstrapModel.businessSettings != null &&
      //     Get.isRegistered<HomeController>()) {
      //   final homeController = Get.find<HomeController>();
      //   homeController
      //       .setBusinessSettingsFromBootstrap(bootstrapModel.businessSettings!);
      //   if (kDebugMode) {
      //     debugPrint('✅ BootstrapDataLoader: Business settings loaded');
      //   }
      // }

      // Banners
      if (bootstrapModel.banners != null &&
          Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        bannerController.setBannerDataFromBootstrap(bootstrapModel.banners!);
        if (kDebugMode) {
          debugPrint('✅ BootstrapDataLoader: Banners loaded');
        }
      }

      // Categories - CRITICAL: Load immediately for UI
      // ⚡ PERFORMANCE: Ensure CategoryController is instantiated (lazy-loaded)
      if (bootstrapModel.categories != null &&
          bootstrapModel.categories!.isNotEmpty) {
        try {
          // Ensure controller is instantiated (Get.find will instantiate if lazy-loaded)
          final categoryController = Get.find<CategoryController>();
          categoryController
              .setCategoryDataFromBootstrap(bootstrapModel.categories!);
          if (kDebugMode) {
            debugPrint(
                '✅ BootstrapDataLoader: Categories loaded (${bootstrapModel.categories!.length})');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ BootstrapDataLoader: CategoryController not available: $e');
          }
        }
      }

      // Popular Stores - CRITICAL: Load immediately for UI
      if (bootstrapModel.storesPopular != null &&
          bootstrapModel.storesPopular!.stores != null &&
          bootstrapModel.storesPopular!.stores!.isNotEmpty &&
          Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        storeController
            .setPopularStoresFromBootstrap(bootstrapModel.storesPopular!);
        if (kDebugMode) {
          debugPrint(
              '✅ BootstrapDataLoader: Popular stores loaded (${bootstrapModel.storesPopular!.stores!.length})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BootstrapDataLoader: Error loading critical sections: $e');
      }
    }
  }

  /// Load secondary sections (all stores, brands, offers)
  /// ⚡ PERFORMANCE: These are synchronous operations, execute immediately
  static Future<void> _loadSecondarySections(
      BootstrapModel bootstrapModel) async {
    try {
      // All Stores
      if (bootstrapModel.stores != null &&
          bootstrapModel.stores!.stores != null &&
          Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        storeController.setStoreDataFromBootstrap(bootstrapModel.stores!);
        if (kDebugMode) {
          debugPrint(
              '✅ BootstrapDataLoader: All stores loaded (${bootstrapModel.stores!.stores!.length})');
        }
      }

      // Latest Stores
      if (bootstrapModel.storesLatest != null &&
          bootstrapModel.storesLatest!.stores != null &&
          Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        storeController
            .setLatestStoresFromBootstrap(bootstrapModel.storesLatest!);
        if (kDebugMode) {
          debugPrint(
              '✅ BootstrapDataLoader: Latest stores loaded (${bootstrapModel.storesLatest!.stores!.length})');
        }
      }

      // Brands
      if (bootstrapModel.brands != null &&
          bootstrapModel.brands!.isNotEmpty &&
          Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        brandsController.setBrandDataFromBootstrap(bootstrapModel.brands!);
        if (kDebugMode) {
          debugPrint(
              '✅ BootstrapDataLoader: Brands loaded (${bootstrapModel.brands!.length})');
        }
      }

      // Offers
      if (bootstrapModel.offers != null &&
          bootstrapModel.offers!.data.isNotEmpty &&
          Get.isRegistered<OffersController>()) {
        final offersController = Get.find<OffersController>();
        offersController.setOfferDataFromBootstrap(bootstrapModel.offers!);
        if (kDebugMode) {
          debugPrint(
              '✅ BootstrapDataLoader: Offers loaded (${bootstrapModel.offers!.data.length})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BootstrapDataLoader: Error loading secondary sections: $e');
      }
    }
  }

  /// Check which sections are missing from bootstrap (for fallback loading)
  static List<String> getMissingSections(BootstrapModel? bootstrapModel) {
    final missingSections = <String>[];

    if (bootstrapModel == null) {
      return [
        'business_settings',
        'banners',
        'categories',
        'stores',
        'brands',
        'offers'
      ];
    }

    if (bootstrapModel.businessSettings == null) {
      missingSections.add('business_settings');
    }
    if (bootstrapModel.banners == null) {
      missingSections.add('banners');
    }
    if (bootstrapModel.categories == null ||
        bootstrapModel.categories!.isEmpty) {
      missingSections.add('categories');
    }
    if (bootstrapModel.storesPopular == null ||
        bootstrapModel.storesPopular!.stores == null ||
        bootstrapModel.storesPopular!.stores!.isEmpty) {
      missingSections.add('stores_popular');
    }
    if (bootstrapModel.stores == null ||
        bootstrapModel.stores!.stores == null ||
        bootstrapModel.stores!.stores!.isEmpty) {
      missingSections.add('stores');
    }
    if (bootstrapModel.brands == null || bootstrapModel.brands!.isEmpty) {
      missingSections.add('brands');
    }
    if (bootstrapModel.offers == null || bootstrapModel.offers!.data.isEmpty) {
      missingSections.add('offers');
    }

    return missingSections;
  }
}
