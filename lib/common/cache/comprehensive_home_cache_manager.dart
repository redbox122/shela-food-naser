import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/hive_cache_config.dart';
import 'package:sixam_mart/core/isolate/json_isolate_helper.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/banner/domain/models/promotional_banner_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

/// Comprehensive Home Cache Manager
/// Caches ALL home screen sections for truly instant loading
/// ⚡ MODULE-SPECIFIC CACHING: Each module has its own isolated cache
/// This prevents data from different modules overwriting each other
class ComprehensiveHomeCacheManager {
  // Base cache key patterns (will be made module-specific)
  static const String _bannerCacheKeyPattern =
      'comprehensive_banner_cache_module_';
  static const String _categoryCacheKeyPattern =
      'comprehensive_category_cache_module_';
  static const String _brandCacheKeyPattern =
      'comprehensive_brand_cache_module_';
  static const String _storeCacheKeyPattern =
      'comprehensive_store_cache_module_';
  static const String _offersCacheKeyPattern =
      'comprehensive_offers_cache_module_';
  static const String _businessSettingsCacheKeyPattern =
      'comprehensive_business_settings_cache_module_';
  static const String _timestampKeyPattern =
      'comprehensive_home_timestamp_module_';
  static const String _versionKeyPattern = 'comprehensive_home_version_module_';
  static const String _userStateKeyPattern =
      'comprehensive_home_user_state_module_';

  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Generate module-specific cache key
  static String _getCacheKey(String pattern, int? moduleId) {
    final moduleIdStr = moduleId?.toString() ?? '0';
    return '$pattern$moduleIdStr';
  }

  /// Get current module ID from splash controller
  static int? _getCurrentModuleId() {
    try {
      return Get.find<SplashController>().module?.id;
    } catch (e) {
      return null;
    }
  }

  // Flag to prevent cache saving during logout
  static bool _isLogoutInProgress = false;

  /// Set logout flag to prevent cache saving during logout
  static void setLogoutInProgress(bool value) {
    _isLogoutInProgress = value;
  }

  /// Check if we should force data restoration due to user state change
  static Future<bool> shouldForceDataRestoration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentModuleId = _getCurrentModuleId();
      final userStateKey = _getCacheKey(_userStateKeyPattern, currentModuleId);
      final cachedUserState = prefs.getString(userStateKey);
      final currentUserState = AuthHelper.isLoggedIn() ? 'logged_in' : 'guest';

      if (cachedUserState != currentUserState) {
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error checking user state - $e');
      }
      return false;
    }
  }

  /// Check if comprehensive home cache is valid for current module
  static Future<bool> isCacheValid() async {
    try {
      final splashController = Get.find<SplashController>();
      final currentModuleId = splashController.module?.id;

      if (currentModuleId == null) {
        return false;
      }

      // Try Hive cache first (fast, binary)
      if (HiveCacheConfig.isHiveEnabled) {
        try {
          final hiveService = HiveHomeCacheService();
          final hiveValid = await hiveService.isCacheValid(currentModuleId);
          if (hiveValid) {
            if (kDebugMode) {
              debugPrint(
                  '✅ Comprehensive Cache: Hive cache valid for module $currentModuleId');
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ Comprehensive Cache: Hive check failed, falling back to SharedPreferences - $e');
          }
          // Fall through to SharedPreferences check
        }
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bannerCacheKey =
          _getCacheKey(_bannerCacheKeyPattern, currentModuleId);
      final categoryCacheKey =
          _getCacheKey(_categoryCacheKeyPattern, currentModuleId);
      final brandCacheKey =
          _getCacheKey(_brandCacheKeyPattern, currentModuleId);
      final storeCacheKey =
          _getCacheKey(_storeCacheKeyPattern, currentModuleId);
      final offersCacheKey =
          _getCacheKey(_offersCacheKeyPattern, currentModuleId);
      final timestampKey = _getCacheKey(_timestampKeyPattern, currentModuleId);

      // Check if any cache exists for this module
      if (!prefs.containsKey(bannerCacheKey) &&
          !prefs.containsKey(categoryCacheKey) &&
          !prefs.containsKey(brandCacheKey) &&
          !prefs.containsKey(storeCacheKey) &&
          !prefs.containsKey(offersCacheKey)) {
        if (kDebugMode) {
          debugPrint(
              '🔄 Comprehensive Cache: No cache found for module $currentModuleId');
        }
        return false;
      }

      // Check timestamp for this module
      final timestamp = prefs.getInt(timestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = Duration(milliseconds: now - timestamp);

      if (age > _cacheExpiry) {
        if (kDebugMode) {
          debugPrint(
              '🔄 Comprehensive Cache: Cache expired for module $currentModuleId (${age.inHours}h old)');
        }
        return false;
      }

      // Check app version (only for major changes)
      final versionKey = _getCacheKey(_versionKeyPattern, currentModuleId);
      final cachedVersion = prefs.getString(versionKey);
      final currentVersion =
          splashController.configModel?.appMinimumVersionAndroid?.toString() ??
              '1.0.0';

      // Only invalidate if it's a major version change (e.g., 1.0.0 -> 2.0.0)
      if (cachedVersion != null && cachedVersion != currentVersion) {
        final cachedMajor = cachedVersion.split('.').first;
        final currentMajor = currentVersion.split('.').first;

        if (cachedMajor != currentMajor) {
          if (kDebugMode) {
            debugPrint(
                '🔄 Comprehensive Cache: App version changed for module $currentModuleId ($cachedVersion -> $currentVersion)');
          }
          return false;
        }
      }

      // User state changes should NEVER affect e-commerce cache
      // E-commerce data (banners, categories, brands, stores) is independent of user authentication
      final userStateKey = _getCacheKey(_userStateKeyPattern, currentModuleId);
      final cachedUserState = prefs.getString(userStateKey);
      final currentUserState = AuthHelper.isLoggedIn() ? 'logged_in' : 'guest';

      if (cachedUserState != currentUserState) {
        // Update user state in cache but NEVER invalidate e-commerce data
        await prefs.setString(userStateKey, currentUserState);
      }

      // CRITICAL: Check if cached data actually contains meaningful content
      if (!await _hasValidCachedData(prefs, currentModuleId)) {
        // Clear the invalid cache immediately
        await clearComprehensiveCache(currentModuleId);
        return false;
      }

      // CRITICAL: Test data restoration to ensure controllers will have data
      if (!await _testDataRestoration(prefs, currentModuleId)) {
        // Clear the invalid cache immediately
        await clearComprehensiveCache(currentModuleId);
        return false;
      }

      if (kDebugMode) {
        debugPrint('✅ Comprehensive Cache: Cache valid for module $currentModuleId');
      }
      return true;
    } catch (e) {
      debugPrint('❌ Comprehensive Cache: Error checking validity - $e');
      return false;
    }
  }

  /// Check if cached data actually contains meaningful content for a module
  static Future<bool> _hasValidCachedData(
      SharedPreferences prefs, int? moduleId) async {
    try {
      final bannerCacheKey = _getCacheKey(_bannerCacheKeyPattern, moduleId);
      final categoryCacheKey = _getCacheKey(_categoryCacheKeyPattern, moduleId);
      final brandCacheKey = _getCacheKey(_brandCacheKeyPattern, moduleId);
      final offersCacheKey = _getCacheKey(_offersCacheKeyPattern, moduleId);

      // Check banner data
      final bannerData = prefs.getString(bannerCacheKey);
      if (bannerData != null) {
        final bannerMap = jsonDecode(bannerData) as Map<String, dynamic>;
        final bannerImageList = bannerMap['bannerImageList'] as List? ?? [];
        if (bannerImageList.isEmpty) {
          return false;
        }
      }

      // Check category data
      final categoryData = prefs.getString(categoryCacheKey);
      if (categoryData != null) {
        final categoryMap = jsonDecode(categoryData) as Map<String, dynamic>;
        final categoryList = categoryMap['categoryList'] as List? ?? [];
        if (categoryList.isEmpty) {
          return false;
        }
      }

      // Check brand data
      final brandData = prefs.getString(brandCacheKey);
      if (brandData != null) {
        final brandMap = jsonDecode(brandData) as Map<String, dynamic>;
        final brandList = brandMap['brandList'] as List? ?? [];
        if (brandList.isEmpty) {
          return false;
        }
      }

      // Check offers data
      final offersData = prefs.getString(offersCacheKey);
      if (offersData != null) {
        final offersMap = jsonDecode(offersData) as Map<String, dynamic>;
        final offersList = offersMap['data'] as List? ?? [];
        if (offersList.isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Comprehensive Cache: Error validating cached data - $e');
      return false;
    }
  }

  /// Test if data restoration will work by attempting to restore data to controllers
  static Future<bool> _testDataRestoration(
      SharedPreferences prefs, int? moduleId) async {
    try {
      // Load cached data for this module
      final cachedData = await loadAllHomeData(moduleId);

      if (cachedData.isEmpty) {
        return false;
      }

      // Test restoration without actually modifying controllers

      // Test banner data parsing
      if (cachedData.containsKey('banners')) {
        final bannerData = cachedData['banners'] as Map<String, dynamic>;
        final bannerImageListData =
            bannerData['bannerImageList'] as List<dynamic>?;
        final bannerImageList = List<String?>.from(bannerImageListData ?? []);
        if (bannerImageList.isEmpty) {
          return false;
        }
      }

      // Test category data parsing
      if (cachedData.containsKey('categories')) {
        final categoryData = cachedData['categories'] as Map<String, dynamic>;
        if (categoryData['categoryList'] == null) {
          return false;
        }
        final categoryList = categoryData['categoryList'] as List;
        if (categoryList.isEmpty) {
          return false;
        }
      }

      // Test brand data parsing
      if (cachedData.containsKey('brands')) {
        final brandData = cachedData['brands'] as Map<String, dynamic>;
        if (brandData['brandList'] == null) {
          return false;
        }
        final brandList = brandData['brandList'] as List;
        if (brandList.isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Comprehensive Cache: Data restoration test failed - $e');
      return false;
    }
  }

  /// Save all home screen data to cache for current module
  static Future<void> saveAllHomeData() async {
    // Don't save cache during logout to prevent saving empty data
    if (_isLogoutInProgress) {
      return;
    }

    try {
      // CRITICAL: Check if controllers have meaningful data before saving
      if (!await _controllersHaveValidData()) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final splashController = Get.find<SplashController>();
      final currentModuleId = splashController.module?.id;

      if (currentModuleId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Comprehensive Cache: Cannot save - no module ID');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '💾 Comprehensive Cache: Saving data for module $currentModuleId');
      }

      // Save actual data from controllers (module-specific)
      // Save to both Hive and SharedPreferences (dual-write during transition)
      await _saveBannerData(prefs, currentModuleId);
      await _saveCategoryData(prefs, currentModuleId);
      await _saveBrandData(prefs, currentModuleId);
      await _saveStoreData(prefs, currentModuleId);
      await _saveOffersData(prefs, currentModuleId);
      await _saveBusinessSettingsData(prefs, currentModuleId);

      // Save metadata (module-specific)
      final timestampKey = _getCacheKey(_timestampKeyPattern, currentModuleId);
      final versionKey = _getCacheKey(_versionKeyPattern, currentModuleId);
      final userStateKey = _getCacheKey(_userStateKeyPattern, currentModuleId);

      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(
          versionKey,
          splashController.configModel?.appMinimumVersionAndroid?.toString() ??
              '1.0.0');
      await prefs.setString(
          userStateKey, AuthHelper.isLoggedIn() ? 'logged_in' : 'guest');

      if (kDebugMode) {
        debugPrint('✅ Comprehensive Cache: Data saved for module $currentModuleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error saving data - $e');
      }
    }
  }

  /// Check if controllers have valid data before saving
  static Future<bool> _controllersHaveValidData() async {
    try {
      bool hasAnyData = false;

      // Check banner data
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        if (bannerController.bannerImageList != null &&
            bannerController.bannerImageList!.isNotEmpty) {
          hasAnyData = true;
        }
      }

      // Check category data
      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        if (categoryController.categoryList != null &&
            categoryController.categoryList!.isNotEmpty) {
          hasAnyData = true;
        }
      }

      // Check brand data
      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        if (brandsController.brandList != null &&
            brandsController.brandList!.isNotEmpty) {
          hasAnyData = true;
        }
      }

      return hasAnyData;
    } catch (e) {
      debugPrint('❌ Comprehensive Cache: Error checking controller data - $e');
      return false;
    }
  }

  /// Save banner data from controller (module-specific)
  /// ⚡ PERFORMANCE: JSON encoding performed in isolate to avoid blocking main thread
  static Future<void> _saveBannerData(
      SharedPreferences prefs, int moduleId) async {
    try {
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        final bannerCacheKey = _getCacheKey(_bannerCacheKeyPattern, moduleId);

        final bannerData = {
          'bannerImageList': bannerController.bannerImageList,
          'bannerDataList': bannerController.bannerDataList,
          'featuredBannerList': bannerController.featuredBannerList,
          'featuredBannerDataList': bannerController.featuredBannerDataList,
          'promotionalBanner': bannerController.promotionalBanner?.toJson(),
        };
        // ⚡ Use isolate for JSON encoding
        final jsonString =
            await JsonIsolateHelper.serializeBannerData(bannerData);
        await prefs.setString(bannerCacheKey, jsonString);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error saving banner data - $e');
      }
    }
  }

  /// Save category data from controller (module-specific)
  /// ⚡ PERFORMANCE: JSON encoding performed in isolate to avoid blocking main thread
  static Future<void> _saveCategoryData(
      SharedPreferences prefs, int moduleId) async {
    try {
      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        final categoryCacheKey =
            _getCacheKey(_categoryCacheKeyPattern, moduleId);

        // ⚡ CRITICAL: Only save categories that belong to this module
        final moduleCategories = categoryController.categoryList
            ?.where((c) => c.moduleId == moduleId && c.storeId == null)
            .toList();

        final categoryData = {
          'categoryList':
              moduleCategories?.map((c) => c.toJson()).toList() ?? [],
        };
        // ⚡ Use isolate for JSON encoding
        final jsonString = await JsonIsolateHelper.encodeJson(categoryData);
        await prefs.setString(categoryCacheKey, jsonString);

        // Also save to Hive
        if (HiveCacheConfig.isHiveEnabled &&
            moduleCategories != null &&
            moduleCategories.isNotEmpty) {
          try {
            final hiveService = HiveHomeCacheService();
            await hiveService.saveCategories(moduleId, moduleCategories);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Comprehensive Cache: Failed to save categories to Hive - $e');
            }
          }
        }

        if (kDebugMode) {
          debugPrint(
              '💾 Comprehensive Cache: Saved ${moduleCategories?.length ?? 0} categories for module $moduleId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error saving category data - $e');
      }
    }
  }

  /// Save brand data from controller (module-specific)
  /// ⚡ PERFORMANCE: JSON encoding performed in isolate to avoid blocking main thread
  static Future<void> _saveBrandData(
      SharedPreferences prefs, int moduleId) async {
    try {
      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        final brandCacheKey = _getCacheKey(_brandCacheKeyPattern, moduleId);

        final brandData = {
          'brandList':
              brandsController.brandList?.map((b) => b.toJson()).toList() ?? [],
        };
        // ⚡ Use isolate for JSON encoding
        final jsonString = await JsonIsolateHelper.encodeJson(brandData);
        await prefs.setString(brandCacheKey, jsonString);

        // Also save to Hive
        if (HiveCacheConfig.isHiveEnabled &&
            brandsController.brandList != null &&
            brandsController.brandList!.isNotEmpty) {
          try {
            final hiveService = HiveHomeCacheService();
            await hiveService.saveBrands(moduleId, brandsController.brandList!);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Comprehensive Cache: Failed to save brands to Hive - $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error saving brand data - $e');
      }
    }
  }

  /// Save offers data from controller (module-specific)
  static Future<void> _saveOffersData(
      SharedPreferences prefs, int moduleId) async {
    try {
      if (Get.isRegistered<OffersController>()) {
        final offersController = Get.find<OffersController>();
        final offersCacheKey = _getCacheKey(_offersCacheKeyPattern, moduleId);

        final offersData = {
          'data': offersController.offersMode?.data
                  .map((o) => {
                        'id': o.id,
                        'reference': o.reference,
                        'name': o.name,
                        'start_date': o.startDate,
                        'end_date': o.endDate,
                        'discount_max': o.discountMax,
                        'banner': o.banner,
                        'created_at': o.createdAt,
                        'updated_at': o.updatedAt,
                        'items_count': o.itemsCount,
                        'active': o.active,
                        'status': o.status,
                      })
                  .toList() ??
              [],
          'success': offersController.offersMode?.success ?? false,
          'message': offersController.offersMode?.message ?? '',
        };
        // ⚡ Use isolate for JSON encoding
        final jsonString =
            await JsonIsolateHelper.serializeOffersData(offersData);
        await prefs.setString(offersCacheKey, jsonString);

        // Also save to Hive
        if (HiveCacheConfig.isHiveEnabled &&
            offersController.offersMode != null) {
          try {
            final hiveService = HiveHomeCacheService();
            await hiveService.saveOffers(
                moduleId, offersController.offersMode!);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Comprehensive Cache: Failed to save offers to Hive - $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error saving offers data - $e');
      }
    }
  }

  /// Save store data from controller (module-specific)
  static Future<void> _saveStoreData(
      SharedPreferences prefs, int moduleId) async {
    try {
      if (Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        final storeCacheKey = _getCacheKey(_storeCacheKeyPattern, moduleId);

        // Safely convert all data to JSON-serializable format
        final storeData = <String, dynamic>{};

        // ⚡ CRITICAL: Only save stores that belong to this module
        if (storeController.storeModel != null) {
          final moduleStores = storeController.storeModel!.stores
              ?.where((s) => s.moduleId == moduleId)
              .toList();
          if (moduleStores != null && moduleStores.isNotEmpty) {
            // Create new StoreModel with filtered stores
            final filteredStoreModel = StoreModel(
              totalSize: storeController.storeModel!.totalSize,
              limit: storeController.storeModel!.limit,
              offset: storeController.storeModel!.offset,
              stores: moduleStores,
            );
            storeData['storeModel'] = filteredStoreModel.toJson();
          }
        }
        if (storeController.store != null &&
            storeController.store!.moduleId == moduleId) {
          storeData['store'] = storeController.store!.toJson();
        }
        if (storeController.featuredStoreList != null) {
          final moduleFeaturedStores = storeController.featuredStoreList!
              .where((s) => s.moduleId == moduleId)
              .toList();
          if (moduleFeaturedStores.isNotEmpty) {
            storeData['featuredStoreList'] =
                moduleFeaturedStores.map((s) => s.toJson()).toList();
          }
        }
        if (storeController.popularStoreList != null) {
          final modulePopularStores = storeController.popularStoreList!
              .where((s) => s.moduleId == moduleId)
              .toList();
          if (modulePopularStores.isNotEmpty) {
            storeData['popularStoreList'] =
                modulePopularStores.map((s) => s.toJson()).toList();
          }
        }
        if (storeController.latestStoreList != null) {
          final moduleLatestStores = storeController.latestStoreList!
              .where((s) => s.moduleId == moduleId)
              .toList();
          if (moduleLatestStores.isNotEmpty) {
            storeData['latestStoreList'] =
                moduleLatestStores.map((s) => s.toJson()).toList();
          }
        }
        if (storeController.topOfferStoreList != null) {
          final moduleTopOfferStores = storeController.topOfferStoreList!
              .where((s) => s.moduleId == moduleId)
              .toList();
          if (moduleTopOfferStores.isNotEmpty) {
            storeData['topOfferStoreList'] =
                moduleTopOfferStores.map((s) => s.toJson()).toList();
          }
        }
        if (storeController.visitAgainStoreList != null) {
          final moduleVisitAgainStores = storeController.visitAgainStoreList!
              .where((s) => s.moduleId == moduleId)
              .toList();
          if (moduleVisitAgainStores.isNotEmpty) {
            storeData['visitAgainStoreList'] =
                moduleVisitAgainStores.map((s) => s.toJson()).toList();
          }
        }

        // ⚡ Use isolate for JSON encoding (stores can be large)
        final jsonString =
            await JsonIsolateHelper.serializeStoreData(storeData);
        await prefs.setString(storeCacheKey, jsonString);

        // Also save to Hive
        if (HiveCacheConfig.isHiveEnabled && storeData['storeModel'] != null) {
          try {
            final storeModel = StoreModel.fromJson(
                storeData['storeModel'] as Map<String, dynamic>);
            final hiveService = HiveHomeCacheService();
            await hiveService.saveStores(moduleId, storeModel);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Comprehensive Cache: Failed to save stores to Hive - $e');
            }
          }
        }

        if (kDebugMode) {
          final totalStores =
              (storeData['storeModel']?['stores'] as List?)?.length ?? 0;
          debugPrint(
              '💾 Comprehensive Cache: Saved $totalStores stores for module $moduleId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error saving store data - $e');
      }
    }
  }

  /// Save business settings data from controller (module-specific)
  static Future<void> _saveBusinessSettingsData(
      SharedPreferences prefs, int moduleId) async {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        final businessSettingsCacheKey =
            _getCacheKey(_businessSettingsCacheKeyPattern, moduleId);

        final businessData = {
          'businessSettings': homeController.business_Settings?.toJson(),
        };
        await prefs.setString(
            businessSettingsCacheKey, jsonEncode(businessData));

        // Also save to Hive
        if (HiveCacheConfig.isHiveEnabled &&
            homeController.business_Settings != null) {
          try {
            final hiveService = HiveHomeCacheService();
            await hiveService.saveBusinessSettings(
                moduleId, homeController.business_Settings!);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Comprehensive Cache: Failed to save business settings to Hive - $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ Comprehensive Cache: Error saving business settings data - $e');
      }
    }
  }

  /// Load all home screen data from cache for current module
  static Future<Map<String, dynamic>> loadAllHomeData([int? moduleId]) async {
    final result = <String, dynamic>{};

    try {
      // Use provided moduleId or get current module ID
      final currentModuleId = moduleId ?? _getCurrentModuleId();

      if (currentModuleId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Comprehensive Cache: Cannot load - no module ID');
        }
        return result;
      }

      // Try Hive cache first (fast, binary)
      if (HiveCacheConfig.isHiveEnabled) {
        try {
          final hiveService = HiveHomeCacheService();

          // Load from Hive
          // Note: Banners are loaded but skipped in result map (complex conversion needed)
          await hiveService.loadBanners(currentModuleId);
          final categories = await hiveService.loadCategories(currentModuleId);
          final stores = await hiveService.loadStores(currentModuleId);
          final brands = await hiveService.loadBrands(currentModuleId);
          final offers = await hiveService.loadOffers(currentModuleId);
          final businessSettings =
              await hiveService.loadBusinessSettings(currentModuleId);

          // Build result map from Hive data
          // Note: Banners are complex and need special conversion, so we skip them for now
          // They'll be loaded from API in background if needed
          // This ensures cache restoration succeeds even without banners
          if (categories != null && categories.isNotEmpty) {
            result['categories'] = {
              'categoryList': categories.map((c) => c.toJson()).toList(),
            };
          }
          if (stores != null) {
            result['stores'] = {
              'storeModel': stores.toJson(),
            };
          }
          if (brands != null && brands.isNotEmpty) {
            result['brands'] = {
              'brandList': brands.map((b) => b.toJson()).toList(),
            };
          }
          if (offers != null) {
            result['offers'] = {
              'data': offers.data.map((o) => o.toJson()).toList(),
              'success': offers.success,
              'message': offers.message,
            };
          }
          if (businessSettings != null) {
            result['businessSettings'] = {
              'businessSettings': businessSettings.toJson(),
            };
          }

          if (result.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                  '📦 Comprehensive Cache: Loaded data from Hive for module $currentModuleId');
            }
            return result;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ Comprehensive Cache: Hive load failed, falling back to SharedPreferences - $e');
          }
          // Fall through to SharedPreferences
        }
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bannerCacheKey =
          _getCacheKey(_bannerCacheKeyPattern, currentModuleId);
      final categoryCacheKey =
          _getCacheKey(_categoryCacheKeyPattern, currentModuleId);
      final brandCacheKey =
          _getCacheKey(_brandCacheKeyPattern, currentModuleId);
      final storeCacheKey =
          _getCacheKey(_storeCacheKeyPattern, currentModuleId);
      final offersCacheKey =
          _getCacheKey(_offersCacheKeyPattern, currentModuleId);
      final businessSettingsCacheKey =
          _getCacheKey(_businessSettingsCacheKeyPattern, currentModuleId);

      // ⚡ PERFORMANCE: Load and parse all cache data in parallel using isolates
      final futures = <Future<void>>[];

      // Load banners
      if (prefs.containsKey(bannerCacheKey)) {
        final bannerData = prefs.getString(bannerCacheKey);
        if (bannerData != null && bannerData != 'cached') {
          futures.add(
              JsonIsolateHelper.deserializeBannerData(bannerData).then((data) {
            result['banners'] = data;
          }));
        }
      }

      // Load categories
      if (prefs.containsKey(categoryCacheKey)) {
        final categoryData = prefs.getString(categoryCacheKey);
        if (categoryData != null && categoryData != 'cached') {
          futures.add(JsonIsolateHelper.decodeJson(categoryData).then((data) {
            result['categories'] = data;
          }));
        }
      }

      // Load brands
      if (prefs.containsKey(brandCacheKey)) {
        final brandData = prefs.getString(brandCacheKey);
        if (brandData != null && brandData != 'cached') {
          futures.add(JsonIsolateHelper.decodeJson(brandData).then((data) {
            result['brands'] = data;
          }));
        }
      }

      // Load stores
      if (prefs.containsKey(storeCacheKey)) {
        final storeData = prefs.getString(storeCacheKey);
        if (storeData != null && storeData != 'cached') {
          futures.add(
              JsonIsolateHelper.deserializeStoreData(storeData).then((data) {
            result['stores'] = data;
          }));
        }
      }

      // Load offers
      if (prefs.containsKey(offersCacheKey)) {
        final offersData = prefs.getString(offersCacheKey);
        if (offersData != null && offersData != 'cached') {
          futures.add(
              JsonIsolateHelper.deserializeOffersData(offersData).then((data) {
            result['offers'] = data;
          }));
        }
      }

      // Load business settings
      if (prefs.containsKey(businessSettingsCacheKey)) {
        final businessData = prefs.getString(businessSettingsCacheKey);
        if (businessData != null && businessData != 'cached') {
          futures.add(JsonIsolateHelper.decodeJson(businessData).then((data) {
            result['businessSettings'] = data;
          }));
        }
      }

      // ⚡ Wait for all parallel JSON parsing to complete
      await Future.wait(futures);

      if (kDebugMode && result.isNotEmpty) {
        debugPrint(
            '📦 Comprehensive Cache: Loaded data from SharedPreferences for module $currentModuleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error loading data - $e');
      }
    }

    return result;
  }

  /// Restore data to controllers
  static Future<void> restoreDataToControllers(
      Map<String, dynamic> cachedData) async {
    try {
      // Restore banner data directly to controller
      if (Get.isRegistered<BannerController>() &&
          cachedData.containsKey('banners')) {
        final bannerController = Get.find<BannerController>();
        final bannerData = cachedData['banners'] as Map<String, dynamic>;

        // Parse promotional banner if exists
        PromotionalBanner? promotionalBanner;
        if (bannerData['promotionalBanner'] != null) {
          try {
            // ⚡ FIX: Ensure we have a Map before calling fromJson
            final promoData = bannerData['promotionalBanner'];
            if (promoData is Map<String, dynamic>) {
              promotionalBanner = PromotionalBanner.fromJson(promoData);
            } else if (promoData is String) {
              // If stored as JSON string, parse it first
              final decoded = jsonDecode(promoData) as Map<String, dynamic>;
              promotionalBanner = PromotionalBanner.fromJson(decoded);
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Comprehensive Cache: Error parsing promotional banner: $e');
            }
            promotionalBanner = null;
          }
        }

        final bannerImageListData =
            bannerData['bannerImageList'] as List<dynamic>?;
        final bannerImageList = List<String?>.from(bannerImageListData ?? []);
        final bannerDataList = bannerData['bannerDataList'] as List<dynamic>?;

        // Only restore if we have actual data
        if (bannerImageList.isNotEmpty ||
            (bannerDataList?.isNotEmpty ?? false)) {
          try {
            final featuredBannerListData =
                bannerData['featuredBannerList'] as List<dynamic>?;
            bannerController.setBannerDataFromCache(
              bannerImageList: bannerImageList,
              bannerDataList: bannerDataList,
              featuredBannerList:
                  List<String?>.from(featuredBannerListData ?? []),
              featuredBannerDataList:
                  bannerData['featuredBannerDataList'] as List<dynamic>?,
              promotionalBanner: promotionalBanner,
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Comprehensive Cache: Error restoring banner data - $e');
            }
          }
        }
      }

      // Restore category data directly to controller
      // ⚡ Since cache is now module-specific, no filtering needed!
      if (Get.isRegistered<CategoryController>() &&
          cachedData.containsKey('categories')) {
        final categoryController = Get.find<CategoryController>();
        final categoryData = cachedData['categories'] as Map<String, dynamic>;
        final currentModuleId = _getCurrentModuleId();

        if (categoryData['categoryList'] != null) {
          try {
            final categoryList = (categoryData['categoryList'] as List<dynamic>)
                .map((json) =>
                    CategoryModel.fromJson(json as Map<String, dynamic>))
                .toList();

            if (kDebugMode) {
              debugPrint(
                  '📦 Comprehensive Cache: Restoring ${categoryList.length} categories (already filtered by module)');
            }

            categoryController.setCategoryDataFromCache(
              categoryList,
              expectedModuleId: currentModuleId,
            );

            // Debug: Verify data was actually set
            await Future<void>.delayed(const Duration(milliseconds: 100));
            if (kDebugMode) {
              debugPrint(
                  '🔍 Comprehensive Cache: Category controller verification:');
              debugPrint(
                  '  - categoryList: ${categoryController.categoryList?.length ?? 0} items');
            }
          } catch (e) {
            debugPrint('❌ Comprehensive Cache: Error restoring category data - $e');
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Comprehensive Cache: No categoryList in cached data');
            debugPrint('  - Available keys: ${categoryData.keys.toList()}');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ Comprehensive Cache: CategoryController not registered or no categories in cache');
        }
      }

      // Restore brand data directly to controller
      if (Get.isRegistered<BrandsController>() &&
          cachedData.containsKey('brands')) {
        final brandsController = Get.find<BrandsController>();
        final brandData = cachedData['brands'] as Map<String, dynamic>;

        if (brandData['brandList'] != null) {
          try {
            final brandList = (brandData['brandList'] as List<dynamic>)
                .map(
                    (json) => BrandModel.fromJson(json as Map<String, dynamic>))
                .toList();
            brandsController.setBrandDataFromCache(brandList);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Comprehensive Cache: Error restoring brand data - $e');
            }
          }
        }
      }

      // Restore store data directly to controller
      if (Get.isRegistered<StoreController>() &&
          cachedData.containsKey('stores')) {
        final storeController = Get.find<StoreController>();
        final storeData = cachedData['stores'] as Map<String, dynamic>;

        // Parse store model if exists
        StoreModel? storeModel;
        if (storeData['storeModel'] != null) {
          storeModel = StoreModel.fromJson(
              storeData['storeModel'] as Map<String, dynamic>);
        }

        // Parse individual store lists
        List<Store>? featuredStoreList;
        if (storeData['featuredStoreList'] != null) {
          featuredStoreList = (storeData['featuredStoreList'] as List<dynamic>)
              .map((json) => Store.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        List<Store>? popularStoreList;
        if (storeData['popularStoreList'] != null) {
          popularStoreList = (storeData['popularStoreList'] as List<dynamic>)
              .map((json) => Store.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        List<Store>? latestStoreList;
        if (storeData['latestStoreList'] != null) {
          latestStoreList = (storeData['latestStoreList'] as List<dynamic>)
              .map((json) => Store.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        List<Store>? topOfferStoreList;
        if (storeData['topOfferStoreList'] != null) {
          topOfferStoreList = (storeData['topOfferStoreList'] as List<dynamic>)
              .map((json) => Store.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        List<Store>? visitAgainStoreList;
        if (storeData['visitAgainStoreList'] != null) {
          visitAgainStoreList =
              (storeData['visitAgainStoreList'] as List<dynamic>)
                  .map((json) => Store.fromJson(json as Map<String, dynamic>))
                  .toList();
        }

        storeController.setStoreDataFromCache(
          storeModel: storeModel,
          featuredStoreList: featuredStoreList,
          popularStoreList: popularStoreList,
          latestStoreList: latestStoreList,
          topOfferStoreList: topOfferStoreList,
          visitAgainStoreList: visitAgainStoreList,
        );
      }

      // Restore offers data directly to controller
      if (Get.isRegistered<OffersController>() &&
          cachedData.containsKey('offers')) {
        final offersController = Get.find<OffersController>();
        final offersData = cachedData['offers'] as Map<String, dynamic>;

        if (offersData['data'] != null) {
          try {
            final offersList = (offersData['data'] as List<dynamic>)
                .map((json) => Datum.fromJson(json as Map<String, dynamic>))
                .toList();

            final offersModel = OffersModel(
              success: (offersData['success'] as bool?) ?? false,
              data: offersList,
              message: (offersData['message'] as String?) ?? '',
            );

            offersController.offersMode = offersModel;
            offersController.update();
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Comprehensive Cache: Error restoring offers data - $e');
            }
          }
        }
      }

      // Restore business settings data directly to controller
      if (Get.isRegistered<HomeController>() &&
          cachedData.containsKey('businessSettings')) {
        final homeController = Get.find<HomeController>();
        final businessData =
            cachedData['businessSettings'] as Map<String, dynamic>;

        if (businessData['businessSettings'] != null) {
          try {
            final businessSettings = BusinessSettingsModel.fromJson(
                businessData['businessSettings'] as Map<String, dynamic>);
            homeController.setBusinessSettingsFromCache(businessSettings);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '❌ Comprehensive Cache: Error restoring business settings - $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error restoring data - $e');
      }
    }
  }

  /// Clear comprehensive cache for a specific module (or all modules if moduleId is null)
  static Future<void> clearComprehensiveCache([int? moduleId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (moduleId != null) {
        // Clear cache for specific module
        final keys = [
          _getCacheKey(_bannerCacheKeyPattern, moduleId),
          _getCacheKey(_categoryCacheKeyPattern, moduleId),
          _getCacheKey(_brandCacheKeyPattern, moduleId),
          _getCacheKey(_storeCacheKeyPattern, moduleId),
          _getCacheKey(_offersCacheKeyPattern, moduleId),
          _getCacheKey(_businessSettingsCacheKeyPattern, moduleId),
          _getCacheKey(_timestampKeyPattern, moduleId),
          _getCacheKey(_versionKeyPattern, moduleId),
          _getCacheKey(_userStateKeyPattern, moduleId),
        ];

        for (final key in keys) {
          await prefs.remove(key);
        }

        if (kDebugMode) {
          debugPrint('🗑️ Comprehensive Cache: Cleared cache for module $moduleId');
        }
      } else {
        // Clear cache for all modules (find all keys matching patterns)
        final allKeys = prefs.getKeys();
        final patterns = [
          _bannerCacheKeyPattern,
          _categoryCacheKeyPattern,
          _brandCacheKeyPattern,
          _storeCacheKeyPattern,
          _offersCacheKeyPattern,
          _businessSettingsCacheKeyPattern,
          _timestampKeyPattern,
          _versionKeyPattern,
          _userStateKeyPattern,
        ];

        int clearedCount = 0;
        for (final key in allKeys) {
          for (final pattern in patterns) {
            if (key.startsWith(pattern)) {
              await prefs.remove(key);
              clearedCount++;
              break;
            }
          }
        }

        if (kDebugMode) {
          debugPrint(
              '🗑️ Comprehensive Cache: Cleared $clearedCount cache entries for all modules');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive Cache: Error clearing cache - $e');
      }
    }
  }

  /// Get cache statistics for current module
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentModuleId = _getCurrentModuleId();

      if (currentModuleId == null) {
        return {'error': 'No module ID available'};
      }

      final bannerCacheKey =
          _getCacheKey(_bannerCacheKeyPattern, currentModuleId);
      final categoryCacheKey =
          _getCacheKey(_categoryCacheKeyPattern, currentModuleId);
      final brandCacheKey =
          _getCacheKey(_brandCacheKeyPattern, currentModuleId);
      final storeCacheKey =
          _getCacheKey(_storeCacheKeyPattern, currentModuleId);
      final businessSettingsCacheKey =
          _getCacheKey(_businessSettingsCacheKeyPattern, currentModuleId);
      final timestampKey = _getCacheKey(_timestampKeyPattern, currentModuleId);
      final versionKey = _getCacheKey(_versionKeyPattern, currentModuleId);

      final timestamp = prefs.getInt(timestampKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      return {
        'moduleId': currentModuleId,
        'hasBannerCache': prefs.containsKey(bannerCacheKey),
        'hasCategoryCache': prefs.containsKey(categoryCacheKey),
        'hasBrandCache': prefs.containsKey(brandCacheKey),
        'hasStoreCache': prefs.containsKey(storeCacheKey),
        'hasBusinessSettingsCache': prefs.containsKey(businessSettingsCacheKey),
        'cacheAge': Duration(milliseconds: age).inHours,
        'cachedAppVersion': prefs.getString(versionKey),
        'isValid': await isCacheValid(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
