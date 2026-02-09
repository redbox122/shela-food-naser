import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 🔥 SAFE SNACKBAR WRAPPER: Prevents LateInitializationError from GetX SnackbarController
/// 
/// GetX has a known bug where closing snackbars when none are open causes:
/// `LateInitializationError: Field '_controller' has not been initialized`
/// 
/// This wrapper provides safe methods that check before closing/opening snackbars.
class SnackbarSafe {
  /// Safely close all open snackbars
  /// Returns true if snackbars were closed, false if none were open
  static bool closeAll() {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ SnackbarSafe.closeAll skipped: $e');
      return false;
    }
  }

  /// Safely show a snackbar with error handling
  /// Returns true if snackbar was shown, false if it couldn't be shown
  static bool show({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    Color? colorText,
    IconData? icon,
  }) {
    try {
      // 🔥 BUG FIX: Check if Overlay is available before showing snackbar
      if (Get.overlayContext == null) {
        debugPrint('⚠️ SnackbarSafe.show: Overlay not available, skipping snackbar');
        return false;
      }

      // 🔥 BUG FIX: Close any existing snackbars before showing new one
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }

      Get.snackbar(
        title,
        message,
        snackPosition: position,
        duration: duration,
        backgroundColor: backgroundColor,
        colorText: colorText,
        icon: icon != null ? Icon(icon, color: colorText ?? Colors.white) : null,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ SnackbarSafe.show failed: $e');
      return false;
    }
  }

  /// Safely show a success snackbar (green)
  static bool showSuccess(String message) {
    return show(
      title: 'success'.tr,
      message: message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: Icons.check_circle,
    );
  }

  /// Safely show an error snackbar (red)
  static bool showError(String message) {
    return show(
      title: 'error'.tr,
      message: message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: Icons.error,
    );
  }

  /// Check if snackbar is currently open
  static bool get isOpen => Get.isSnackbarOpen;
}

