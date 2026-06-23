
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sixam_mart/core/cache/hive_cache_config.dart';
import 'package:sixam_mart/core/cache/hive_isolate_helper.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';
import 'package:sixam_mart/features/home/domain/models/home_unified_model.dart';
import 'package:sixam_mart/core/cache/hive_adapters/banner_model_adapter.dart';
import 'package:sixam_mart/core/isolate/json_isolate_helper.dart';
import 'package:sixam_mart/core/cache/hive_adapters/category_model_adapter.dart';
import 'package:sixam_mart/core/cache/hive_adapters/store_model_adapter.dart';
import 'package:sixam_mart/core/cache/hive_adapters/brand_model_adapter.dart';
import 'package:sixam_mart/core/cache/hive_adapters/offers_model_adapter.dart';
import 'package:sixam_mart/core/cache/hive_adapters/business_settings_adapter.dart';
import 'package:sixam_mart/core/cache/hive_adapters/app_init_model_adapter.dart';
import 'package:sixam_mart/common/models/app_init_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';

/// Hive Home Cache Service
/// Provides module-aware caching with per-data-type TTLs, compression, and offline support
/// ⚡ PERFORMANCE: Uses LazyBox for reduced memory footprint and faster startup
class HiveHomeCacheService {
  static final HiveHomeCacheService _instance =
      HiveHomeCacheService._internal();
  factory HiveHomeCacheService() => _instance;
  HiveHomeCacheService._internal();

  bool _isInitialized = false;
  // ⚡ PERFORMANCE: Changed from Box to LazyBox for reduced memory usage
  // LazyBox only loads data when accessed, not on box open
  final Map<String, LazyBox> _openLazyBoxes = {};
  final Connectivity _connectivity = Connectivity();

  /// Initialize Hive and register adapters
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Initialize Hive Flutter (uses path_provider internally)
      // 🔧 CRITICAL FIX: Verify Android storage path is correct
      await Hive.initFlutter();

      // 🔧 DEBUG: Log Hive storage path for Android verification
      if (kDebugMode) {
        try {
          // Hive.initFlutter() uses path_provider which returns:
          // Android: /data/data/<package>/app_flutter/hive/
          // iOS: <AppDocumentsDirectory>/hive/
          // This path is managed by path_provider and should persist across app restarts
          debugPrint('✅ HiveHomeCacheService: Hive initialized');
          debugPrint(
              '   - Storage path managed by path_provider (persists across restarts)');
          debugPrint('   - Android: /data/data/<package>/app_flutter/hive/');
          debugPrint('   - iOS: <AppDocumentsDirectory>/hive/');
        } catch (e) {
          debugPrint('⚠️ HiveHomeCacheService: Could not log storage path: $e');
        }
      }

      // Register all adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(BannerModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CategoryModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CategoryModelListAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(StoreModelAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(BrandModelAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(BrandModelListAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(OffersModelAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(BusinessSettingsModelAdapter());
      }
      // ⚡ TASK 3: Register AppInitModel adapter for app_config box
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(AppInitModelAdapter());
      }

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ HiveHomeCacheService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Initialization failed - $e');
      }
      _isInitialized = false;
      rethrow;
    }
  }

  /// Check if online
  Future<bool> _isOnline() async {
    try {
      final List<ConnectivityResult> connectivityResults =
          await _connectivity.checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      // Assume online if check fails
      return true;
    }
  }

  /// Pre-open promotional cache box (called during SplashController init)
  /// This ensures the box is ready when MultiModuleHomeScreen loads cache
  Future<void> preOpenPromotionalCacheBox() async {
    try {
      await _getLazyBox(HiveCacheConfig.multiModulePromotionalCacheBoxName);
      if (kDebugMode) {
        debugPrint('✅ HiveHomeCacheService: Promotional cache box pre-opened');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ HiveHomeCacheService: Error pre-opening promotional cache box: $e');
      }
    }
  }

  /// ⚡ SWR: Pre-open all home unified cache boxes for a module
  /// This ensures boxes are ready BEFORE home screens load for instant cache access
  /// Called during SplashController parallel initialization
  Future<void> preOpenHomeUnifiedCacheBoxes(int moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      // Pre-open all module-specific cache boxes in parallel
      await Future.wait([
        _getLazyBox(HiveCacheConfig.getBannerBoxName(moduleId)),
        _getLazyBox(HiveCacheConfig.getCategoryBoxName(moduleId)),
        _getLazyBox(HiveCacheConfig.getStoreBoxName(moduleId)),
        _getLazyBox(HiveCacheConfig.getBrandBoxName(moduleId)),
        _getLazyBox(HiveCacheConfig.getOffersBoxName(moduleId)),
        _getLazyBox(HiveCacheConfig.metadataBoxName),
      ]);

      if (kDebugMode) {
        debugPrint(
            '✅ HiveHomeCacheService: All home unified cache boxes pre-opened for module $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ HiveHomeCacheService: Error pre-opening home unified cache boxes: $e');
      }
      // Don't throw - continue even if pre-opening fails
    }
  }

  /// Get or open a Hive LazyBox
  /// ⚡ PERFORMANCE: LazyBox loads data on-demand, not on open
  /// This reduces memory usage and speeds up initialization
  Future<LazyBox> _getLazyBox(String boxName) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_openLazyBoxes.containsKey(boxName)) {
      final cachedBox = _openLazyBoxes[boxName]!;
      if (cachedBox.isOpen) {
        return cachedBox;
      }
      // Drop stale closed handle so a fresh box can be acquired.
      _openLazyBoxes.remove(boxName);
    }

    // Reuse an already-open Hive box if available (e.g., reopened elsewhere).
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.lazyBox(boxName);
      _openLazyBoxes[boxName] = box;
      return box;
    }

    try {
      // ⚡ PERFORMANCE: Use openLazyBox instead of openBox
      // LazyBox doesn't load all data into memory on open
      final box = await Hive.openLazyBox(boxName);
      _openLazyBoxes[boxName] = box;
      return box;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Failed to open lazy box $boxName - $e');
      }
      rethrow;
    }
  }

  /// Save timestamp for cache entry
  /// ⚡ PERFORMANCE: Uses LazyBox for async access
  Future<void> _saveTimestamp(
      String boxName, String key, DateTime timestamp) async {
    try {
      final box = await _getLazyBox(HiveCacheConfig.metadataBoxName);
      await box.put(
          '${boxName}_${key}_timestamp', timestamp.millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveHomeCacheService: Failed to save timestamp - $e');
      }
    }
  }

  /// Get timestamp for cache entry
  /// ⚡ PERFORMANCE: Uses LazyBox.get() which is async
  Future<DateTime?> _getTimestamp(String boxName, String key) async {
    try {
      final box = await _getLazyBox(HiveCacheConfig.metadataBoxName);
      // ⚡ LazyBox.get() is async - must await
      final timestamp = await box.get('${boxName}_${key}_timestamp');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveHomeCacheService: Failed to get timestamp - $e');
      }
    }
    return null;
  }

  /// Delete timestamp for cache entry
  /// 🔧 FIX: Used when invalidating cache
  Future<void> _deleteTimestamp(String boxName, String key) async {
    try {
      final box = await _getLazyBox(HiveCacheConfig.metadataBoxName);
      await box.delete('${boxName}_${key}_timestamp');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveHomeCacheService: Failed to delete timestamp - $e');
      }
    }
  }

  /// Check if cache is valid based on TTL
  Future<bool> _isCacheValid(
      String boxName, String key, String dataType) async {
    try {
      final timestamp = await _getTimestamp(boxName, key);
      if (timestamp == null) {
        return false;
      }

      final isOnline = await _isOnline();
      final ttl = HiveCacheConfig.getTTL(dataType, isOnline);
      final age = DateTime.now().difference(timestamp);

      return age < ttl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error checking cache validity - $e');
      }
      return false;
    }
  }

  // Save operations

  /// Save banners for a module
  /// ⚡ PERFORMANCE: Uses LazyBox for reduced memory footprint
  Future<void> saveBanners(int moduleId, BannerModel data) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getBannerBoxName(moduleId);
      final box = await _getLazyBox(boxName);
      await box.put('banners', data);
      await _saveTimestamp(boxName, 'banners', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint('💾 HiveHomeCacheService: Saved banners for module $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving banners - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Save categories for a module
  /// ⚡ PERFORMANCE: JSON encoding in isolate + LazyBox for reduced memory
  Future<void> saveCategories(int moduleId, List<CategoryModel> data) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getCategoryBoxName(moduleId);
      // ⚡ Perform JSON encoding in isolate (non-blocking)
      final jsonString = await HiveIsolateHelper.serializeCategories(data);
      LazyBox box = await _getLazyBox(boxName);
      try {
        await box.put('categories', jsonString);
        await _saveTimestamp(boxName, 'categories', DateTime.now());
        // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
        await box.flush();
      } on HiveError catch (e) {
        if (e.toString().contains('already been closed')) {
          _openLazyBoxes.remove(boxName);
          box = await _getLazyBox(boxName);
          await box.put('categories', jsonString);
          await _saveTimestamp(boxName, 'categories', DateTime.now());
        } else {
          rethrow;
        }
      }
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved ${data.length} categories for module $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving categories - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Generate location hash from coordinates (rounded to ~10m precision)
  /// This ensures cache is invalidated when location changes significantly
  static String? _generateLocationHash(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    final roundedLat = (lat * 1000).round() / 1000;
    final roundedLng = (lng * 1000).round() / 1000;
    return 'loc_${roundedLat.toStringAsFixed(3)}_${roundedLng.toStringAsFixed(3)}';
  }

  /// Get current location hash from user address
  static String? _getCurrentLocationHash() {
    try {
      final addressModel = AddressHelper.getUserAddressFromSharedPref();
      if (addressModel?.latitude == null || addressModel?.longitude == null) {
        return null;
      }

      final lat = double.tryParse(addressModel!.latitude!);
      final lng = double.tryParse(addressModel.longitude!);
      return _generateLocationHash(lat, lng);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveHomeCacheService: Error getting location hash - $e');
      }
      return null;
    }
  }

  /// Save stores for a module
  /// ⚡ PERFORMANCE: Uses LazyBox for reduced memory footprint
  /// 📍 LOCATION-AWARE: For location-dependent modules, includes location in cache key
  Future<void> saveStores(int moduleId, StoreModel data,
      {String? locationHash}) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      // For Food module (or any location-dependent module), include location in cache key
      // If locationHash not provided, try to get it from current address
      String? finalLocationHash = locationHash;
      finalLocationHash ??= _getCurrentLocationHash();

      final boxName = HiveCacheConfig.getStoreBoxName(moduleId,
          locationHash: finalLocationHash);
      final box = await _getLazyBox(boxName);
      await box.put('stores', jsonEncode(data.toJson()));
      await _saveTimestamp(boxName, 'stores', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved stores for module $moduleId${finalLocationHash != null ? ' (location: $finalLocationHash)' : ''}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving stores - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Save brands for a module
  /// ⚡ PERFORMANCE: JSON encoding in isolate + LazyBox for reduced memory
  Future<void> saveBrands(int moduleId, List<BrandModel> data) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getBrandBoxName(moduleId);
      final box = await _getLazyBox(boxName);
      // ⚡ Perform JSON encoding in isolate (non-blocking)
      final jsonString = await HiveIsolateHelper.serializeBrands(data);
      await box.put('brands', jsonString);
      await _saveTimestamp(boxName, 'brands', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved ${data.length} brands for module $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving brands - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Save offers for a module
  /// ⚡ PERFORMANCE: Uses LazyBox for reduced memory footprint
  Future<void> saveOffers(int moduleId, OffersModel data) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getOffersBoxName(moduleId);
      final box = await _getLazyBox(boxName);
      await box.put('offers', jsonEncode(data.toJson()));
      await _saveTimestamp(boxName, 'offers', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint('💾 HiveHomeCacheService: Saved offers for module $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving offers - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Save business settings for a module
  /// ⚡ PERFORMANCE: Uses LazyBox for reduced memory footprint
  Future<void> saveBusinessSettings(
      int moduleId, BusinessSettingsModel data) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getBusinessSettingsBoxName(moduleId);
      final box = await _getLazyBox(boxName);
      await box.put('business_settings', data);
      await _saveTimestamp(boxName, 'business_settings', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved business settings for module $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving business settings - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Save promotional content (banners and offers) for multi-module home screen
  /// This caches Module 3 promotional content separately for instant loading
  Future<void> savePromotionalContent({
    required BannerModel? banners,
    required OffersModel? offers,
  }) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final box =
          await _getLazyBox(HiveCacheConfig.multiModulePromotionalCacheBoxName);

      if (banners != null) {
        await box.put('banners', banners);
        await _saveTimestamp(
          HiveCacheConfig.multiModulePromotionalCacheBoxName,
          'banners',
          DateTime.now(),
        );
        // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
        await box.flush();
        if (kDebugMode) {
          debugPrint('💾 HiveHomeCacheService: Saved promotional banners');
        }
      }

      if (offers != null) {
        await box.put('offers', offers);
        await _saveTimestamp(
          HiveCacheConfig.multiModulePromotionalCacheBoxName,
          'offers',
          DateTime.now(),
        );
        // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
        await box.flush();
        if (kDebugMode) {
          debugPrint('💾 HiveHomeCacheService: Saved promotional offers');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving promotional content - $e');
      }
    }
  }

  /// Load promotional content (banners and offers) for multi-module home screen
  /// Returns cached data if available and valid
  Future<Map<String, dynamic>?> loadPromotionalContent() async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final box =
          await _getLazyBox(HiveCacheConfig.multiModulePromotionalCacheBoxName);

      // Check if banners cache is valid
      final bannersValid = await _isCacheValid(
        HiveCacheConfig.multiModulePromotionalCacheBoxName,
        'banners',
        'banners',
      );

      // Check if offers cache is valid
      final offersValid = await _isCacheValid(
        HiveCacheConfig.multiModulePromotionalCacheBoxName,
        'offers',
        'offers',
      );

      final Map<String, dynamic> resultMap = <String, dynamic>{};

      if (bannersValid) {
        final bannersData = await box.get('banners');
        if (bannersData != null && bannersData is BannerModel) {
          resultMap['banners'] = bannersData;
          if (kDebugMode) {
            debugPrint(
                '📦 HiveHomeCacheService: Loaded promotional banners from cache');
          }
        }
      }

      if (offersValid) {
        final offersData = await box.get('offers');
        if (offersData != null && offersData is OffersModel) {
          resultMap['offers'] = offersData;
          if (kDebugMode) {
            debugPrint(
                '📦 HiveHomeCacheService: Loaded promotional offers from cache');
          }
        }
      }

      return resultMap.isNotEmpty ? resultMap : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading promotional content - $e');
      }
      return null;
    }
  }

  // Load operations

  /// Load banners for a module
  /// ⚡ PERFORMANCE: Uses LazyBox.get() which is async
  Future<BannerModel?> loadBanners(int moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final boxName = HiveCacheConfig.getBannerBoxName(moduleId);
      if (!await _isCacheValid(boxName, 'banners', 'banners')) {
        return null;
      }

      final box = await _getLazyBox(boxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('banners');
      if (data != null && data is BannerModel) {
        if (kDebugMode) {
          debugPrint('📦 HiveHomeCacheService: Loaded banners for module $moduleId');
        }
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading banners - $e');
      }
      return null;
    }
  }

  /// Load categories for a module
  /// ⚡ PERFORMANCE: LazyBox + JSON decoding in isolate
  Future<List<CategoryModel>?> loadCategories(int moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final boxName = HiveCacheConfig.getCategoryBoxName(moduleId);
      if (!await _isCacheValid(boxName, 'categories', 'categories')) {
        return null;
      }

      final box = await _getLazyBox(boxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('categories');
      if (data != null && data is String) {
        // ⚡ Perform JSON decoding in isolate (non-blocking)
        final categories = await HiveIsolateHelper.deserializeCategories(data);
        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded ${categories.length} categories for module $moduleId');
        }
        return categories;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading categories - $e');
      }
      return null;
    }
  }

  /// Load stores for a module
  /// ⚡ PERFORMANCE: Uses LazyBox.get() which is async
  /// 📍 LOCATION-AWARE: Validates location matches cached data, returns null if location changed
  Future<StoreModel?> loadStores(int moduleId,
      {String? locationHash, bool validateLocation = true}) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      // Get current location hash if not provided and validation is enabled
      String? currentLocationHash = locationHash;
      if (validateLocation && currentLocationHash == null) {
        currentLocationHash = _getCurrentLocationHash();
      }

      // Try loading with current location hash first
      final String boxName = HiveCacheConfig.getStoreBoxName(moduleId,
          locationHash: currentLocationHash);
      final bool cacheValid = await _isCacheValid(boxName, 'stores', 'stores');

      // If cache not found with location hash, try without (for backward compatibility)
      if (!cacheValid && currentLocationHash != null) {
        final String fallbackBoxName =
            HiveCacheConfig.getStoreBoxName(moduleId);
        final fallbackValid =
            await _isCacheValid(fallbackBoxName, 'stores', 'stores');
        if (fallbackValid) {
          if (kDebugMode) {
            debugPrint(
                '📍 HiveHomeCacheService: Found old cache without location hash - location changed, skipping cache');
          }
          // Location changed - don't use old cache
          return null;
        }
      }

      if (!cacheValid) {
        return null;
      }

      final box = await _getLazyBox(boxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('stores');
      if (data != null && data is StoreModel) {
        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded stores for module $moduleId${currentLocationHash != null ? ' (location: $currentLocationHash)' : ''}');
        }
        return data;
      }
      if (data is String) {
        try {
          return StoreModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }
      if (data is Map) {
        try {
          return StoreModel.fromJson(Map<String, dynamic>.from(data));
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading stores - $e');
      }
      return null;
    }
  }

  /// Load brands for a module
  /// ⚡ PERFORMANCE: LazyBox + JSON decoding in isolate
  Future<List<BrandModel>?> loadBrands(int moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final boxName = HiveCacheConfig.getBrandBoxName(moduleId);
      if (!await _isCacheValid(boxName, 'brands', 'brands')) {
        return null;
      }

      final box = await _getLazyBox(boxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('brands');
      if (data != null && data is String) {
        // ⚡ Perform JSON decoding in isolate (non-blocking)
        final brands = await HiveIsolateHelper.deserializeBrands(data);
        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded ${brands.length} brands for module $moduleId');
        }
        return brands;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading brands - $e');
      }
      return null;
    }
  }

  /// Load offers for a module
  /// ⚡ PERFORMANCE: Uses LazyBox.get() which is async
  Future<OffersModel?> loadOffers(int moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final boxName = HiveCacheConfig.getOffersBoxName(moduleId);
      if (!await _isCacheValid(boxName, 'offers', 'offers')) {
        return null;
      }

      final box = await _getLazyBox(boxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('offers');
      if (data != null && data is OffersModel) {
        if (kDebugMode) {
          debugPrint('📦 HiveHomeCacheService: Loaded offers for module $moduleId');
        }
        return data;
      }
      if (data is String) {
        try {
          return OffersModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }
      if (data is Map) {
        try {
          return OffersModel.fromJson(Map<String, dynamic>.from(data));
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading offers - $e');
      }
      return null;
    }
  }

  /// Load business settings for a module
  /// ⚡ PERFORMANCE: Uses LazyBox.get() which is async
  Future<BusinessSettingsModel?> loadBusinessSettings(int moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final boxName = HiveCacheConfig.getBusinessSettingsBoxName(moduleId);
      if (!await _isCacheValid(
          boxName, 'business_settings', 'business_settings')) {
        return null;
      }

      final box = await _getLazyBox(boxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('business_settings');
      if (data != null && data is BusinessSettingsModel) {
        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded business settings for module $moduleId');
        }
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading business settings - $e');
      }
      return null;
    }
  }

  // Cache management

  /// Check if cache is valid for a module
  Future<bool> isCacheValid(int moduleId, {String? dataType}) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return false;
    }

    try {
      final dataTypes = dataType != null
          ? [dataType]
          : [
              'banners',
              'categories',
              'stores',
              'brands',
              'offers',
              'business_settings'
            ];

      for (final type in dataTypes) {
        String boxName;
        String key;
        switch (type) {
          case 'banners':
            boxName = HiveCacheConfig.getBannerBoxName(moduleId);
            key = 'banners';
            break;
          case 'categories':
            boxName = HiveCacheConfig.getCategoryBoxName(moduleId);
            key = 'categories';
            break;
          case 'stores':
            boxName = HiveCacheConfig.getStoreBoxName(moduleId);
            key = 'stores';
            break;
          case 'brands':
            boxName = HiveCacheConfig.getBrandBoxName(moduleId);
            key = 'brands';
            break;
          case 'offers':
            boxName = HiveCacheConfig.getOffersBoxName(moduleId);
            key = 'offers';
            break;
          case 'business_settings':
            boxName = HiveCacheConfig.getBusinessSettingsBoxName(moduleId);
            key = 'business_settings';
            break;
          default:
            continue;
        }

        if (await _isCacheValid(boxName, key, type)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error checking cache validity - $e');
      }
      return false;
    }
  }

  /// Clear cache for a specific module
  /// ⚡ PERFORMANCE: Uses LazyBox for cache clearing
  Future<void> clearModuleCache(int moduleId) async {
    try {
      final boxNames = [
        HiveCacheConfig.getBannerBoxName(moduleId),
        HiveCacheConfig.getCategoryBoxName(moduleId),
        HiveCacheConfig.getStoreBoxName(moduleId),
        HiveCacheConfig.getBrandBoxName(moduleId),
        HiveCacheConfig.getOffersBoxName(moduleId),
        HiveCacheConfig.getBusinessSettingsBoxName(moduleId),
      ];

      for (final boxName in boxNames) {
        try {
          if (_openLazyBoxes.containsKey(boxName)) {
            await _openLazyBoxes[boxName]!.clear();
            await _openLazyBoxes[boxName]!.close();
            _openLazyBoxes.remove(boxName);
          } else {
            // ⚡ Use LazyBox for clearing
            final box = await Hive.openLazyBox(boxName);
            await box.clear();
            await box.close();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ HiveHomeCacheService: Failed to clear box $boxName - $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('🗑️ HiveHomeCacheService: Cleared cache for module $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error clearing module cache - $e');
      }
    }
  }

  /// Clear all cache
  /// ⚡ PERFORMANCE: Uses LazyBox for cache clearing
  Future<void> clearAllCache() async {
    try {
      // Close all open lazy boxes
      for (final box in _openLazyBoxes.values) {
        await box.close();
      }
      _openLazyBoxes.clear();

      // Clear metadata box
      try {
        final metadataBox = await _getLazyBox(HiveCacheConfig.metadataBoxName);
        await metadataBox.clear();
      } catch (e) {
        // Ignore if box doesn't exist
      }

      if (kDebugMode) {
        debugPrint('🗑️ HiveHomeCacheService: Cleared all cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error clearing all cache - $e');
      }
    }
  }

  // ============================================================
  // UNIFIED HOME CACHE (BFF API v2)
  // ============================================================

  /// Save unified home data for a module
  /// ⚡ PERFORMANCE: Stores entire HomeUnifiedModel as JSON string in isolate
  /// This is the single source of truth for home screen data
  Future<void> saveHomeUnifiedData(int moduleId, HomeUnifiedModel data) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getHomeUnifiedBoxName(moduleId);
      final box = await _getLazyBox(boxName);

      // ⚡ Perform JSON encoding in isolate (non-blocking)
      final jsonData = data.toJson();
      final jsonString = await JsonIsolateHelper.encodeJson(jsonData);

      await box.put('home_unified', jsonString);
      await _saveTimestamp(boxName, 'home_unified', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved unified home data for module $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving unified home data - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Load unified home data for a module
  /// ⚡ PERFORMANCE: Loads entire HomeUnifiedModel from JSON string in isolate
  /// Returns cached data if available and valid
  Future<HomeUnifiedModel?> loadHomeUnifiedData(int moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final boxName = HiveCacheConfig.getHomeUnifiedBoxName(moduleId);
      if (!await _isCacheValid(boxName, 'home_unified', 'bootstrap')) {
        return null;
      }

      final box = await _getLazyBox(boxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('home_unified');
      if (data != null && data is String) {
        // ⚡ Perform JSON decoding in isolate (non-blocking)
        final jsonMap = await JsonIsolateHelper.decodeJson(data);
        final model = HomeUnifiedModel.fromJson(jsonMap);

        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded unified home data for module $moduleId');
        }
        return model;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading unified home data - $e');
      }
      return null;
    }
  }

  /// Invalidate home unified cache for a module
  /// 🔧 FIX: Used when cached data has empty banners (stale cache)
  Future<void> invalidateHomeUnifiedCache(int moduleId, {bool clearEtag = false}) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getHomeUnifiedBoxName(moduleId);
      final box = await _getLazyBox(boxName);

      // Delete the cached data
      await box.delete('home_unified');

      // Delete the timestamp to mark cache as invalid
      await _deleteTimestamp(boxName, 'home_unified');
      if (clearEtag) {
        await clearETagForUri('/api/v2/home-unified');
      }

      if (kDebugMode) {
        debugPrint(
            'HiveHomeCacheService: Invalidated home unified cache for module $moduleId${clearEtag ? ' (including ETag)' : ''}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ HiveHomeCacheService: Error invalidating home unified cache - $e');
      }
    }
  }

  /// Clear ETag for a specific URI (forces fresh request, bypasses 304)
  Future<void> clearETagForUri(String uri) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.appConfigBoxName);
      final normalizedUri =
          uri.replaceAll('/', '_').replaceAll(':', '_');
      final exactEtagKey = 'etag_$normalizedUri';
      await box.delete(exactEtagKey);

      // Also remove scoped/full-url variants (e.g. with query/module scope).
      final keysToDelete = box.keys
          .whereType<String>()
          .where((key) =>
              key.startsWith('etag_') &&
              key != exactEtagKey &&
              key.contains(normalizedUri))
          .toList();
      for (final key in keysToDelete) {
        await box.delete(key);
      }
      if (kDebugMode) {
        debugPrint(
            '🗑️ HiveHomeCacheService: Cleared ETag for $uri (${1 + keysToDelete.length} key(s))');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error clearing ETag for $uri - $e');
      }
    }
  }

  // ============================================================
  // STORE DETAILS CACHE (SWR Pattern)
  // ============================================================

  /// Save store details for a specific store ID
  /// ⚡ PERFORMANCE: Uses LazyBox + JSON encoding in isolate
  Future<void> saveStoreDetails(int storeId, Store data) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getStoreDetailsBoxName();
      final box = await _getLazyBox(boxName);

      // ⚡ Perform JSON encoding in isolate (non-blocking)
      final jsonData = data.toJson();
      final jsonString = await JsonIsolateHelper.encodeJson(jsonData);

      await box.put('store_$storeId', jsonString);
      await _saveTimestamp(boxName, 'store_$storeId', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved store details for store $storeId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving store details - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Load store details for a specific store ID
  /// ⚡ PERFORMANCE: LazyBox + JSON decoding in isolate
  /// Returns cached data if available and valid
  Future<Store?> loadStoreDetails(int storeId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final boxName = HiveCacheConfig.getStoreDetailsBoxName();
      if (!await _isCacheValid(boxName, 'store_$storeId', 'store_details')) {
        return null;
      }

      final box = await _getLazyBox(boxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('store_$storeId');
      if (data != null && data is String) {
        // ⚡ Perform JSON decoding in isolate (non-blocking)
        final jsonMap = await JsonIsolateHelper.decodeJson(data);
        final store = Store.fromJson(jsonMap);

        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded store details for store $storeId');
        }
        return store;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading store details - $e');
      }
      return null;
    }
  }

  /// Invalidate store details cache for a specific store
  /// 🔧 FIX: Used when store information changes
  Future<void> invalidateStoreDetailsCache(int storeId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final boxName = HiveCacheConfig.getStoreDetailsBoxName();
      final box = await _getLazyBox(boxName);

      // Delete the cached store data
      await box.delete('store_$storeId');

      // Delete the timestamp to mark cache as invalid
      await _deleteTimestamp(boxName, 'store_$storeId');

      if (kDebugMode) {
        debugPrint(
            '🗑️ HiveHomeCacheService: Invalidated store details cache for store $storeId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ HiveHomeCacheService: Error invalidating store details cache - $e');
      }
    }
  }

  // ============================================================
  // APP CONFIG CACHE (App-Init & ETags)
  // ============================================================

  /// ⚡ TASK 3: Save AppInitModel to app_config Hive box
  Future<void> saveAppInitData(AppInitModel data) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.appConfigBoxName);
      await box.put('app_init', data); // ✅ Uses TypeAdapter
      await _saveTimestamp(
          HiveCacheConfig.appConfigBoxName, 'app_init', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint('💾 HiveHomeCacheService: Saved app-init data to app_config box');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving app-init data - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// ⚡ TASK 3: Load AppInitModel from app_config Hive box
  Future<AppInitModel?> loadAppInitData() async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.appConfigBoxName);
      final data = await box.get('app_init');
      if (data != null && data is AppInitModel) {
        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded app-init data from app_config box');
        }
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading app-init data - $e');
      }
      return null;
    }
  }

  /// ⚡ TASK 3: Save ETag to app_config Hive box
  Future<void> saveEtag(String uri, String etag) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    if (uri.contains('/api/v1/coupon/apply')) {
      if (kDebugMode) {
        debugPrint(
          'HiveHomeCacheService: skipped ETag save for coupon apply ($uri)',
        );
      }
      return;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.appConfigBoxName);
      final uriHash = uri.hashCode.toRadixString(36);
      final etagKey = 'etag_$uriHash';
      await box.put(etagKey, etag);
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint('💾 HiveHomeCacheService: Saved ETag for $uri');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving ETag - $e');
      }
    }
  }

  /// ⚡ TASK 3: Get ETag from app_config Hive box
  Future<String?> getEtag(String uri) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    if (uri.contains('/api/v1/coupon/apply')) {
      return null;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.appConfigBoxName);
      final uriHash = uri.hashCode.toRadixString(36);
      final etagKey = 'etag_$uriHash';
      final etag = await box.get(etagKey);
      return etag is String ? etag : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error getting ETag - $e');
      }
      return null;
    }
  }

  /// ⚡ TASK 3: Clear ETag from app_config Hive box
  Future<void> clearEtag(String uri) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.appConfigBoxName);
      final uriHash = uri.hashCode.toRadixString(36);
      final etagKey = 'etag_$uriHash';
      await box.delete(etagKey);

      if (kDebugMode) {
        debugPrint('🗑️ HiveHomeCacheService: Cleared ETag for $uri');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error clearing ETag - $e');
      }
    }
  }

  // ============================================================
  // ZONE CACHE (SWR Pattern - Instant Loading)
  // ============================================================

  /// Save zone data to Hive for instant loading
  /// ⚡ PERFORMANCE: Uses LazyBox + JSON encoding in isolate
  Future<void> saveZoneData(
      String cacheKey, Map<String, dynamic> zoneData) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.zoneCacheBoxName);
      // ⚡ Perform JSON encoding in isolate (non-blocking)
      final jsonString = await JsonIsolateHelper.encodeJson(zoneData);
      await box.put(cacheKey, jsonString);
      await _saveTimestamp(
          HiveCacheConfig.zoneCacheBoxName, cacheKey, DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint('💾 HiveHomeCacheService: Saved zone data for key $cacheKey');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving zone data - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Load zone data from Hive
  /// ⚡ PERFORMANCE: LazyBox + JSON decoding in isolate
  /// Returns cached data if available and valid (0ms load time)
  Future<Map<String, dynamic>?> loadZoneData(String cacheKey) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      if (!await _isCacheValid(
          HiveCacheConfig.zoneCacheBoxName, cacheKey, 'zone')) {
        return null;
      }

      final box = await _getLazyBox(HiveCacheConfig.zoneCacheBoxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get(cacheKey);
      if (data != null && data is String) {
        // ⚡ Perform JSON decoding in isolate (non-blocking)
        final jsonMap = await JsonIsolateHelper.decodeJson(data);
        if (kDebugMode) {
          debugPrint('📦 HiveHomeCacheService: Loaded zone data for key $cacheKey');
        }
        return jsonMap;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading zone data - $e');
      }
      return null;
    }
  }

  // ============================================================
  // CART CACHE (SWR Pattern - Instant Loading)
  // ============================================================

  /// Save cart data to Hive for instant loading
  /// ⚡ PERFORMANCE: Uses LazyBox + JSON encoding in isolate
  Future<void> saveCartData(
      int? moduleId, List<Map<String, dynamic>> cartListJson) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.cartCacheBoxName);
      final cacheKey =
          moduleId != null ? 'cart_module_$moduleId' : 'cart_global';
      // ⚡ Perform JSON encoding in isolate (non-blocking)
      final jsonString =
          await JsonIsolateHelper.encodeJson({'cartList': cartListJson});
      await box.put(cacheKey, jsonString);
      await _saveTimestamp(
          HiveCacheConfig.cartCacheBoxName, cacheKey, DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved cart data for module ${moduleId ?? 'global'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving cart data - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// Load cart data from Hive
  /// ⚡ PERFORMANCE: LazyBox + JSON decoding in isolate
  /// Returns cached data if available and valid (0ms load time)
  Future<List<Map<String, dynamic>>?> loadCartData(int? moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final cacheKey =
          moduleId != null ? 'cart_module_$moduleId' : 'cart_global';
      if (!await _isCacheValid(
          HiveCacheConfig.cartCacheBoxName, cacheKey, 'cart')) {
        return null;
      }

      final box = await _getLazyBox(HiveCacheConfig.cartCacheBoxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get(cacheKey);
      if (data != null && data is String) {
        // ⚡ Perform JSON decoding in isolate (non-blocking)
        final jsonMap = await JsonIsolateHelper.decodeJson(data);
        if (jsonMap['cartList'] != null) {
          final cartList =
              (jsonMap['cartList'] as List).cast<Map<String, dynamic>>();
          if (kDebugMode) {
            debugPrint(
                '📦 HiveHomeCacheService: Loaded ${cartList.length} cart items for module ${moduleId ?? 'global'}');
          }
          return cartList;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading cart data - $e');
      }
      return null;
    }
  }

  // ============================================================
  // SESSION CONFIG CACHE (Zone ID & Coordinates)
  // ============================================================

  /// Save last known zone ID and coordinates to session config
  /// ⚡ PERFORMANCE: Uses LazyBox for instant access
  Future<void> saveLastKnownZone({
    required int zoneId,
    required String latitude,
    required String longitude,
  }) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.sessionConfigBoxName);
      final zoneData = {
        'zoneId': zoneId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      // ⚡ Perform JSON encoding in isolate (non-blocking)
      final jsonString = await JsonIsolateHelper.encodeJson(zoneData);
      await box.put('last_known_zone_id', jsonString);
      await _saveTimestamp(HiveCacheConfig.sessionConfigBoxName,
          'last_known_zone_id', DateTime.now());
      // 🔧 CRITICAL FIX: Flush to ensure data is persisted to disk immediately
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved last known zone ID $zoneId for coordinates $latitude,$longitude');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error saving last known zone - $e');
      }
      throw HiveCacheConfig.boxNotFound;
    }
  }

  /// 🏗️ MODULE-FIRST ARCHITECTURE: Save last selected module ID
  /// Persists user's module selection for next app launch
  static Future<void> saveLastSelectedModuleId(int moduleId) async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return;
    }

    try {
      final service = HiveHomeCacheService();
      final box =
          await service._getLazyBox(HiveCacheConfig.sessionConfigBoxName);
      await box.put('last_selected_module_id', moduleId);
      await box.flush();
      if (kDebugMode) {
        debugPrint(
            '💾 HiveHomeCacheService: Saved last selected module ID: $moduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ HiveHomeCacheService: Error saving last selected module ID - $e');
      }
    }
  }

  /// 🏗️ MODULE-FIRST ARCHITECTURE: Get last selected module ID
  /// Returns cached module ID or null if not found
  static Future<int?> getLastSelectedModuleId() async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final service = HiveHomeCacheService();
      final box =
          await service._getLazyBox(HiveCacheConfig.sessionConfigBoxName);
      final moduleId = await box.get('last_selected_module_id');
      if (moduleId != null && moduleId is int) {
        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded last selected module ID: $moduleId');
        }
        return moduleId;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ HiveHomeCacheService: Error loading last selected module ID - $e');
      }
      return null;
    }
  }

  /// 🔄 APP UPGRADE: Wipe ALL Hive-backed cache from disk.
  ///
  /// Hive holds only disposable cache here (app config, module list, per-module
  /// home data, zone cache, cart cache, and the last-selected module id). The
  /// auth token and saved address live in SharedPreferences and are NOT touched,
  /// so wiping Hive on an app upgrade is safe and reproduces a fresh-install
  /// state for the home layout without logging the user out.
  Future<void> wipeForUpgrade() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      // Close every box we currently hold so the on-disk files can be deleted.
      for (final box in _openLazyBoxes.values) {
        try {
          if (box.isOpen) {
            await box.close();
          }
        } catch (_) {
          // Ignore individual close failures — deleteFromDisk handles the rest.
        }
      }
      _openLazyBoxes.clear();
      await Hive.deleteFromDisk();
      if (kDebugMode) {
        debugPrint(
            '🗑️ HiveHomeCacheService: All Hive cache wiped for app upgrade');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveHomeCacheService: wipeForUpgrade failed - $e');
      }
    }
  }

  /// Load last known zone ID and coordinates from session config
  /// ⚡ PERFORMANCE: LazyBox + JSON decoding in isolate (0ms load time)
  Future<Map<String, dynamic>?> loadLastKnownZone() async {
    if (!HiveCacheConfig.isHiveEnabled) {
      return null;
    }

    try {
      final box = await _getLazyBox(HiveCacheConfig.sessionConfigBoxName);
      // ⚡ LazyBox.get() is async - must await
      final data = await box.get('last_known_zone_id');
      if (data != null && data is String) {
        // ⚡ Perform JSON decoding in isolate (non-blocking)
        final jsonMap = await JsonIsolateHelper.decodeJson(data);
        if (kDebugMode) {
          debugPrint(
              '📦 HiveHomeCacheService: Loaded last known zone ID ${jsonMap['zoneId']}');
        }
        return jsonMap;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveHomeCacheService: Error loading last known zone - $e');
      }
      return null;
    }
  }
}

