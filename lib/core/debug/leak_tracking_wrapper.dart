import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Memory leak tracking wrapper for GetX controllers
/// 
/// Monitors controller lifecycle in debug mode and alerts when controllers
/// are not properly disposed after screen navigation.
/// 
/// Usage:
/// ```dart
/// runApp(LeakTrackingWrapper(child: MyApp()));
/// ```
class LeakTrackingWrapper extends StatefulWidget {
  final Widget child;
  
  const LeakTrackingWrapper({
    super.key,
    required this.child,
  });

  @override
  State<LeakTrackingWrapper> createState() => _LeakTrackingWrapperState();
}

class _LeakTrackingWrapperState extends State<LeakTrackingWrapper> {
  // Track registered controllers and their creation context
  final Map<String, _ControllerInfo> _trackedControllers = {};
  String? _currentRoute;
  String? _previousRoute;
  Timer? _routeCheckTimer;
  Timer? _leakCheckTimer;

  @override
  void initState() {
    super.initState();
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      _startTracking();
    }
  }

  void _startTracking() {
    // Initialize current route
    _currentRoute = Get.routing.current;
    
    // Periodic check for route changes (every 500ms in debug)
    // Since Get.routing.stream doesn't exist in this Get version, we poll instead
    _routeCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !kDebugMode) return;
      
      final newRoute = Get.routing.current;
      if (newRoute != _currentRoute) {
        _previousRoute = _currentRoute;
        _currentRoute = newRoute;
        
        if (AppConstants.enableVerboseLogs) {
          debugPrint('🔍 LeakTracker: Route changed from $_previousRoute to $_currentRoute');
        }
        
        // Check for leaks 3 seconds after route change
        // This gives controllers time to be disposed
        if (_previousRoute != null) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && kDebugMode) {
              _checkForLeaks();
            }
          });
        }
      }
    });
    
    // Periodic check for leaked controllers (every 15 seconds in debug)
    // This catches controllers that weren't disposed after navigation
    _leakCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && kDebugMode) {
        _checkForLeaks();
      }
    });
    
    if (AppConstants.enableVerboseLogs) {
      debugPrint('🔍 LeakTracker: Memory leak tracking enabled (Debug Mode Only)');
      debugPrint('💡 Tip: Use LeakTrackingMixin on controllers for better tracking');
    }
  }

  void _checkForLeaks() {
    if (!kDebugMode || !mounted) return;
    
    final now = DateTime.now();
    final leakedControllers = <String>[];
    
    // Check all tracked controllers
    _trackedControllers.removeWhere((key, info) {
      // Check if controller is still registered
      try {
        // We can't directly check if a controller by key is registered
        // So we check based on age and route changes
        final age = now.difference(info.registeredAt);
        final routeChanged = _previousRoute != null && 
                            _currentRoute != _previousRoute &&
                            info.route == _previousRoute;
        
        // If route changed and controller is older than 5 seconds, it might be leaked
        if (routeChanged && age.inSeconds > 5) {
          leakedControllers.add(key);
          return false; // Remove from tracking (it's leaked)
        }
        
        // Keep tracking if it's a recent controller or route hasn't changed
        return age.inSeconds < 30; // Keep tracking for 30 seconds max
      } catch (e) {
        return true; // Remove if there's an error
      }
    });
    
    if (leakedControllers.isNotEmpty && AppConstants.enableVerboseLogs) {
      debugPrint('\n${'=' * 80}');
      debugPrint('🔴 MEMORY LEAK DETECTED - Controllers may not be disposed!');
      debugPrint('=' * 80);
      debugPrint('Previous Route: $_previousRoute');
      debugPrint('Current Route: $_currentRoute');
      debugPrint('\n⚠️  SUSPECTED LEAKED CONTROLLERS:');
      for (final key in leakedControllers) {
        if (_trackedControllers.containsKey(key)) {
          final info = _trackedControllers[key]!;
          final age = now.difference(info.registeredAt);
          debugPrint('  • $key');
          debugPrint('    Registered: ${info.registeredAt}');
          debugPrint('    Age: ${age.inSeconds}s');
          debugPrint('    Route: ${info.route}');
          debugPrint('');
        }
      }
      debugPrint('💡 TIP: Ensure controllers are disposed in onClose() method');
      debugPrint('💡 TIP: Use Get.delete() for temporary controllers');
      debugPrint('💡 TIP: Check bindings to ensure proper cleanup');
      debugPrint('=' * 80 + '\n');
    }
  }

  /// Track a controller registration
  void trackController(String controllerType, String route) {
    if (!kDebugMode || !AppConstants.enableVerboseLogs) return;
    
    final key = '${controllerType}_${DateTime.now().millisecondsSinceEpoch}';
    _trackedControllers[key] = _ControllerInfo(
      registeredAt: DateTime.now(),
      route: route,
      controllerType: controllerType,
    );
    
    debugPrint('🔵 Controller Tracked: $controllerType at route: $route');
  }

  /// Mark a controller as disposed
  void untrackController(String controllerType) {
    if (!kDebugMode || !AppConstants.enableVerboseLogs) return;
    
    _trackedControllers.removeWhere((key, info) {
      if (info.controllerType == controllerType) {
        final age = DateTime.now().difference(info.registeredAt);
        debugPrint('🟢 Controller Disposed: $controllerType (Age: ${age.inSeconds}s)');
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _routeCheckTimer?.cancel();
    _leakCheckTimer?.cancel();
    
    if (kDebugMode && AppConstants.enableVerboseLogs && _trackedControllers.isNotEmpty) {
      debugPrint('\n⚠️  LeakTrackingWrapper disposed with ${_trackedControllers.length} tracked controllers');
    }
    super.dispose();
  }
}

class _ControllerInfo {
  final DateTime registeredAt;
  final String route;
  final String controllerType;

  _ControllerInfo({
    required this.registeredAt,
    required this.route,
    required this.controllerType,
  });
}

/// Enhanced GetX controller mixin for leak detection
/// 
/// This mixin can be added to controllers to enable automatic leak tracking
mixin LeakTrackingMixin on GetxController {
  String? _leakTrackingId;
  DateTime? _leakTrackingRegisteredAt;
  String? _leakTrackingRoute;

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      _leakTrackingId = runtimeType.toString();
      _leakTrackingRegisteredAt = DateTime.now();
      _leakTrackingRoute = Get.routing.current;
      debugPrint('🔵 Controller onInit: $_leakTrackingId at route: $_leakTrackingRoute');
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (kDebugMode && _leakTrackingId != null) {
      debugPrint('✅ Controller onReady: $_leakTrackingId');
    }
  }

  @override
  void onClose() {
    if (kDebugMode && _leakTrackingId != null && _leakTrackingRegisteredAt != null) {
      final age = DateTime.now().difference(_leakTrackingRegisteredAt!);
      debugPrint('🟢 Controller onClose: $_leakTrackingId (Age: ${age.inSeconds}s)');
      _leakTrackingId = null;
      _leakTrackingRegisteredAt = null;
    }
    super.onClose();
  }
}

