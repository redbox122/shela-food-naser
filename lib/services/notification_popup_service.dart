// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/domain/repository/notification_repository_interface.dart';
import 'package:sixam_mart/features/notification/widgets/notifiation_popup_dialog_widget.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/util/backend_message_translator.dart';

class NotificationPopupService {
  static final NotificationRepositoryInterface _notificationRepository =
      Get.find();
  static const bool _popupEnabled = false;

  /// Check if there's an unshown notification popup and display it
  static Future<void> checkAndShowNotificationPopup() async {
    try {
      // Global kill switch: keep notifications in list only, never show popup.
      if (!_popupEnabled) {
        if (_notificationRepository.hasUnshownNotificationPopup()) {
          print(
              '🔕 NotificationPopupService: Popup disabled - marking pending popup as handled');
          _notificationRepository.markNotificationPopupAsShown();
        }
        return;
      }

      // Check if there's an unshown notification popup
      if (!_notificationRepository.hasUnshownNotificationPopup()) {
        print(
            '🔔 NotificationPopupService: No unshown notification popup found');
        return;
      }

      // Get the latest notification for popup
      final NotificationModel? notification =
          _notificationRepository.getLatestNotificationForPopup();
      if (notification == null) {
        print(
            '🔔 NotificationPopupService: No notification data found for popup');
        _notificationRepository.clearLatestNotificationForPopup();
        return;
      }

      // Check if we have a valid context
      if (Get.context == null) {
        print(
            '🔔 NotificationPopupService: No context available, delaying popup');
        return;
      }

      print(
          '🔔 NotificationPopupService: Showing notification popup for: ${notification.data?.title}');

      // Convert to PayloadModel with translations
      final payload = _convertToPayloadModel(notification);

      // Show the professional notification popup dialog
      Get.dialog<void>(
        NotificationPopUpDialogWidget(payload),
      );

      // Mark as shown when dialog is dismissed
      Future.delayed(Duration.zero, () {
        print('🔔 NotificationPopupService: Notification popup dismissed');
        _notificationRepository.markNotificationPopupAsShown();
      });
    } catch (e) {
      print(
          '🔔 NotificationPopupService: Error showing notification popup: $e');
      // Clear invalid data
      _notificationRepository.clearLatestNotificationForPopup();
    }
  }

  /// Save a notification for popup display
  static void saveNotificationForPopup(NotificationModel notification) {
    try {
      print(
          '🔔 NotificationPopupService: Saving notification for popup: ${notification.data?.title}');
      _notificationRepository.saveLatestNotificationForPopup(notification);
    } catch (e) {
      print(
          '🔔 NotificationPopupService: Error saving notification for popup: $e');
    }
  }

  /// Clear any pending notification popup
  static void clearNotificationPopup() {
    try {
      print('🔔 NotificationPopupService: Clearing notification popup');
      _notificationRepository.clearLatestNotificationForPopup();
    } catch (e) {
      print(
          '🔔 NotificationPopupService: Error clearing notification popup: $e');
    }
  }

  /// Check if there's a pending notification popup
  static bool hasPendingNotificationPopup() {
    try {
      return _notificationRepository.hasUnshownNotificationPopup();
    } catch (e) {
      print(
          '🔔 NotificationPopupService: Error checking pending notification popup: $e');
      return false;
    }
  }

  /// Get the latest notification for popup (without showing it)
  static NotificationModel? getLatestNotificationForPopup() {
    try {
      return _notificationRepository.getLatestNotificationForPopup();
    } catch (e) {
      print(
          '🔔 NotificationPopupService: Error getting latest notification for popup: $e');
      return null;
    }
  }

  /// Converts NotificationModel to PayloadModel with translation support
  ///
  /// Automatically:
  /// - Translates title and body using BackendMessageTranslator
  /// - Placeholders ({userName}, {orderId}, {storeName}) are handled by BackendMessageTranslator
  /// - Maps notification data to payload format
  static PayloadModel _convertToPayloadModel(NotificationModel notification) {
    // Get raw title and body
    final rawTitle = notification.data?.title ?? '';
    final rawBody = notification.data?.description ?? '';

    // Translate title and body
    // BackendMessageTranslator will handle placeholder replacement automatically
    // if the message matches a known pattern
    final translatedTitle = BackendMessageTranslator.translate(rawTitle);
    final translatedBody = BackendMessageTranslator.translate(rawBody);

    print(
        '🔔 NotificationPopupService: Translated title: "$rawTitle" → "$translatedTitle"');
    print(
        '🔔 NotificationPopupService: Translated body: "$rawBody" → "$translatedBody"');

    // Extract order ID if present in the text (for navigation)
    String? orderId;
    // ignore: deprecated_member_use
    final orderIdMatch = RegExp(r'\d+').firstMatch(rawBody);
    if (orderIdMatch != null) {
      orderId = orderIdMatch.group(0);
    }

    // Create and return PayloadModel
    return PayloadModel(
      title: translatedTitle.isNotEmpty ? translatedTitle : rawTitle,
      body: translatedBody.isNotEmpty ? translatedBody : rawBody,
      orderId: orderId ?? '',
      type: notification.data?.type ?? 'general',
      image: notification.imageFullUrl ?? notification.data?.imageFullUrl,
    );
  }
}
