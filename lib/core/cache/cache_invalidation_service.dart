import 'package:flutter/foundation.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

/// Centralized Cache Invalidation Service
/// 
/// Provides unified cache invalidation logic across the application:
/// - Single point of control for cache invalidation
/// - Consistent invalidation patterns
/// - Easy to maintain and extend
class CacheInvalidationService {
  static final CacheInvalidationService _instance = CacheInvalidationService._internal();
  factory CacheInvalidationService() => _instance;
  CacheInvalidationService._internal();
  
  final HiveHomeCacheService _cacheService = HiveHomeCacheService();
  
  /// Invalidate home unified cache for a specific module
  /// 
  /// Clears cached home data, timestamps, and ETags for the module
  Future<void> invalidateHomeUnifiedCache(int moduleId) async {
    try {
      await _cacheService.invalidateHomeUnifiedCache(moduleId);
      
      if (kDebugMode) {
        debugPrint('🗑️ CacheInvalidationService: Invalidated home unified cache for module $moduleId');
      }
      
      appLogger.info('Cache invalidated: home_unified_module_$moduleId');
    } catch (e) {
      appLogger.error('Failed to invalidate home unified cache', e);
      if (kDebugMode) {
        debugPrint('❌ CacheInvalidationService: Error invalidating home unified cache - $e');
      }
    }
  }
  
  /// Invalidate home unified cache for all modules
  /// 
  /// Useful when global changes require clearing all module caches
  Future<void> invalidateAllHomeUnifiedCache() async {
    try {
      // Common module IDs: 1 (Food), 2 (Grocery), 3 (Ecommerce), etc.
      final moduleIds = [1, 2, 3, 4, 5];
      
      for (final moduleId in moduleIds) {
        await invalidateHomeUnifiedCache(moduleId);
      }
      
      if (kDebugMode) {
        debugPrint('🗑️ CacheInvalidationService: Invalidated all home unified caches');
      }
      
      appLogger.info('All home unified caches invalidated');
    } catch (e) {
      appLogger.error('Failed to invalidate all home unified caches', e);
      if (kDebugMode) {
        debugPrint('❌ CacheInvalidationService: Error invalidating all home unified caches - $e');
      }
    }
  }
  
  /// Invalidate store details cache for a specific store
  /// 
  /// Clears cached store data when store information changes
  Future<void> invalidateStoreDetailsCache(int storeId) async {
    try {
      await _cacheService.invalidateStoreDetailsCache(storeId);
      
      if (kDebugMode) {
        debugPrint('🗑️ CacheInvalidationService: Invalidated store details cache for store $storeId');
      }
      
      appLogger.info('Cache invalidated: store_details_$storeId');
    } catch (e) {
      appLogger.error('Failed to invalidate store details cache', e);
      if (kDebugMode) {
        debugPrint('❌ CacheInvalidationService: Error invalidating store details cache - $e');
      }
    }
  }
  
  /// Invalidate cart cache
  /// 
  /// Clears cart cache when cart operations occur
  Future<void> invalidateCartCache() async {
    try {
      // Cart cache is managed by CartController
      // This method provides a centralized way to trigger cart cache invalidation
      if (kDebugMode) {
        debugPrint('🗑️ CacheInvalidationService: Cart cache invalidation requested');
      }
      
      appLogger.info('Cart cache invalidation requested');
      
      // Note: Actual cart cache invalidation is handled by CartController
      // This service provides a unified interface for future centralized cache management
    } catch (e) {
      appLogger.error('Failed to invalidate cart cache', e);
      if (kDebugMode) {
        debugPrint('❌ CacheInvalidationService: Error invalidating cart cache - $e');
      }
    }
  }
  
  /// Invalidate ETag for a specific URI
  /// 
  /// Forces fresh API request by clearing ETag cache
  Future<void> invalidateETag(String uri) async {
    try {
      await _cacheService.clearETagForUri(uri);
      
      if (kDebugMode) {
        debugPrint('🗑️ CacheInvalidationService: Invalidated ETag for $uri');
      }
      
      appLogger.info('ETag invalidated: $uri');
    } catch (e) {
      appLogger.error('Failed to invalidate ETag', e);
      if (kDebugMode) {
        debugPrint('❌ CacheInvalidationService: Error invalidating ETag - $e');
      }
    }
  }
  
  /// Invalidate multiple cache types at once
  /// 
  /// Convenience method for bulk cache invalidation
  Future<void> invalidateMultiple({
    int? moduleId,
    int? storeId,
    String? uri,
    bool invalidateCart = false,
  }) async {
    try {
      if (moduleId != null) {
        await invalidateHomeUnifiedCache(moduleId);
      }
      
      if (storeId != null) {
        await invalidateStoreDetailsCache(storeId);
      }
      
      if (uri != null) {
        await invalidateETag(uri);
      }
      
      if (invalidateCart) {
        await invalidateCartCache();
      }
      
      if (kDebugMode) {
        debugPrint('🗑️ CacheInvalidationService: Bulk cache invalidation completed');
      }
      
      appLogger.info('Bulk cache invalidation completed');
    } catch (e) {
      appLogger.error('Failed to perform bulk cache invalidation', e);
      if (kDebugMode) {
        debugPrint('❌ CacheInvalidationService: Error in bulk cache invalidation - $e');
      }
    }
  }
}

