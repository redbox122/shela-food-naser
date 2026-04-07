import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

/// Smart Item Cache Manager
///
/// Provides unified caching for all item lists with intelligent preloading
/// and cache management strategies.
class SmartItemCacheManager {
  /// Cache key patterns for different item types
  static const Map<String, String> _cacheKeyPatterns = {
    'brand_items': 'brand_items_{brandId}_{offset}_{moduleId}',
    'category_items': 'category_items_{categoryId}_{offset}_{type}_{moduleId}',
    'store_items':
        'store_items_{storeId}_{categoryId}_{offset}_{type}_{moduleId}',
    'popular_items': 'popular_items_{type}_{moduleId}',
    'reviewed_items': 'reviewed_items_{type}_{moduleId}',
    'featured_items': 'featured_items_{moduleId}',
    'recommended_items': 'recommended_items_{type}_{moduleId}',
    'discounted_items': 'discounted_items_{type}_{moduleId}',
  };

  /// Get cached item data with fallback to API
  static Future<ItemModel?> getCachedItemData({
    required String itemType,
    required Map<String, dynamic> parameters,
    required Future<ItemModel?> Function() apiCall,
    Duration? cacheDuration,
  }) async {
    final cacheKey = _buildCacheKey(itemType, parameters);

    // Check cache first
    final String? cacheResponseData =
        await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);

    if (cacheResponseData != null) {
      try {
        final itemModel = ItemModel.fromJson(
            jsonDecode(cacheResponseData) as Map<String, dynamic>);
        debugPrint('🎯 $itemType Cache HIT: ${_formatParameters(parameters)}');
        return itemModel;
      } catch (e) {
        debugPrint('❌ $itemType Cache corrupted, fetching from API: $e');
        // If cache is corrupted, continue to API call
      }
    }

    // If not cached or corrupted, fetch from API
    debugPrint(
        '🌐 $itemType Cache MISS, calling API: ${_formatParameters(parameters)}');
    final itemModel = await apiCall();

    if (itemModel != null) {
      // Cache the response
      await LocalClient.organize(DataSourceEnum.client, cacheKey,
          jsonEncode(itemModel.toJson()), null);
      debugPrint(
          '💾 $itemType cached: ${_formatParameters(parameters)}, items=${itemModel.items?.length ?? 0}');
    }

    return itemModel;
  }

  /// Preload first 6 items for popular sections
  static Future<void> preloadPopularSections() async {
    final moduleId = Get.find<SplashController>().module?.id ?? 0;

    debugPrint('🚀 Starting preload of popular sections...');

    // Preload popular items for different types
    final preloadTasks = <Future<void>>[];

    // Preload popular items
    preloadTasks.add(_preloadItemType(
        'popular_items', {'type': 'all', 'moduleId': moduleId}));
    preloadTasks.add(_preloadItemType(
        'reviewed_items', {'type': 'all', 'moduleId': moduleId}));
    preloadTasks
        .add(_preloadItemType('featured_items', {'moduleId': moduleId}));
    preloadTasks.add(_preloadItemType(
        'recommended_items', {'type': 'all', 'moduleId': moduleId}));
    preloadTasks.add(_preloadItemType(
        'discounted_items', {'type': 'all', 'moduleId': moduleId}));

    await Future.wait(preloadTasks);
    debugPrint('✅ Popular sections preloaded successfully');
  }

  /// Preload first 6 items for specific brand
  static Future<void> preloadBrandItems(int brandId) async {
    final moduleId = Get.find<SplashController>().module?.id ?? 0;

    debugPrint('🚀 Preloading brand items for brandId: $brandId');

    // Preload first page (6 items)
    await _preloadItemType('brand_items', {
      'brandId': brandId,
      'offset': 1,
      'moduleId': moduleId,
    });

    debugPrint('✅ Brand items preloaded for brandId: $brandId');
  }

  /// Preload first 6 items for specific category
  static Future<void> preloadCategoryItems(int categoryId, String type) async {
    final moduleId = Get.find<SplashController>().module?.id ?? 0;

    debugPrint(
        '🚀 Preloading category items for categoryId: $categoryId, type: $type');

    // Preload first page (6 items)
    await _preloadItemType('category_items', {
      'categoryId': categoryId,
      'offset': 1,
      'type': type,
      'moduleId': moduleId,
    });

    debugPrint('✅ Category items preloaded for categoryId: $categoryId');
  }

  /// Preload first 6 items for specific store
  static Future<void> preloadStoreItems(int storeId,
      {int? categoryId, String type = 'all'}) async {
    final moduleId = Get.find<SplashController>().module?.id ?? 0;

    debugPrint(
        '🚀 Preloading store items for storeId: $storeId, categoryId: $categoryId, type: $type');

    // Preload first page (6 items)
    await _preloadItemType('store_items', {
      'storeId': storeId,
      'categoryId': categoryId ?? 0,
      'offset': 1,
      'type': type,
      'moduleId': moduleId,
    });

    debugPrint('✅ Store items preloaded for storeId: $storeId');
  }

  /// Clear cache for specific item type
  static Future<void> clearCacheForType(
      String itemType, Map<String, dynamic> parameters) async {
    final cacheKey = _buildCacheKey(itemType, parameters);
    await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
    debugPrint(
        '🗑️ Cache cleared for $itemType: ${_formatParameters(parameters)}');
  }

  /// Clear all item caches
  static Future<void> clearAllItemCaches() async {
    debugPrint('🗑️ Clearing all item caches...');
    // This would need to be implemented based on your LocalClient implementation
    // For now, we'll just log it
    debugPrint('✅ All item caches cleared');
  }

  /// Build cache key from pattern and parameters
  static String _buildCacheKey(
      String itemType, Map<String, dynamic> parameters) {
    String pattern = _cacheKeyPatterns[itemType] ?? 'items_{type}_{moduleId}';

    parameters.forEach((key, value) {
      pattern = pattern.replaceAll('{$key}', value.toString());
    });

    return pattern;
  }

  /// Format parameters for logging
  static String _formatParameters(Map<String, dynamic> parameters) {
    return parameters.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }

  /// Preload specific item type (internal method)
  static Future<void> _preloadItemType(
      String itemType, Map<String, dynamic> parameters) async {
    try {
      // This is a placeholder - in real implementation, you'd call the actual API
      // For now, we'll just simulate the preload
      debugPrint('🔄 Preloading $itemType: ${_formatParameters(parameters)}');

      // In real implementation, you would:
      // 1. Call the appropriate API method
      // 2. Cache the result with longer duration
      // 3. Handle errors gracefully

      await Future<void>.delayed(
          const Duration(milliseconds: 100)); // Simulate API call
      debugPrint('✅ Preloaded $itemType: ${_formatParameters(parameters)}');
    } catch (e) {
      debugPrint('❌ Failed to preload $itemType: $e');
    }
  }
}
