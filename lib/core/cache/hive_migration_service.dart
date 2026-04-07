
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/hive_cache_config.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';

/// Hive Migration Service
/// Migrates existing SharedPreferences cache to Hive (one-time migration)
class HiveMigrationService {
  static final HiveMigrationService _instance =
      HiveMigrationService._internal();
  factory HiveMigrationService() => _instance;
  HiveMigrationService._internal();

  /// Check if migration has been completed
  static Future<bool> isMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(HiveCacheConfig.hiveMigrationComplete) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark migration as complete
  static Future<void> markMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(HiveCacheConfig.hiveMigrationComplete, true);
      await prefs.setString(
        HiveCacheConfig.hiveMigrationVersion,
        HiveCacheConfig.currentMigrationVersion,
      );
      if (kDebugMode) {
        debugPrint('✅ HiveMigrationService: Migration marked as complete');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveMigrationService: Error marking migration complete - $e');
      }
    }
  }

  /// Migrate all SharedPreferences cache to Hive
  /// Runs in background, doesn't block app startup
  static Future<void> migrateFromSharedPreferences() async {
    // Check if migration already completed
    if (await isMigrationComplete()) {
      if (kDebugMode) {
        debugPrint('⏭️ HiveMigrationService: Migration already completed, skipping');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint(
            '🚀 HiveMigrationService: Starting migration from SharedPreferences to Hive');
      }

      final prefs = await SharedPreferences.getInstance();
      final hiveService = HiveHomeCacheService();
      await hiveService.initialize();

      // Get all module IDs from cache keys
      final allKeys = prefs.getKeys();
      final moduleIds = <int>{};

      // Extract module IDs from cache keys
      // Pattern: comprehensive_{type}_cache_module_{moduleId}
      for (final key in allKeys) {
        if (key.contains('_cache_module_')) {
          final parts = key.split('_cache_module_');
          if (parts.length == 2) {
            final moduleIdStr = parts[1];
            final moduleId = int.tryParse(moduleIdStr);
            if (moduleId != null) {
              moduleIds.add(moduleId);
            }
          }
        }
      }

      if (kDebugMode) {
        debugPrint(
            '📦 HiveMigrationService: Found ${moduleIds.length} modules to migrate: $moduleIds');
      }

      int successCount = 0;
      int failureCount = 0;

      // Migrate each module
      for (final moduleId in moduleIds) {
        try {
          await _migrateModule(prefs, hiveService, moduleId);
          successCount++;
        } catch (e) {
          failureCount++;
          if (kDebugMode) {
            debugPrint(
                '❌ HiveMigrationService: Failed to migrate module $moduleId - $e');
          }
        }
      }

      // Mark migration as complete if at least one module migrated successfully
      if (successCount > 0) {
        await markMigrationComplete();
        if (kDebugMode) {
          debugPrint(
            '✅ HiveMigrationService: Migration completed - $successCount modules migrated, $failureCount failures',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ HiveMigrationService: Migration failed - no modules migrated successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HiveMigrationService: Migration error - $e');
      }
      // Don't mark as complete if migration failed
      // Will retry on next app launch
    }
  }

  /// Migrate a single module's cache data
  static Future<void> _migrateModule(
    SharedPreferences prefs,
    HiveHomeCacheService hiveService,
    int moduleId,
  ) async {
    // Migrate banners
    await _migrateBanners(prefs, hiveService, moduleId);

    // Migrate categories
    await _migrateCategories(prefs, hiveService, moduleId);

    // Migrate stores
    await _migrateStores(prefs, hiveService, moduleId);

    // Migrate brands
    await _migrateBrands(prefs, hiveService, moduleId);

    // Migrate offers
    await _migrateOffers(prefs, hiveService, moduleId);

    // Migrate business settings
    await _migrateBusinessSettings(prefs, hiveService, moduleId);

    if (kDebugMode) {
      debugPrint('✅ HiveMigrationService: Module $moduleId migrated successfully');
    }
  }

  /// Migrate banner data
  static Future<void> _migrateBanners(
    SharedPreferences prefs,
    HiveHomeCacheService hiveService,
    int moduleId,
  ) async {
    try {
      final key = 'comprehensive_banner_cache_module_$moduleId';
      final cachedData = prefs.getString(key);
      if (cachedData != null && cachedData != 'cached') {
        // Extract banner model from cached data structure
        // The cached data has bannerImageList, bannerDataList, etc.
        // We need to reconstruct BannerModel if possible, or skip if structure is different
        // For now, we'll skip banners migration as it has a complex structure
        // They'll be cached fresh from API on next load
        if (kDebugMode) {
          debugPrint(
              '⏭️ HiveMigrationService: Skipping banners migration (complex structure)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveMigrationService: Error migrating banners - $e');
      }
    }
  }

  /// Migrate category data
  static Future<void> _migrateCategories(
    SharedPreferences prefs,
    HiveHomeCacheService hiveService,
    int moduleId,
  ) async {
    try {
      final key = 'comprehensive_category_cache_module_$moduleId';
      final cachedData = prefs.getString(key);
      if (cachedData != null && cachedData != 'cached') {
        final categoryData = jsonDecode(cachedData) as Map<String, dynamic>;
        if (categoryData['categoryList'] != null) {
          final categoryList = (categoryData['categoryList'] as List)
              .map((json) =>
                  CategoryModel.fromJson(json as Map<String, dynamic>))
              .toList();
          await hiveService.saveCategories(moduleId, categoryList);
          if (kDebugMode) {
            debugPrint(
              '✅ HiveMigrationService: Migrated ${categoryList.length} categories for module $moduleId',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveMigrationService: Error migrating categories - $e');
      }
    }
  }

  /// Migrate store data
  static Future<void> _migrateStores(
    SharedPreferences prefs,
    HiveHomeCacheService hiveService,
    int moduleId,
  ) async {
    try {
      final key = 'comprehensive_store_cache_module_$moduleId';
      final cachedData = prefs.getString(key);
      if (cachedData != null && cachedData != 'cached') {
        final storeData = jsonDecode(cachedData) as Map<String, dynamic>;
        if (storeData['storeModel'] != null) {
          final storeModel = StoreModel.fromJson(
              storeData['storeModel'] as Map<String, dynamic>);
          await hiveService.saveStores(moduleId, storeModel);
          if (kDebugMode) {
            debugPrint(
                '✅ HiveMigrationService: Migrated stores for module $moduleId');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveMigrationService: Error migrating stores - $e');
      }
    }
  }

  /// Migrate brand data
  static Future<void> _migrateBrands(
    SharedPreferences prefs,
    HiveHomeCacheService hiveService,
    int moduleId,
  ) async {
    try {
      final key = 'comprehensive_brand_cache_module_$moduleId';
      final cachedData = prefs.getString(key);
      if (cachedData != null && cachedData != 'cached') {
        final brandData = jsonDecode(cachedData) as Map<String, dynamic>;
        if (brandData['brandList'] != null) {
          final brandList = (brandData['brandList'] as List)
              .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
              .toList();
          await hiveService.saveBrands(moduleId, brandList);
          if (kDebugMode) {
            debugPrint(
              '✅ HiveMigrationService: Migrated ${brandList.length} brands for module $moduleId',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveMigrationService: Error migrating brands - $e');
      }
    }
  }

  /// Migrate offers data
  static Future<void> _migrateOffers(
    SharedPreferences prefs,
    HiveHomeCacheService hiveService,
    int moduleId,
  ) async {
    try {
      final key = 'comprehensive_offers_cache_module_$moduleId';
      final cachedData = prefs.getString(key);
      if (cachedData != null && cachedData != 'cached') {
        final offersData = jsonDecode(cachedData) as Map<String, dynamic>;
        if (offersData['data'] != null) {
          final offersList = (offersData['data'] as List)
              .map((json) => Datum.fromJson(json as Map<String, dynamic>))
              .toList();
          final offersModel = OffersModel(
            success: offersData['success'] as bool? ?? false,
            data: offersList,
            message: offersData['message'] as String? ?? '',
          );

          await hiveService.saveOffers(moduleId, offersModel);
          if (kDebugMode) {
            debugPrint(
                '✅ HiveMigrationService: Migrated offers for module $moduleId');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HiveMigrationService: Error migrating offers - $e');
      }
    }
  }

  /// Migrate business settings data
  static Future<void> _migrateBusinessSettings(
    SharedPreferences prefs,
    HiveHomeCacheService hiveService,
    int moduleId,
  ) async {
    try {
      final key = 'comprehensive_business_settings_cache_module_$moduleId';
      final cachedData = prefs.getString(key);
      if (cachedData != null && cachedData != 'cached') {
        final businessData = jsonDecode(cachedData) as Map<String, dynamic>;
        if (businessData['businessSettings'] != null) {
          final businessSettings = BusinessSettingsModel.fromJson(
            businessData['businessSettings'] as Map<String, dynamic>,
          );
          await hiveService.saveBusinessSettings(moduleId, businessSettings);
          if (kDebugMode) {
            debugPrint(
                '✅ HiveMigrationService: Migrated business settings for module $moduleId');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ HiveMigrationService: Error migrating business settings - $e');
      }
    }
  }
}
