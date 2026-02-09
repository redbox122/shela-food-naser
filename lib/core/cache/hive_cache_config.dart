/// Hive Cache Configuration
/// Contains all constants, TTL values, and configuration for Hive caching
class HiveCacheConfig {
  // Cache TTL Configuration (per data type - backend recommended)
  static const Duration businessSettingsTTL = Duration(hours: 24); // Rarely changes
  static const Duration categoriesTTL = Duration(hours: 12); // Changes occasionally
  static const Duration storesTTL = Duration(hours: 6); // Changes more frequently
  static const Duration storeDetailsTTL = Duration(hours: 2); // Store details change moderately
  static const Duration bannersTTL = Duration(hours: 2); // Changes frequently
  static const Duration offersTTL = Duration(hours: 1); // Changes very frequently
  static const Duration brandsTTL = Duration(hours: 12); // Rarely changes
  static const Duration zoneTTL = Duration(hours: 24); // Zone data changes rarely
  static const Duration cartTTL = Duration(minutes: 5); // Cart data changes frequently
  
  // Offline TTL (extended)
  static const Duration offlineTTL = Duration(days: 7); // When user is offline
  
  // Get TTL based on data type and online status
  static Duration getTTL(String dataType, bool isOnline) {
    if (!isOnline) {
      return offlineTTL; // Extended TTL for offline mode
    }
    
    switch (dataType) {
      case 'business_settings':
        return businessSettingsTTL;
      case 'categories':
        return categoriesTTL;
      case 'stores':
        return storesTTL;
      case 'store_details':
        return storeDetailsTTL;
      case 'banners':
        return bannersTTL;
      case 'offers':
        return offersTTL;
      case 'brands':
        return brandsTTL;
      case 'zone':
        return zoneTTL;
      case 'cart':
        return cartTTL;
      default:
        return const Duration(hours: 24); // Default fallback
    }
  }
  
  // Hive Box Names (Module-Isolated)
  // Pattern: {dataType}_module_{moduleId}
  static String getBannerBoxName(int moduleId) => 'banners_module_$moduleId';
  static String getCategoryBoxName(int moduleId) => 'categories_module_$moduleId';
  static String getStoreBoxName(int moduleId, {String? locationHash}) {
    // For location-dependent modules (like Food), include location in cache key
    // This ensures cache is invalidated when location changes
    if (locationHash != null && locationHash.isNotEmpty) {
      return 'stores_module_${moduleId}_$locationHash';
    }
    return 'stores_module_$moduleId';
  }
  static String getBrandBoxName(int moduleId) => 'brands_module_$moduleId';
  static String getOffersBoxName(int moduleId) => 'offers_module_$moduleId';
  static String getBusinessSettingsBoxName(int moduleId) => 'business_settings_module_$moduleId';
  
  // Store Details Box (store-specific, not module-specific)
  static String getStoreDetailsBoxName() => 'store_details';
  
  // Zone cache box (global, not module-specific)
  static const String zoneCacheBoxName = 'zone_cache';
  
  // Cart cache box (global, not module-specific)
  static const String cartCacheBoxName = 'cart_cache';
  
  // Multi-module promotional cache box (for Module 3 banners and offers)
  static const String multiModulePromotionalCacheBoxName = 'multi_module_promotional_cache';
  
  // Metadata box (shared across modules)
  static const String metadataBoxName = 'home_cache_metadata';
  
  // Unified home cache box (stores entire HomeUnifiedModel)
  static String getHomeUnifiedBoxName(int moduleId) => 'home_unified_module_$moduleId';
  
  // App config box (stores AppInitModel and ETags)
  static const String appConfigBoxName = 'app_config';
  
  // Session config box (stores zone ID and coordinates for instant loading)
  static const String sessionConfigBoxName = 'session_config';
  
  // Compression Configuration
  // Note: Hive 2.x doesn't support compression via openBox parameter
  // Compression can be added later using custom codecs if needed
  // For now, compression is disabled as it requires custom codec implementation
  
  // Feature Flags
  static const String enableHiveFlag = 'enable_hive_cache';
  static const String enableCompressionFlag = 'enable_hive_compression';
  static const String enableOfflineExtensionFlag = 'enable_offline_ttl_extension';
  
  // Default feature flag values
  static bool get isHiveEnabled => true; // Enable by default
  static bool get isCompressionEnabled => false; // Disabled - requires custom codec
  static bool get isOfflineExtensionEnabled => true; // Enable by default
  
  // Migration Flags
  static const String hiveMigrationComplete = 'hive_migration_complete';
  static const String hiveMigrationVersion = 'hive_migration_version';
  static const String currentMigrationVersion = '1.0';
  
  // Error Handling
  static const String boxNotFound = 'HIVE_BOX_NOT_FOUND';
  static const String migrationFailed = 'HIVE_MIGRATION_FAILED';
  static const String invalidData = 'HIVE_INVALID_DATA';
  static const String compressionError = 'HIVE_COMPRESSION_ERROR';
  
  // Check if error should trigger SharedPreferences fallback
  static bool shouldFallbackToSharedPreferences(String error) {
    return [
      boxNotFound,
      migrationFailed,
      invalidData,
    ].contains(error);
  }
  
  // Data Types - Cache vs No Cache
  static const List<String> cacheableDataTypes = [
    'bootstrap',
    'categories',
    'stores',
    'store_details',
    'banners',
    'offers',
    'brands',
    'business_settings',
    'zone', // Zone data is now cacheable
    'cart', // Cart data is now cacheable for instant loading
  ];
  
  static const List<String> nonCacheableDataTypes = [
    'auth_token',
    'user_profile',
    'order_status',
    'payment_info',
  ];
  
  // Validate if data type is cacheable
  static bool isCacheable(String dataType) {
    return cacheableDataTypes.contains(dataType);
  }
  
  static bool isNonCacheable(String dataType) {
    return nonCacheableDataTypes.contains(dataType);
  }
}

