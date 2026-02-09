import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/utils/snackbar_safe.dart';

/// 🎯 Premium UX Dialog: Ask user if they want to be redirected to nearest service area
/// This dialog appears when user confirms a location outside service zones
/// User has two options:
/// 1. "Yes, redirect me" → Auto-move to nearest zone
/// 2. "No, go to home" → Navigate to home page
class ZoneRedirectionDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ZoneRedirectionDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            
            // 🎯 Title
            Text(
              'zone_outside_service_title'.tr,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeExtraLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            
            // 🎯 Message
            Text(
              'zone_outside_service_message'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            
            // 🎯 Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    child: Text(
                      'zone_redirection_cancel'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                
                // Confirm Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'zone_redirection_confirm'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎯 Helper function to show zone redirection dialog
void showZoneRedirectionDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
  required VoidCallback onCancel,
}) {
  Get.dialog<void>(
    ZoneRedirectionDialog(
      onConfirm: () {
        // 🔥 BUG FIX: Use SnackbarSafe to safely close any open snackbars before navigation
        SnackbarSafe.closeAll();
        
        // Use microtask to separate dialog dismissal from callback (prevents race conditions)
        Future.microtask(() {
          Get.back<void>();
          onConfirm();
        });
      },
      onCancel: () {
        // 🔥 BUG FIX: Use SnackbarSafe to safely close any open snackbars before navigation
        SnackbarSafe.closeAll();
        
        // Use microtask to separate dialog dismissal from callback (prevents race conditions)
        Future.microtask(() {
          Get.back<void>();
          onCancel();
        });
      },
    ),
    barrierDismissible: true,
  );
}

