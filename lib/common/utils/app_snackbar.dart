import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';

/// 🔥 PRODUCTION-SAFE SNACKBAR: Uses ScaffoldMessenger instead of GetX Snackbar
/// 
/// Why ScaffoldMessenger?
/// - Respects widget lifecycle
/// - Works during route changes
/// - No "No Overlay widget found" errors
/// - No LateInitializationError
/// 
/// This replaces Get.snackbar in cart/item flows where route changes and rebuilds
/// can cause GetX snackbar to fail.
class AppSnackBar {
  /// Show a success snackbar (green) for cart actions
  /// Returns true if snackbar was shown, false if context is invalid
  static bool showCartSuccess(
    BuildContext? context, {
    bool showViewCartButton = true,
  }) {
    if (context == null || !context.mounted) {
      debugPrint('⚠️ AppSnackBar.showCartSuccess: Invalid context, skipping');
      return false;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      debugPrint('⚠️ AppSnackBar.showCartSuccess: No ScaffoldMessenger found, skipping');
      return false;
    }

    // Clear any existing snackbars
    messenger.clearSnackBars();

    // Build the snackbar content
    final content = Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'item_added_to_cart'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        if (showViewCartButton)
          TextButton(
            onPressed: () {
              messenger.hideCurrentSnackBar();
              Get.toNamed<dynamic>(RouteHelper.getCartRoute());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'view_cart'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );

    messenger.showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.up,
      ),
    );

    return true;
  }

  /// Show a generic snackbar with custom message
  static bool show(
    BuildContext? context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context == null || !context.mounted) {
      debugPrint('⚠️ AppSnackBar.show: Invalid context, skipping');
      return false;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      debugPrint('⚠️ AppSnackBar.show: No ScaffoldMessenger found, skipping');
      return false;
    }

    messenger.clearSnackBars();

    final content = Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );

    messenger.showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: backgroundColor ?? Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );

    return true;
  }
}

