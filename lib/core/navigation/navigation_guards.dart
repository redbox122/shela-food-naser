import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// 🛡️ Navigation Guards
/// 
/// Centralized navigation guards to prevent unwanted route changes
/// when user is in specific screens (e.g., AccessLocationScreen)
class NavigationGuards {
  /// Flag to prevent auto-routing when user is in AccessLocationScreen
  /// 
  /// When true, any auto-routing (from SplashRouteHelper, Route Guards, etc.)
  /// should be blocked to prevent interrupting the user's location selection flow.
  static bool isInAccessLocation = false;

  /// Check if auto-routing should be blocked
  /// 
  /// Returns true if routing should be blocked, false otherwise
  static bool shouldBlockAutoRouting() {
    if (isInAccessLocation) {
      if (kDebugMode) {
        debugPrint('🛑 NavigationGuard: Auto-routing blocked - user is in AccessLocationScreen');
      }
      return true;
    }
    return false;
  }

  /// Check if current route is AccessLocationScreen
  /// 
  /// Additional safety check using route name
  static bool isCurrentRouteAccessLocation() {
    final currentRoute = Get.currentRoute;
    return currentRoute.contains('access-location') || 
           currentRoute.contains('set-location');
  }

  /// Combined check: Flag OR route name
  /// 
  /// Returns true if routing should be blocked
  static bool shouldBlockRouting() {
    return shouldBlockAutoRouting() || isCurrentRouteAccessLocation();
  }
}

