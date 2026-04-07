
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';

/// Instant Loading Manager
/// Prevents unnecessary API calls when data is already loaded
class InstantLoadingManager {
  static const String _dataLoadedKey = 'home_data_loaded';
  static const String _lastLoadTimeKey = 'last_load_time';

  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Check if home data is already loaded and valid
  static Future<bool> isDataLoaded() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if data loaded flag exists
      if (!prefs.containsKey(_dataLoadedKey)) {
        debugPrint('🔄 InstantLoadingManager: Data not marked as loaded');
        return false;
      }

      // Check if data is expired
      final lastLoadTime = prefs.getInt(_lastLoadTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = Duration(milliseconds: now - lastLoadTime);

      if (age > _cacheExpiry) {
        debugPrint('🔄 InstantLoadingManager: Data expired (${age.inHours}h old)');
        await forceRefresh();
        return false;
      }

      // Check if comprehensive cache is valid
      final comprehensiveCacheValid =
          await ComprehensiveHomeCacheManager.isCacheValid();
      if (!comprehensiveCacheValid) {
        debugPrint('🔄 InstantLoadingManager: Comprehensive cache invalid');
        await forceRefresh();
        return false;
      }

      debugPrint(
          '✅ InstantLoadingManager: Data is loaded and valid - INSTANT LOADING!');
      return true;
    } catch (e) {
      debugPrint('❌ InstantLoadingManager: Error checking data - $e');
      return false;
    }
  }

  /// Mark data as loaded
  static Future<void> markDataLoaded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dataLoadedKey, true);
      await prefs.setInt(
          _lastLoadTimeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('✅ InstantLoadingManager: Data marked as loaded');
    } catch (e) {
      debugPrint('❌ InstantLoadingManager: Error marking data loaded - $e');
    }
  }

  /// Clear loaded data flag
  static Future<void> clearDataLoaded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dataLoadedKey);
      await prefs.remove(_lastLoadTimeKey);
      debugPrint('🗑️ InstantLoadingManager: Data loaded flag cleared');
    } catch (e) {
      debugPrint('❌ InstantLoadingManager: Error clearing data flag - $e');
    }
  }

  /// Force refresh (clear flag and reload)
  static Future<void> forceRefresh() async {
    await clearDataLoaded();
    debugPrint('🔄 InstantLoadingManager: Force refresh - will reload all data');
  }

  /// Load data from cache to controllers
  static Future<void> loadDataFromCache(BuildContext context) async {
    try {
      debugPrint(
          '📦 InstantLoadingManager: Loading data from cache to controllers...');

      // Instead of using ComprehensiveHomeLoader (which gets blocked),
      // directly trigger the normal loading process which will load from cache
      // since forceRefresh is false
      await HomeScreen.loadData(context, false);

      debugPrint('✅ InstantLoadingManager: Data loaded from cache to controllers!');
    } catch (e) {
      debugPrint('❌ InstantLoadingManager: Error loading data from cache - $e');
    }
  }
}
