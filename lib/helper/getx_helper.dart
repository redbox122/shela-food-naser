/// Helper for safe GetX controller access
/// 
/// This helper provides safe methods to access controllers with null checks
/// to prevent runtime errors when controllers are not registered.
library;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class GetXHelper {
  /// Safely find a controller, returns null if not registered
  /// 
  /// Usage:
  /// ```dart
  /// final controller = GetXHelper.findIfRegistered<StoreController>();
  /// if (controller != null) {
  ///   // Use controller safely
  /// }
  /// ```
  static T? findIfRegistered<T>() {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
      if (kDebugMode) {
        debugPrint('⚠️ GetXHelper: Controller ${T.toString()} is not registered');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ GetXHelper: Error finding controller ${T.toString()}: $e');
      }
      return null;
    }
  }
  
  /// Safely find a controller, throws descriptive error if not registered
  /// 
  /// Usage:
  /// ```dart
  /// try {
  ///   final controller = GetXHelper.findOrThrow<StoreController>();
  ///   // Use controller
  /// } catch (e) {
  ///   // Handle error
  /// }
  /// ```
  static T findOrThrow<T>({String? errorMessage}) {
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    }
    final message = errorMessage ?? 'Controller ${T.toString()} is not registered';
    throw Exception(message);
  }
  
  /// Check if controller is registered before accessing
  /// 
  /// Usage:
  /// ```dart
  /// if (GetXHelper.isRegistered<StoreController>()) {
  ///   final controller = Get.find<StoreController>();
  /// }
  /// ```
  static bool isRegistered<T>() => Get.isRegistered<T>();
  
  /// Safely update a controller if it's registered
  /// 
  /// Usage:
  /// ```dart
  /// GetXHelper.updateIfRegistered<StoreController>();
  /// ```
  static void updateIfRegistered<T>() {
    final controller = findIfRegistered<T>();
    if (controller is GetxController) {
      controller.update();
    }
  }
}



