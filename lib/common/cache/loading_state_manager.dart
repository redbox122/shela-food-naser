
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Centralized loading state manager to prevent duplicate data loading
/// This ensures only one data loading operation happens at a time
class LoadingStateManager {
  static final LoadingStateManager _instance = LoadingStateManager._internal();
  factory LoadingStateManager() => _instance;
  LoadingStateManager._internal();

  // Track different types of loading operations
  bool _isSplashLoading = false;
  bool _isHomeLoading = false;
  bool _isBackgroundRefreshing = false;
  bool _isComprehensiveLoading = false;

  // Track loading timestamps to prevent rapid successive calls
  DateTime? _lastSplashLoad;
  DateTime? _lastHomeLoad;
  DateTime? _lastBackgroundRefresh;
  DateTime? _lastComprehensiveLoad;

  // Minimum intervals between loads
  static const Duration _minSplashInterval = Duration(seconds: 5);
  static const Duration _minHomeInterval = Duration(seconds: 3);
  static const Duration _minBackgroundInterval = Duration(seconds: 10);
  static const Duration _minComprehensiveInterval = Duration(seconds: 2);

  /// Check if splash data is currently loading
  bool get isSplashLoading => _isSplashLoading;

  /// Check if home data is currently loading
  bool get isHomeLoading => _isHomeLoading;

  /// Check if background refresh is currently running
  bool get isBackgroundRefreshing => _isBackgroundRefreshing;

  /// Check if comprehensive loading is currently running
  bool get isComprehensiveLoading => _isComprehensiveLoading;

  /// Check if any loading operation is in progress
  bool get isAnyLoading =>
      _isSplashLoading ||
      _isHomeLoading ||
      _isBackgroundRefreshing ||
      _isComprehensiveLoading;

  /// Start splash loading
  bool startSplashLoading() {
    if (_isSplashLoading) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Splash loading already in progress, skipping');
      }
      return false;
    }

    if (_lastSplashLoad != null &&
        DateTime.now().difference(_lastSplashLoad!) < _minSplashInterval) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Too soon since last splash load, skipping');
      }
      return false;
    }

    _isSplashLoading = true;
    _lastSplashLoad = DateTime.now();

    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('🚀 Starting splash loading');
    }
    return true;
  }

  /// Complete splash loading
  void completeSplashLoading() {
    _isSplashLoading = false;
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('✅ Splash loading completed');
    }
  }

  /// Start home loading
  bool startHomeLoading({bool force = false}) {
    if (_isHomeLoading) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Home loading already in progress, skipping');
      }
      return false;
    }

    if (!force &&
        _lastHomeLoad != null &&
        DateTime.now().difference(_lastHomeLoad!) < _minHomeInterval) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Too soon since last home load, skipping');
      }
      return false;
    }

    _isHomeLoading = true;
    _lastHomeLoad = DateTime.now();

    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('🚀 Starting home loading${force ? ' (FORCED)' : ''}');
    }
    return true;
  }

  /// Complete home loading
  void completeHomeLoading() {
    _isHomeLoading = false;
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('✅ Home loading completed');
    }
  }

  /// Start background refresh
  bool startBackgroundRefresh() {
    if (_isBackgroundRefreshing) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Background refresh already in progress, skipping');
      }
      return false;
    }

    if (_lastBackgroundRefresh != null &&
        DateTime.now().difference(_lastBackgroundRefresh!) <
            _minBackgroundInterval) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Too soon since last background refresh, skipping');
      }
      return false;
    }

    _isBackgroundRefreshing = true;
    _lastBackgroundRefresh = DateTime.now();

    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('🚀 Starting background refresh');
    }
    return true;
  }

  /// Complete background refresh
  void completeBackgroundRefresh() {
    _isBackgroundRefreshing = false;
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('✅ Background refresh completed');
    }
  }

  /// Start comprehensive loading
  bool startComprehensiveLoading() {
    if (_isComprehensiveLoading) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Comprehensive loading already in progress, skipping');
      }
      return false;
    }

    if (_lastComprehensiveLoad != null &&
        DateTime.now().difference(_lastComprehensiveLoad!) <
            _minComprehensiveInterval) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Too soon since last comprehensive load, skipping');
      }
      return false;
    }

    _isComprehensiveLoading = true;
    _lastComprehensiveLoad = DateTime.now();

    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('🚀 Starting comprehensive loading');
    }
    return true;
  }

  /// Complete comprehensive loading
  void completeComprehensiveLoading() {
    _isComprehensiveLoading = false;
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('✅ Comprehensive loading completed');
    }
  }

  /// Check if comprehensive loading can start (not blocked by other operations)
  bool canStartComprehensiveLoading() {
    // Don't start comprehensive loading if splash is loading
    if (_isSplashLoading) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Cannot start comprehensive loading - splash is loading');
      }
      return false;
    }

    // Don't start if already loading
    if (_isComprehensiveLoading) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Cannot start comprehensive loading - already in progress');
      }
      return false;
    }

    return true;
  }

  /// Check if home loading can start (not blocked by other operations)
  bool canStartHomeLoading() {
    // Don't start home loading if splash is loading
    if (_isSplashLoading) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Cannot start home loading - splash is loading');
      }
      return false;
    }

    // Don't start if already loading
    if (_isHomeLoading) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Cannot start home loading - already in progress');
      }
      return false;
    }

    return true;
  }

  /// Force stop all loading operations
  void forceStopAllLoading() {
    _isSplashLoading = false;
    _isHomeLoading = false;
    _isBackgroundRefreshing = false;
    _isComprehensiveLoading = false;

    if (kDebugMode) {
      debugPrint('🛑 Force stopped all loading operations');
    }
  }

  /// Reset loading state (useful when app restarts or user logs in/out)
  void resetLoadingState() {
    _isSplashLoading = false;
    _isHomeLoading = false;
    _isBackgroundRefreshing = false;
    _isComprehensiveLoading = false;
    _lastSplashLoad = null;
    _lastHomeLoad = null;
    _lastBackgroundRefresh = null;
    _lastComprehensiveLoad = null;

    if (kDebugMode) {
      debugPrint('🔄 Reset all loading states and timestamps');
    }
  }

  /// Get loading status summary
  Map<String, dynamic> getLoadingStatus() {
    return {
      'isSplashLoading': _isSplashLoading,
      'isHomeLoading': _isHomeLoading,
      'isBackgroundRefreshing': _isBackgroundRefreshing,
      'isComprehensiveLoading': _isComprehensiveLoading,
      'isAnyLoading': isAnyLoading,
      'lastSplashLoad': _lastSplashLoad?.toIso8601String(),
      'lastHomeLoad': _lastHomeLoad?.toIso8601String(),
      'lastBackgroundRefresh': _lastBackgroundRefresh?.toIso8601String(),
      'lastComprehensiveLoad': _lastComprehensiveLoad?.toIso8601String(),
    };
  }

  /// Reset all timestamps (useful for testing or app restart)
  void resetTimestamps() {
    _lastSplashLoad = null;
    _lastHomeLoad = null;
    _lastBackgroundRefresh = null;
    _lastComprehensiveLoad = null;

    if (kDebugMode) {
      debugPrint('🔄 Reset all loading timestamps');
    }
  }
}
