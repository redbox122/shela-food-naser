// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/cache/splash_cache_manager.dart';
import 'package:sixam_mart/common/cache/loading_state_manager.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';

/// ⚡ PERF: Top-level function for compute() isolate.
/// Decodes all splash cache JSON strings in a single isolate call,
/// avoiding ~170 frame skips from main thread JSON parsing.
Map<String, dynamic> _decodeSplashCacheInIsolate(
    Map<String, String?> rawStrings) {
  final result = <String, dynamic>{};

  final configStr = rawStrings['config'];
  if (configStr != null && configStr.isNotEmpty) {
    result['configData'] = jsonDecode(configStr) as Map<String, dynamic>;
  }

  final moduleStr = rawStrings['module'];
  if (moduleStr != null && moduleStr.isNotEmpty) {
    result['moduleData'] = jsonDecode(moduleStr) as Map<String, dynamic>;
  }

  final moduleListStr = rawStrings['moduleList'];
  if (moduleListStr != null && moduleListStr.isNotEmpty) {
    result['moduleListData'] = jsonDecode(moduleListStr) as List<dynamic>;
  }

  return result;
}

/// Cached Splash Data Loader
/// Provides instant app startup with smart caching
///
/// 🔧 CRITICAL FIX: Uses Completer pattern instead of polling loop
/// This eliminates the 600+ frame skips caused by the old 50-retry busy-wait
class CachedSplashLoader {
  // 🔧 FIX: Completer to await config data without blocking main thread
  static Completer<bool>? _configCompleter;

  /// Load splash data with smart caching
  static Future<void> loadSplashData(
    BuildContext context, {
    NotificationBodyModel? notificationBody,
    bool loadModuleData = false,
    bool loadLandingData = false,
    bool forceRefresh = false,
    bool allowBackgroundRefresh = false,
  }) async {
    final loadingManager = LoadingStateManager();

    // Check if we can start splash loading
    if (!loadingManager.startSplashLoading()) {
      print(
          '🚫 CachedSplashLoader: Cannot start - splash loading already in progress');
      return;
    }

    try {
      print(
          '🚀 CachedSplashLoader: Starting splash data load (forceRefresh: $forceRefresh)');

      // Check if we should use cache
      final useCache =
          !forceRefresh && await SplashCacheManager.isSplashCacheValid();
      if (!context.mounted) {
        return;
      }

      if (useCache) {
        print('📦 CachedSplashLoader: Loading from cache - INSTANT STARTUP!');
        await _loadFromCache(context, loadModuleData, loadLandingData);

        // Refresh in background only if not already refreshing
        if (!loadingManager.isBackgroundRefreshing) {
          print('🔄 CachedSplashLoader: Refreshing in background');
          if (!context.mounted) {
            return;
          }
          if (allowBackgroundRefresh) {
            _refreshInBackground(
                context, notificationBody, loadModuleData, loadLandingData);
          }
        } else {
          print(
              '🚫 CachedSplashLoader: Background refresh already in progress, skipping');
        }
      } else {
        print(
            '🌐 CachedSplashLoader: Loading from API - FIRST TIME OR CACHE INVALID');
        if (!context.mounted) {
          return;
        }
        await _loadFromAPI(
            context, notificationBody, loadModuleData, loadLandingData);
      }
    } catch (e) {
      print('❌ CachedSplashLoader: Error - $e');
      // Fallback to API loading
      if (!context.mounted) {
        return;
      }
      await _loadFromAPI(
          context, notificationBody, loadModuleData, loadLandingData);
    } finally {
      loadingManager.completeSplashLoading();
    }
  }

  /// Load data from cache
  /// ⚡ PERF: Reads raw strings from SharedPreferences, then decodes ALL JSON
  /// in a single compute() isolate to prevent main thread blocking (~170 frames).
  static Future<void> _loadFromCache(
    BuildContext context,
    bool loadModuleData,
    bool loadLandingData,
  ) async {
    final splashController = Get.find<SplashController>();
    try {
      // Step 1: Read raw strings (fast - SharedPreferences is already cached in memory)
      final configStr = await SplashCacheManager.loadConfigDataRaw();

      if (configStr == null || configStr.isEmpty) {
        print(
            'CachedSplashLoader: No cached config data available, falling back to API');
        throw Exception('Cache config data is null or empty');
      }

      String? moduleStr;
      String? moduleListStr;

      if (loadModuleData) {
        moduleStr = await SplashCacheManager.loadModuleDataRaw();
        moduleListStr = await SplashCacheManager.loadModuleListDataRaw();
      }

      // Step 2: Decode ALL JSON in a single isolate (heavy CPU work off main thread)
      final parsed = await compute(_decodeSplashCacheInIsolate, {
        'config': configStr,
        'module': moduleStr,
        'moduleList': moduleListStr,
      });

      final configData = parsed['configData'] as Map<String, dynamic>?;
      if (configData == null || configData.isEmpty) {
        throw Exception('Config data decoded to null/empty');
      }

      // Step 3: Restore to controller (model parsing + state assignment)
      await splashController.restoreFromCache(
        configData: configData,
        moduleData: parsed['moduleData'] as Map<String, dynamic>?,
        moduleListData: parsed['moduleListData'] as List<dynamic>?,
      );

      // 🔧 FIX: Verify data was actually populated after restore
      if (splashController.configModel == null) {
        print(
            'CachedSplashLoader: configModel is null after cache restore - falling back to API');
        throw Exception('configModel null after cache restore');
      }

      print(
          'CachedSplashLoader: Splash data restored from cache - instant startup ready');
    } catch (e) {
      print('CachedSplashLoader: Error loading from cache - $e');
      // 🔧 FIX: Rethrow so the caller triggers API fallback
      rethrow;
    }
  }

  /// Load data from API
  ///
  /// 🔧 CRITICAL FIX: Uses Completer pattern to avoid blocking main thread
  /// The old 50-retry polling loop was causing 600+ frame skips
  static Future<void> _loadFromAPI(
    BuildContext context,
    NotificationBodyModel? notificationBody,
    bool loadModuleData,
    bool loadLandingData,
  ) async {
    try {
      final splashController = Get.find<SplashController>();

      // 🔧 FIX: Initialize Completer for non-blocking config await
      _configCompleter = Completer<bool>();

      if (kDebugMode) {
        print(
            '🚀 CachedSplashLoader: Starting API load (non-blocking Completer pattern)');
      }

      // Load config data without routing immediately
      // This is async and will complete the Completer when done
      splashController
          .getConfigData(
        context,
        notificationBody: notificationBody,
        loadModuleData: loadModuleData,
        loadLandingData: loadLandingData,
        source: DataSourceEnum.client,
        shouldRoute: false, // Don't route immediately during splash loading
      )
          .then((_) {
        // ⚡ PERF FIX: Complete immediately instead of polling.
        // getConfigData sets configModel synchronously before returning,
        // so there is no gap to poll over. The old 50×100ms loop was
        // burning ~600 frames on the main thread for no reason.
        if (_configCompleter != null && !_configCompleter!.isCompleted) {
          final hasConfig = splashController.configModel != null;
          if (kDebugMode) {
            print(
                '✅ CachedSplashLoader: getConfigData completed, configModel=${hasConfig ? "✓" : "✗"}');
          }
          _configCompleter!.complete(hasConfig);
        }
      }).catchError((Object error) {
        // 🔧 FIX: Complete with error to prevent hanging
        if (_configCompleter != null && !_configCompleter!.isCompleted) {
          if (kDebugMode) {
            print('❌ CachedSplashLoader: getConfigData failed: $error');
          }
          _configCompleter!.complete(false);
        }
      });

      // 🔧 FIX: Non-blocking await with timeout
      // This doesn't block the main thread like the old polling loop
      final success = await _configCompleter!.future.timeout(
        const Duration(
            seconds: 4), // ⚡ PERF: 4s cap keeps splash under 6s worst-case
        onTimeout: () {
          if (kDebugMode) {
            print(
                '⚠️ CachedSplashLoader: Config load timed out after 4s - routing with cached/default data');
          }
          return splashController.configModel != null;
        },
      );

      if (!success && splashController.configModel == null) {
        if (kDebugMode) {
          print('❌ CachedSplashLoader: ConfigModel is null after await');
          print('   - This may indicate 304 response with missing Hive cache');
          print(
              '   - App will continue with null config (may show error screen)');
        }
        // Don't throw - let the app continue and show appropriate error UI
        // This prevents infinite loops and allows graceful degradation
      } else {
        if (kDebugMode) {
          print('✅ CachedSplashLoader: ConfigModel verified loaded');
        }
      }

      // Save to cache
      await _saveDataToCache();

      if (kDebugMode) {
        print('✅ CachedSplashLoader: Splash data loaded from API and cached');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CachedSplashLoader: Error loading from API - $e');
      }
      // 🔧 FIX: Don't rethrow - allow graceful degradation
      // The app should continue and show appropriate error UI
    } finally {
      _configCompleter = null; // Clean up
    }
  }

  /// Refresh data in background
  static void _refreshInBackground(
    BuildContext context,
    NotificationBodyModel? notificationBody,
    bool loadModuleData,
    bool loadLandingData,
  ) {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final splashController = Get.find<SplashController>();
        if (!context.mounted) {
          return;
        }
        await splashController.getConfigData(
          context,
          notificationBody: notificationBody,
          loadModuleData: loadModuleData,
          loadLandingData: loadLandingData,
          shouldRoute: false, // Don't route during background refresh
        );
        await _saveDataToCache();
        print('🔄 CachedSplashLoader: Background refresh completed');
      } catch (e) {
        print('❌ CachedSplashLoader: Background refresh failed - $e');
      }
    });
  }

  /// Save current data to cache
  static Future<void> _saveDataToCache() async {
    try {
      final splashController = Get.find<SplashController>();

      // Save config data
      final rawConfig = splashController.rawConfigData;
      if (rawConfig != null && rawConfig.isNotEmpty) {
        await SplashCacheManager.saveConfigData(rawConfig);
      } else if (splashController.configModel != null) {
        await SplashCacheManager.saveConfigData(
            splashController.configModel!.toJson());
      }

      // Save module data
      if (splashController.module != null) {
        await SplashCacheManager.saveModuleData(
            splashController.module!.toJson());
      }

      // Save module list data
      if (splashController.moduleList != null) {
        final moduleListData =
            splashController.moduleList!.map((m) => m.toJson()).toList();
        await SplashCacheManager.saveModuleListData(moduleListData);
      }
    } catch (e) {
      print('CachedSplashLoader: Error saving to cache - $e');
    }
  }

  /// Clear cache and force refresh
  static Future<void> clearCacheAndRefresh(
    BuildContext context, {
    NotificationBodyModel? notificationBody,
    bool loadModuleData = false,
    bool loadLandingData = false,
  }) async {
    print('🗑️ CachedSplashLoader: Clearing cache and refreshing');
    await SplashCacheManager.clearSplashCache();
    if (!context.mounted) {
      return;
    }
    await loadSplashData(
      context,
      notificationBody: notificationBody,
      loadModuleData: loadModuleData,
      loadLandingData: loadLandingData,
      forceRefresh: true,
    );
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    return await SplashCacheManager.getCacheStats();
  }
}
