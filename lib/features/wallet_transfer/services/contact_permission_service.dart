import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

/// Service for handling contact permissions
/// Follows the same pattern as location permission service
class ContactPermissionService {
  /// Checks contact permission and requests if needed
  /// Executes onTap callback if permission is granted
  Future<void> checkContactPermission(Function onTap) async {
    debugPrint('🔍 Checking contact permission...');

    PermissionStatus permission = await Permission.contacts.status;
    debugPrint('🔍 Initial permission status: $permission');

    if (permission.isDenied) {
      debugPrint('🔍 Permission denied, requesting permission...');
      permission = await Permission.contacts.request();
      debugPrint('🔍 Permission after request: $permission');
    }

    if (permission.isDenied) {
      debugPrint('❌ Permission still denied, showing snackbar');
      showCustomSnackBar('contacts_permission_denied'.tr);
    } else if (permission.isPermanentlyDenied) {
      debugPrint('❌ Permission denied forever, showing dialog');
      _showPermissionDialog();
    } else if (permission.isGranted) {
      debugPrint('✅ Permission granted, executing onTap callback');
      onTap();
    } else {
      debugPrint('⚠️ Unknown permission status: $permission');
      showCustomSnackBar('contacts_permission_required'.tr);
    }
  }

  /// Shows dialog when permission is permanently denied
  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('contacts_permission_required'.tr),
        content: Text('contacts_permission_denied'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: Text('settings'.tr),
          ),
        ],
      ),
    );
  }
}


