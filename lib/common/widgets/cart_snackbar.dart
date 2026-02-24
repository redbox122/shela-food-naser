import 'package:flutter/material.dart';
import 'package:sixam_mart/common/utils/app_snackbar.dart';

/// 🔥 PRODUCTION-SAFE CART SNACKBAR: Uses ScaffoldMessenger instead of GetX
/// 
/// This function now delegates to AppSnackBar which uses ScaffoldMessenger.
/// This prevents "No Overlay widget found" and LateInitializationError crashes
/// that occur with GetX snackbar during route changes and rebuilds.
/// 
/// IMPORTANT: context parameter is now REQUIRED for reliable operation.
/// If context is null, the snackbar will be silently skipped (no crash).
void showCartSnackBar([BuildContext? context]) {
  // 🔥 PRODUCTION FIX: Use ScaffoldMessenger instead of GetX snackbar
  // This prevents crashes during route changes, rebuilds, and async operations
  AppSnackBar.showCartSuccess(context, showViewCartButton: false);
}

