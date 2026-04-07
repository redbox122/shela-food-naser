
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

/// Manages preloaded data to ensure instant home screen display
/// This prevents unnecessary API calls when data is already cached
class PreloadedDataManager {
  static final PreloadedDataManager _instance =
      PreloadedDataManager._internal();
  factory PreloadedDataManager() => _instance;
  PreloadedDataManager._internal();

  bool _isDataPreloaded = false;
  bool _isDataValid = false;
  DateTime? _lastPreloadTime;
  String? _lastUserState; // Track user state (guest/logged-in)

  /// Get current user state
  String _getCurrentUserState() {
    final isLoggedIn = AuthHelper.isLoggedIn();
    return isLoggedIn ? 'logged_in' : 'guest';
  }

  /// Check if user state has changed
  bool _hasUserStateChanged() {
    final currentState = _getCurrentUserState();
    if (_lastUserState == null) {
      _lastUserState = currentState;
      return false; // First time, no change
    }
    return _lastUserState != currentState;
  }

  /// Check if home data is preloaded and valid
  Future<bool> isHomeDataPreloaded() async {
    try {
      // User state changes should NEVER affect e-commerce data preloading
      // E-commerce data is completely independent of user authentication
      if (_hasUserStateChanged()) {
        if (kDebugMode) {
          debugPrint(
              '🔄 PreloadedDataManager: User state changed from $_lastUserState to ${_getCurrentUserState()} - e-commerce data remains preloaded');
        }
        // Update user state but NEVER invalidate e-commerce data
        _lastUserState = _getCurrentUserState();
        // E-commerce data persists across all user state changes
      }

      // Check if splash controller says data is preloaded
      if (Get.isRegistered<SplashController>()) {
        final splashController = Get.find<SplashController>();
        if (splashController.homeDataPreLoaded == true) {
          _isDataPreloaded = true;
        }
      }

      // Check if comprehensive cache is valid
      _isDataValid = await ComprehensiveHomeCacheManager.isCacheValid();

      if (_isDataPreloaded && _isDataValid) {
        if (kDebugMode) {
          debugPrint(
              '✅ PreloadedDataManager: Home data is preloaded and valid - INSTANT DISPLAY!');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint(
              '🔄 PreloadedDataManager: Home data not preloaded or invalid - need to load');
          debugPrint('   - Preloaded: $_isDataPreloaded');
          debugPrint('   - Valid: $_isDataValid');
          debugPrint('   - User State: ${_getCurrentUserState()}');
          debugPrint(
              '   - SplashController.homeDataPreLoaded: ${Get.isRegistered<SplashController>() ? Get.find<SplashController>().homeDataPreLoaded : "not registered"}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PreloadedDataManager: Error checking preloaded data - $e');
      }
      return false;
    }
  }

  /// Mark data as preloaded
  void markDataPreloaded() {
    _isDataPreloaded = true;
    _lastPreloadTime = DateTime.now();
    _lastUserState = _getCurrentUserState(); // Track current user state

    if (kDebugMode) {
      debugPrint(
          '✅ PreloadedDataManager: Data marked as preloaded for user state: ${_getCurrentUserState()}');
    }
  }

  /// Mark data as invalid (needs refresh)
  void markDataInvalid() {
    _isDataPreloaded = false;
    _isDataValid = false;

    if (kDebugMode) {
      debugPrint('🔄 PreloadedDataManager: Data marked as invalid');
    }
  }

  /// Force invalidate cache due to user state change
  void invalidateForUserStateChange() {
    markDataInvalid();
    _lastUserState = _getCurrentUserState();

    if (kDebugMode) {
      debugPrint(
          '🔄 PreloadedDataManager: Cache invalidated due to user state change to: ${_getCurrentUserState()}');
    }
  }

  /// Invalidate only user-specific data, keep e-commerce data
  void invalidateUserSpecificDataOnly() {
    // Only invalidate user-specific data, not e-commerce data
    _lastUserState = _getCurrentUserState();

    if (kDebugMode) {
      debugPrint(
          '🔄 PreloadedDataManager: User-specific data invalidated, e-commerce data preserved for user state: ${_getCurrentUserState()}');
    }
  }

  /// Check if we should skip loading (data is already available)
  Future<bool> shouldSkipLoading() async {
    final isPreloaded = await isHomeDataPreloaded();

    if (isPreloaded) {
      if (kDebugMode) {
        debugPrint(
            '🚫 PreloadedDataManager: Skipping loading - data already preloaded and valid');
      }
      return true;
    }

    // Fallback: Check if we have any cached data at all (even if version doesn't match)
    if (_isDataPreloaded) {
      if (kDebugMode) {
        debugPrint(
            '🔄 PreloadedDataManager: Data is preloaded but cache validation failed - using fallback');
      }
      return true; // Use cached data even if version doesn't match
    }

    return false;
  }

  /// Get preload status
  Map<String, dynamic> getPreloadStatus() {
    return {
      'isDataPreloaded': _isDataPreloaded,
      'isDataValid': _isDataValid,
      'lastPreloadTime': _lastPreloadTime?.toIso8601String(),
      'shouldSkipLoading': _isDataPreloaded && _isDataValid,
    };
  }

  /// Reset preload status (useful for testing or app restart)
  void resetPreloadStatus() {
    _isDataPreloaded = false;
    _isDataValid = false;
    _lastPreloadTime = null;
    _lastUserState = null;

    if (kDebugMode) {
      debugPrint('🔄 PreloadedDataManager: Preload status reset');
    }
  }

  /// Get current user state for debugging
  String getCurrentUserState() {
    return _getCurrentUserState();
  }
}
