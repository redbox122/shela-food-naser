import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/core/isolate/json_isolate_helper.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

/// Splash Cache Manager for Instant App Startup
/// Handles configuration, modules, and essential data caching
class SplashCacheManager {
  static const String _configCacheKey = 'splash_config_cache';
  static const String _moduleCacheKey = 'splash_module_cache';
  static const String _moduleListCacheKey = 'splash_module_list_cache';
  static const String _configTimestampKey = 'splash_config_timestamp';
  static const String _moduleTimestampKey = 'splash_module_timestamp';
  static const String _splashVersionKey = 'splash_cache_version';

  static const Duration _configCacheExpiry = Duration(hours: 6);
  static const Duration _moduleCacheExpiry = Duration(hours: 12);

  /// ⚡ PERF: Read raw cache strings without JSON decoding (for isolate batching)
  static Future<String?> loadConfigDataRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_configCacheKey);
    } catch (e) {
      debugPrint('❌ Splash Cache: Error loading raw config data - $e');
      return null;
    }
  }

  /// ⚡ PERF: Read raw module string without JSON decoding
  static Future<String?> loadModuleDataRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_moduleCacheKey)) return null;
      return prefs.getString(_moduleCacheKey);
    } catch (e) {
      debugPrint('❌ Module Cache: Error loading raw data - $e');
      return null;
    }
  }

  /// ⚡ PERF: Read raw module list string without JSON decoding
  static Future<String?> loadModuleListDataRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_moduleListCacheKey)) return null;
      return prefs.getString(_moduleListCacheKey);
    } catch (e) {
      debugPrint('❌ Module List Cache: Error loading raw data - $e');
      return null;
    }
  }

  /// Check if splash cache is valid
  static Future<bool> isSplashCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final splashController = Get.find<SplashController>();

      // Check if config cache exists
      if (!prefs.containsKey(_configCacheKey)) {
        debugPrint('🔄 Splash Cache: No cached config data found');
        return false;
      }

      // Check config cache timestamp
      final configTimestamp = prefs.getInt(_configTimestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final configAge = Duration(milliseconds: now - configTimestamp);

      if (configAge > _configCacheExpiry) {
        debugPrint(
            '🔄 Splash Cache: Config expired (${configAge.inHours}h old)');
        return false;
      }

      // Check app version
      final cachedAppVersion = prefs.getString(_splashVersionKey);
      final currentAppVersion =
          splashController.configModel?.appMinimumVersionAndroid;

      if (cachedAppVersion == null) {
        debugPrint('???? Splash Cache: Cached version missing');
        return false;
      }

      if (currentAppVersion != null &&
          cachedAppVersion != currentAppVersion.toString()) {
        debugPrint('???? Splash Cache: App version changed');
        return false;
      }

      debugPrint('✅ Splash Cache: Valid - INSTANT APP STARTUP!');
      return true;
    } catch (e) {
      debugPrint('❌ Splash Cache: Error checking validity - $e');
      return false;
    }
  }

  /// Check if module cache is valid
  static Future<bool> isModuleCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(_moduleCacheKey)) {
        return false;
      }

      final moduleTimestamp = prefs.getInt(_moduleTimestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final moduleAge = Duration(milliseconds: now - moduleTimestamp);

      return moduleAge <= _moduleCacheExpiry;
    } catch (e) {
      debugPrint('❌ Module Cache: Error checking validity - $e');
      return false;
    }
  }

  /// Save config data to cache
  static Future<void> saveConfigData(Map<String, dynamic> configData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final splashController = Get.find<SplashController>();

      // Save config data
      await prefs.setString(_configCacheKey, jsonEncode(configData));
      await prefs.setInt(
          _configTimestampKey, DateTime.now().millisecondsSinceEpoch);
      final cachedVersion = configData['app_minimum_version_android']
              ?.toString() ??
          splashController.configModel?.appMinimumVersionAndroid?.toString();
      await prefs.setString(_splashVersionKey, cachedVersion ?? '1.0.0');

      debugPrint(
          '💾 Splash Cache: Config data saved - INSTANT STARTUP NEXT TIME!');
    } catch (e) {
      debugPrint('❌ Splash Cache: Error saving config data - $e');
    }
  }

  /// Save module data to cache
  static Future<void> saveModuleData(Map<String, dynamic> moduleData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_moduleCacheKey, jsonEncode(moduleData));
      await prefs.setInt(
          _moduleTimestampKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('💾 Module Cache: Data saved');
    } catch (e) {
      debugPrint('❌ Module Cache: Error saving data - $e');
    }
  }

  /// Save module list to cache
  static Future<void> saveModuleListData(List<dynamic> moduleList) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_moduleListCacheKey, jsonEncode(moduleList));

      debugPrint('💾 Module List Cache: Data saved');
    } catch (e) {
      debugPrint('❌ Module List Cache: Error saving data - $e');
    }
  }

  /// Load config data from cache
  static Future<Map<String, dynamic>?> loadConfigData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(_configCacheKey)) {
        return null;
      }

      final cacheData = prefs.getString(_configCacheKey);
      if (cacheData == null) return null;

      // ⚡ PERF FIX: Use isolate for JSON decoding to avoid blocking main thread
      final data = await JsonIsolateHelper.decodeJson(cacheData);
      debugPrint('📦 Splash Cache: Config data loaded successfully');
      return data;
    } catch (e) {
      debugPrint('❌ Splash Cache: Error loading config data - $e');
      return null;
    }
  }

  /// Load module data from cache
  static Future<Map<String, dynamic>?> loadModuleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(_moduleCacheKey)) {
        return null;
      }

      final cacheData = prefs.getString(_moduleCacheKey);
      if (cacheData == null) return null;

      // ⚡ PERF FIX: Use isolate for JSON decoding to avoid blocking main thread
      final data = await JsonIsolateHelper.decodeJson(cacheData);
      debugPrint('📦 Module Cache: Data loaded successfully');
      return data;
    } catch (e) {
      debugPrint('❌ Module Cache: Error loading data - $e');
      return null;
    }
  }

  /// Load module list from cache
  static Future<List<dynamic>?> loadModuleListData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(_moduleListCacheKey)) {
        return null;
      }

      final cacheData = prefs.getString(_moduleListCacheKey);
      if (cacheData == null) return null;

      // ⚡ PERF FIX: Use isolate for JSON decoding to avoid blocking main thread
      final data = await JsonIsolateHelper.decodeJsonList(cacheData);
      debugPrint('📦 Module List Cache: Data loaded successfully');
      return data;
    } catch (e) {
      debugPrint('❌ Module List Cache: Error loading data - $e');
      return null;
    }
  }

  /// Clear all splash cache
  static Future<void> clearSplashCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_configCacheKey);
      await prefs.remove(_moduleCacheKey);
      await prefs.remove(_moduleListCacheKey);
      await prefs.remove(_configTimestampKey);
      await prefs.remove(_moduleTimestampKey);
      await prefs.remove(_splashVersionKey);

      debugPrint('🗑️ Splash Cache: Cleared successfully');
    } catch (e) {
      debugPrint('❌ Splash Cache: Error clearing cache - $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final configTimestamp = prefs.getInt(_configTimestampKey) ?? 0;
      final moduleTimestamp = prefs.getInt(_moduleTimestampKey) ?? 0;
      final configAge = DateTime.now().millisecondsSinceEpoch - configTimestamp;
      final moduleAge = DateTime.now().millisecondsSinceEpoch - moduleTimestamp;

      return {
        'hasConfigCache': prefs.containsKey(_configCacheKey),
        'hasModuleCache': prefs.containsKey(_moduleCacheKey),
        'hasModuleListCache': prefs.containsKey(_moduleListCacheKey),
        'configCacheAge': Duration(milliseconds: configAge).inHours,
        'moduleCacheAge': Duration(milliseconds: moduleAge).inHours,
        'isConfigValid': await isSplashCacheValid(),
        'isModuleValid': await isModuleCacheValid(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
