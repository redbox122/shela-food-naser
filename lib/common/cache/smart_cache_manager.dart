import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

/// Smart Cache Manager for Home Screen Data
/// Handles version-based cache invalidation and local storage
class SmartCacheManager {
  static const String _cacheVersionKey = 'home_cache_version';
  static const String _bootstrapVersionKey = 'bootstrap_version';
  static const String _appVersionKey = 'app_version';
  static const String _cacheDataKey = 'home_cache_data';
  static const String _cacheTimestampKey = 'home_cache_timestamp';

  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Check if cache is valid and up-to-date
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final splashController = Get.find<SplashController>();

      // Check if cache exists
      if (!prefs.containsKey(_cacheDataKey)) {
        debugPrint('🔄 Cache: No cached data found');
        return false;
      }

      // Check cache timestamp
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = Duration(milliseconds: now - cacheTimestamp);

      if (cacheAge > _cacheExpiry) {
        debugPrint('🔄 Cache: Expired (${cacheAge.inHours}h old)');
        return false;
      }

      // Check app version (using minimum version as proxy)
      final cachedAppVersion = prefs.getString(_appVersionKey);
      final currentAppVersion =
          splashController.configModel?.appMinimumVersionAndroid?.toString() ??
              '1.0.0';

      if (cachedAppVersion != currentAppVersion) {
        debugPrint(
            '🔄 Cache: App version changed ($cachedAppVersion -> $currentAppVersion)');
        return false;
      }

      // Check bootstrap version (using module config as proxy)
      final cachedBootstrapVersion = prefs.getString(_bootstrapVersionKey);
      final currentBootstrapVersion =
          splashController.module?.id?.toString() ?? '1.0.0';

      if (cachedBootstrapVersion != currentBootstrapVersion) {
        debugPrint(
            '🔄 Cache: Bootstrap version changed ($cachedBootstrapVersion -> $currentBootstrapVersion)');
        return false;
      }

      debugPrint(
          '✅ Cache: Valid and up-to-date - USER WILL SEE INSTANT LOADING!');
      return true;
    } catch (e) {
      debugPrint('❌ Cache: Error checking validity - $e');
      return false;
    }
  }

  /// Save data to local cache
  static Future<void> saveCacheData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final splashController = Get.find<SplashController>();

      // Save cache data
      await prefs.setString(_cacheDataKey, jsonEncode(data));

      // Save metadata
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(
          _appVersionKey,
          splashController.configModel?.appMinimumVersionAndroid?.toString() ??
              '1.0.0');
      await prefs.setString(_bootstrapVersionKey,
          splashController.module?.id?.toString() ?? '1.0.0');
      await prefs.setString(_cacheVersionKey, '1.0.0');

      debugPrint(
          '💾 Cache: Data saved successfully - NEXT APP OPEN WILL BE INSTANT!');
    } catch (e) {
      debugPrint('❌ Cache: Error saving data - $e');
    }
  }

  /// Load data from local cache
  static Future<Map<String, dynamic>?> loadCacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(_cacheDataKey)) {
        debugPrint('🔄 Cache: No cached data available');
        return null;
      }

      final cacheData = prefs.getString(_cacheDataKey);
      if (cacheData == null) {
        debugPrint('🔄 Cache: Cache data is null');
        return null;
      }

      final data = jsonDecode(cacheData) as Map<String, dynamic>;
      debugPrint('📦 Cache: Data loaded successfully');
      return data;
    } catch (e) {
      debugPrint('❌ Cache: Error loading data - $e');
      return null;
    }
  }

  /// Clear all cache data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_cacheDataKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_appVersionKey);
      await prefs.remove(_bootstrapVersionKey);
      await prefs.remove(_cacheVersionKey);

      debugPrint('🗑️ Cache: Cleared successfully');
    } catch (e) {
      debugPrint('❌ Cache: Error clearing cache - $e');
    }
  }

  /// Get cache info for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final splashController = Get.find<SplashController>();

      final cacheTimestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;

      return {
        'hasCache': prefs.containsKey(_cacheDataKey),
        'cacheAge': Duration(milliseconds: cacheAge).inHours,
        'cachedAppVersion': prefs.getString(_appVersionKey),
        'currentAppVersion': splashController
                .configModel?.appMinimumVersionAndroid
                ?.toString() ??
            '1.0.0',
        'cachedBootstrapVersion': prefs.getString(_bootstrapVersionKey),
        'currentBootstrapVersion':
            splashController.module?.id?.toString() ?? '1.0.0',
        'isValid': await isCacheValid(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
