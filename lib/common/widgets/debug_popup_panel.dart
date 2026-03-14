/*
 * Debug Popup Panel Widget
 * 
 * This widget provides a debug panel (visible only in debug mode) that allows
 * developers to test all popups, notifications, dialogs, and snackbars in the app.
 * Each button in the panel triggers a corresponding popup for testing purposes.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/payment_complete_dialog.dart';
import 'package:sixam_mart/features/notification/widgets/notifiation_popup_dialog_widget.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/services/app_version_service.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/widgets/update_dialog.dart';

/// Debug popup panel widget that shows a list of buttons to test various popups
class DebugPopupPanel extends StatelessWidget {
  const DebugPopupPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusLarge),
                  topRight: Radius.circular(Dimensions.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      'Debug Popup Panel',
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Scrollable button list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(context, 'Custom Snackbars'),
                    _buildPopupButton(
                      context,
                      'Custom Snackbar (Error)',
                      Icons.error_outline,
                      Colors.red,
                      () => _showCustomSnackbarError(context),
                    ),
                    _buildPopupButton(
                      context,
                      'Custom Snackbar (Success)',
                      Icons.check_circle_outline,
                      Colors.green,
                      () => _showCustomSnackbarSuccess(context),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    _buildSectionHeader(context, 'Notification Popups'),
                    _buildPopupButton(
                      context,
                      'Notification (Order)',
                      Icons.receipt_long,
                      Theme.of(context).primaryColor,
                      () => _showNotificationOrder(context),
                    ),
                    _buildPopupButton(
                      context,
                      'Notification (Message)',
                      Icons.message,
                      Colors.blue,
                      () => _showNotificationMessage(context),
                    ),
                    _buildPopupButton(
                      context,
                      'Notification (Payment)',
                      Icons.payment,
                      Colors.green,
                      () => _showNotificationPayment(context),
                    ),
                    _buildPopupButton(
                      context,
                      'Notification (Delivery)',
                      Icons.delivery_dining,
                      Colors.orange,
                      () => _showNotificationDelivery(context),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    _buildSectionHeader(context, 'Update Dialogs'),
                    _buildPopupButton(
                      context,
                      'Update Dialog (Optional)',
                      Icons.system_update,
                      Colors.blue,
                      () => _showUpdateDialogOptional(context),
                    ),
                    _buildPopupButton(
                      context,
                      'Update Dialog (Force)',
                      Icons.warning,
                      Colors.red,
                      () => _showUpdateDialogForce(context),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    _buildSectionHeader(context, 'Payment Dialogs'),
                    _buildPopupButton(
                      context,
                      'Payment Complete',
                      Icons.check_circle,
                      Colors.green,
                      () => _showPaymentCompleteDialog(context),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    _buildSectionHeader(context, 'GetX Snackbars'),
                    _buildPopupButton(
                      context,
                      'GetX Snackbar (Success)',
                      Icons.check_circle,
                      Colors.green,
                      () => _showGetXSnackbarSuccess(context),
                    ),
                    _buildPopupButton(
                      context,
                      'GetX Snackbar (Error)',
                      Icons.error,
                      Colors.red,
                      () => _showGetXSnackbarError(context),
                    ),
                    _buildPopupButton(
                      context,
                      'GetX Snackbar (Info)',
                      Icons.info,
                      Colors.blue,
                      () => _showGetXSnackbarInfo(context),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    _buildSectionHeader(context, 'Bottom Sheets'),
                    _buildPopupButton(
                      context,
                      'Bottom Sheet Example',
                      Icons.view_day,
                      Theme.of(context).primaryColor,
                      () => _showBottomSheetExample(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeSmall,
      ),
      child: Text(
        title,
        style: robotoBold.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  /// Build popup button
  Widget _buildPopupButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: ElevatedButton.icon(
        onPressed: () {
          Get.back(); // Close debug panel first
          Future.delayed(const Duration(milliseconds: 200), onTap);
        },
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }

  /// Show custom snackbar (error)
  void _showCustomSnackbarError(BuildContext context) {
    showCustomSnackBar(
      'This is a test error message for debugging purposes',
    );
  }

  /// Show custom snackbar (success)
  void _showCustomSnackbarSuccess(BuildContext context) {
    showCustomSnackBar(
      'This is a test success message for debugging purposes',
      isError: false,
    );
  }

  /// Show notification popup (order)
  void _showNotificationOrder(BuildContext context) {
    final payload = _createMockOrderNotification();
    Get.dialog(
      NotificationPopUpDialogWidget(payload),
    );
  }

  /// Show notification popup (message)
  void _showNotificationMessage(BuildContext context) {
    final payload = _createMockMessageNotification();
    Get.dialog(
      NotificationPopUpDialogWidget(payload),
    );
  }

  /// Show notification popup (payment)
  void _showNotificationPayment(BuildContext context) {
    final payload = _createMockPaymentNotification();
    Get.dialog(
      NotificationPopUpDialogWidget(payload),
    );
  }

  /// Show notification popup (delivery)
  void _showNotificationDelivery(BuildContext context) {
    final payload = _createMockDeliveryNotification();
    Get.dialog(
      NotificationPopUpDialogWidget(payload),
    );
  }

  /// Show update dialog (optional)
  void _showUpdateDialogOptional(BuildContext context) {
    final result = _createMockUpdateResult();
    Get.dialog(
      UpdateDialog(
        versionResult: result,
        onDismiss: () {},
      ),
    );
  }

  /// Show update dialog (force)
  void _showUpdateDialogForce(BuildContext context) {
    final result = _createMockForceUpdateResult();
    Get.dialog(
      UpdateDialog(
        versionResult: result,
        onDismiss: () {},
      ),
      barrierDismissible: false, // Force update cannot be dismissed
    );
  }

  /// Show payment complete dialog
  void _showPaymentCompleteDialog(BuildContext context) {
    Get.dialog(
      PaymentCompleteDialog(
        icon: Images.checked,
        title: 'Payment Successful',
        description: 'Your payment has been completed successfully',
        shortDescription: 'Thank you for your payment',
        onYesPressed: () {
          Get.back();
        },
      ),
    );
  }

  /// Show GetX snackbar (success)
  void _showGetXSnackbarSuccess(BuildContext context) {
    Get.snackbar(
      'Success',
      'This is a test success snackbar message',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Show GetX snackbar (error)
  void _showGetXSnackbarError(BuildContext context) {
    Get.snackbar(
      'Error',
      'This is a test error snackbar message',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  /// Show GetX snackbar (info)
  void _showGetXSnackbarInfo(BuildContext context) {
    Get.snackbar(
      'Info',
      'This is a test info snackbar message',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }

  /// Show bottom sheet example
  void _showBottomSheetExample(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radiusLarge),
            topRight: Radius.circular(Dimensions.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Icon(
              Icons.view_day,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'Bottom Sheet Example',
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'This is an example bottom sheet for testing purposes',
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Create mock order notification
  PayloadModel _createMockOrderNotification() {
    return PayloadModel(
      title: 'Order Status Update',
      body: 'Your order #12345 has been confirmed and is being prepared',
      orderId: '12345',
      type: 'order',
    );
  }

  /// Create mock message notification
  PayloadModel _createMockMessageNotification() {
    return PayloadModel(
      title: 'New Message',
      body: 'You have received a new message from the support team',
      type: 'message',
    );
  }

  /// Create mock payment notification
  PayloadModel _createMockPaymentNotification() {
    return PayloadModel(
      title: 'Payment Successful',
      body: 'Your payment of 50.00 SAR has been processed successfully',
      type: 'payment',
    );
  }

  /// Create mock delivery notification
  PayloadModel _createMockDeliveryNotification() {
    return PayloadModel(
      title: 'Delivery Update',
      body: 'Your order is out for delivery. Expected arrival: 30 minutes',
      orderId: '12345',
      type: 'delivery',
    );
  }

  /// Create mock update result (optional)
  VersionCheckResult _createMockUpdateResult() {
    return VersionCheckResult(
      updateAvailable: true,
      isForceUpdate: false,
      latestVersion: '2.0.0',
      minSupportedVersion: '1.5.0',
      currentVersion: '1.9.0',
      releaseNotes: 'New features and bug fixes\n- Improved performance\n- Enhanced UI\n- Bug fixes',
      storeUrl: 'https://play.google.com/store/apps/details?id=com.example.app',
    );
  }

  /// Create mock force update result
  VersionCheckResult _createMockForceUpdateResult() {
    return VersionCheckResult(
      updateAvailable: true,
      isForceUpdate: true,
      latestVersion: '2.0.0',
      minSupportedVersion: '2.0.0',
      currentVersion: '1.9.0',
      releaseNotes: 'Critical update required\n- Security improvements\n- Bug fixes\n- Please update to continue using the app',
      storeUrl: 'https://play.google.com/store/apps/details?id=com.example.app',
    );
  }
}

/// Helper function to show debug popup panel
void showDebugPopupPanel(BuildContext context) {
  if (kDebugMode) {
    Get.dialog(
      const DebugPopupPanel(),
    );
  }
}
