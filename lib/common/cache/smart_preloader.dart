import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

/// Smart Preloader
///
/// Intelligently preloads the first 6 items for popular sections
/// to provide instant loading when users navigate to them.
class SmartPreloader {
  static const int _preloadItemCount = 6;
  static const int _maxPreloadBrands = 3;
  static const int _maxPreloadCategories = 5;
  static const int _maxPreloadStores = 3;

  /// Preload popular sections on app startup
  static Future<void> preloadPopularSections() async {
    debugPrint('🚀 SmartPreloader: Starting popular sections preload...');

    try {
      // Preload popular items
      await _preloadPopularItems();

      // Preload top brands
      await _preloadTopBrands();

      // Preload top categories
      await _preloadTopCategories();

      // Preload top stores
      await _preloadTopStores();

      debugPrint('✅ SmartPreloader: Popular sections preloaded successfully');
    } catch (e) {
      debugPrint('❌ SmartPreloader: Error preloading sections: $e');
    }
  }

  /// Preload items for a specific brand when user taps on it
  static Future<void> preloadBrandItems(int brandId) async {
    debugPrint(
        '🚀 SmartPreloader: Preloading brand items for brandId: $brandId');

    try {
      final brandsController = Get.find<BrandsController>();

      // Preload first page of brand items
      await brandsController.getBrandItemList(brandId, 1, false);

      debugPrint(
          '✅ SmartPreloader: Brand items preloaded for brandId: $brandId');
    } catch (e) {
      debugPrint('❌ SmartPreloader: Error preloading brand items: $e');
    }
  }

  /// Preload items for a specific category when user taps on it
  static Future<void> preloadCategoryItems(int categoryId, String type) async {
    debugPrint(
        '🚀 SmartPreloader: Preloading category items for categoryId: $categoryId, type: $type');

    try {
      final categoryController = Get.find<CategoryController>();

      // Preload first page of category items
      categoryController.getCategoryItemList(
          categoryId.toString(), 1, type, false);

      debugPrint(
          '✅ SmartPreloader: Category items preloaded for categoryId: $categoryId');
    } catch (e) {
      debugPrint('❌ SmartPreloader: Error preloading category items: $e');
    }
  }

  /// Preload items for a specific store when user taps on it
  static Future<void> preloadStoreItems(int storeId,
      {int? categoryId, String type = 'all'}) async {
    debugPrint(
        '🚀 SmartPreloader: Preloading store items for storeId: $storeId, categoryId: $categoryId, type: $type');

    try {
      final storeController = Get.find<StoreController>();

      // Preload first page of store items
      storeController.getStoreItemList(storeId, 1, type, false);

      debugPrint(
          '✅ SmartPreloader: Store items preloaded for storeId: $storeId');
    } catch (e) {
      debugPrint('❌ SmartPreloader: Error preloading store items: $e');
    }
  }

  /// Preload popular items
  static Future<void> _preloadPopularItems() async {
    try {
      final itemController = Get.find<ItemController>();
      final splashController = Get.find<SplashController>();

      // Only preload for ecommerce module
      if (splashController.module?.moduleType.toString() == 'ecommerce') {
        debugPrint('🔄 Preloading popular items...');

        // Preload popular items
        await itemController.getPopularItemList(false, 'all', false);

        // Preload reviewed items
        await itemController.getReviewedItemList(false, 'all', false);

        // Preload featured category items
        await itemController.getFeaturedCategoriesItemList(false, false);

        // Preload recommended items
        await itemController.getRecommendedItemList(false, 'all', false);

        // Preload discounted items
        await itemController.getDiscountedItemList(false, false, 'all');

        debugPrint('✅ Popular items preloaded');
      }
    } catch (e) {
      debugPrint('❌ Error preloading popular items: $e');
    }
  }

  /// Preload top brands
  static Future<void> _preloadTopBrands() async {
    try {
      final brandsController = Get.find<BrandsController>();

      if (brandsController.brandList != null &&
          brandsController.brandList!.isNotEmpty) {
        debugPrint('🔄 Preloading top brands...');

        // Preload first 3 brands
        final topBrands = brandsController.brandList!.take(_maxPreloadBrands);

        for (final brand in topBrands) {
          try {
            await brandsController.getBrandItemList(brand.id!, 1, false);
            debugPrint('✅ Preloaded brand: ${brand.name}');
          } catch (e) {
            debugPrint('❌ Error preloading brand ${brand.name}: $e');
          }
        }

        debugPrint('✅ Top brands preloaded');
      }
    } catch (e) {
      debugPrint('❌ Error preloading top brands: $e');
    }
  }

  /// Preload top categories
  /// ⚠️ REMOVED: Automatic category item preloading to prevent unnecessary API calls
  /// Category items are now only preloaded when user taps on a category (via preloadCategoryItems)
  static Future<void> _preloadTopCategories() async {
    try {
      final categoryController = Get.find<CategoryController>();

      if (categoryController.categoryList != null &&
          categoryController.categoryList!.isNotEmpty) {
        debugPrint('🔄 Preloading top categories...');

        // ✅ FIXED: Removed automatic category item preloading to prevent unnecessary API calls
        // Category items are only preloaded when user actually taps on a category
        // This prevents 500 errors and reduces API calls significantly

        // Only log that categories are available for preloading
        final topCategories =
            categoryController.categoryList!.take(_maxPreloadCategories);
        debugPrint(
            '✅ Top categories available for preloading: ${topCategories.map((c) => c.name).join(", ")}');
        debugPrint(
            'ℹ️  Category items will be preloaded when user taps on categories');

        debugPrint(
            '✅ Top categories preloaded (skipping item preload to avoid unnecessary API calls)');
      }
    } catch (e) {
      debugPrint('❌ Error preloading top categories: $e');
    }
  }

  /// Preload top stores
  static Future<void> _preloadTopStores() async {
    try {
      final storeController = Get.find<StoreController>();

      if (storeController.popularStoreList != null &&
          storeController.popularStoreList!.isNotEmpty) {
        debugPrint('🔄 Preloading top stores...');

        // Preload first 3 stores
        final topStores =
            storeController.popularStoreList!.take(_maxPreloadStores);

        for (final store in topStores) {
          try {
            storeController.getStoreItemList(store.id, 1, 'all', false);
            debugPrint('✅ Preloaded store: ${store.name}');
          } catch (e) {
            debugPrint('❌ Error preloading store ${store.name}: $e');
          }
        }

        debugPrint('✅ Top stores preloaded');
      }
    } catch (e) {
      debugPrint('❌ Error preloading top stores: $e');
    }
  }

  /// Check if data is already preloaded
  static bool isDataPreloaded(
      String dataType, Map<String, dynamic> parameters) {
    // This would check if the data is already in cache
    // For now, we'll return false to always preload
    return false;
  }

  /// Get preload statistics
  static Map<String, dynamic> getPreloadStats() {
    return {
      'preloadItemCount': _preloadItemCount,
      'maxPreloadBrands': _maxPreloadBrands,
      'maxPreloadCategories': _maxPreloadCategories,
      'maxPreloadStores': _maxPreloadStores,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
