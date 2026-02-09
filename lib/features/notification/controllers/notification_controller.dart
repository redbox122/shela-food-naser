import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/domain/service/notification_service_interface.dart';
import 'package:sixam_mart/services/notification_popup_service.dart';

class NotificationController extends GetxController implements GetxService {
  final NotificationServiceInterface notificationServiceInterface;
  NotificationController({required this.notificationServiceInterface});

  List<NotificationModel>? _notificationList;
  List<NotificationModel>? get notificationList => _notificationList;

  bool _hasNotification = false;
  bool get hasNotification => _hasNotification;

  // ⚡ TASK 1: Reactive unread notification signal
  final RxBool hasUnread = false.obs;

  Future<int> getNotificationList(bool reload) async {
    if (_notificationList == null || reload) {
      final List<NotificationModel>? notificationList =
          await notificationServiceInterface.getNotificationList();
      if (notificationList != null) {
        _notificationList = [];
        _notificationList!.addAll(notificationList);
        _notificationList!.sort((a, b) {
          return DateConverter.isoStringToLocalDate(a.updatedAt!).compareTo(
            DateConverter.isoStringToLocalDate(b.updatedAt!),
          );
        });
        final Iterable<NotificationModel> iterable = _notificationList!.reversed;
        _notificationList = iterable.toList();
        _hasNotification =
            _notificationList!.length != getSeenNotificationCount();
        
        // ⚡ TASK 1: Check for unread notifications (status == 0)
        final hasUnreadNotifications = _notificationList!.any((notification) => notification.status == 0);
        hasUnread.value = hasUnreadNotifications;
        if (kDebugMode) {
          print('🔔 NotificationController: hasUnread = $hasUnreadNotifications (${_notificationList!.where((n) => n.status == 0).length} unread)');
        }
      }
      update();
    }

    return _notificationList?.length ?? 0;
  }

  void saveSeenNotificationCount(int count) {
    notificationServiceInterface.saveSeenNotificationCount(count);
  }

  int? getSeenNotificationCount() {
    return notificationServiceInterface.getSeenNotificationCount();
  }

  void clearNotification() {
    _notificationList = null;
  }

  List<int>? getSeenNotificationIdList() {
    return notificationServiceInterface.getNotificationIdList();
  }

  void addSeenNotificationId(int id) {
    final List<int> idList = [];
    idList.addAll(notificationServiceInterface.getNotificationIdList());
    idList.add(id);
    notificationServiceInterface.addSeenNotificationIdList(idList);
    update();
  }

  /// Save the latest notification for popup display
  void saveLatestNotificationForPopup(NotificationModel notification) {
    try {
      NotificationPopupService.saveNotificationForPopup(notification);
      print(
          '🔔 NotificationController: Saved notification for popup: ${notification.data?.title}');
    } catch (e) {
      print(
          '🔔 NotificationController: Error saving notification for popup: $e');
    }
  }

  /// Check and show notification popup if available
  Future<void> checkAndShowNotificationPopup() async {
    try {
      await NotificationPopupService.checkAndShowNotificationPopup();
    } catch (e) {
      print('🔔 NotificationController: Error checking notification popup: $e');
    }
  }

  /// Clear any pending notification popup
  void clearNotificationPopup() {
    try {
      NotificationPopupService.clearNotificationPopup();
      print('🔔 NotificationController: Cleared notification popup');
    } catch (e) {
      print('🔔 NotificationController: Error clearing notification popup: $e');
    }
  }

  /// Check if there's a pending notification popup
  bool hasPendingNotificationPopup() {
    try {
      return NotificationPopupService.hasPendingNotificationPopup();
    } catch (e) {
      print(
          '🔔 NotificationController: Error checking pending notification popup: $e');
      return false;
    }
  }

  /// Get the latest notification for popup
  NotificationModel? getLatestNotificationForPopup() {
    try {
      return NotificationPopupService.getLatestNotificationForPopup();
    } catch (e) {
      print(
          '🔔 NotificationController: Error getting latest notification for popup: $e');
      return null;
    }
  }

  /// Process new notifications and save the latest one for popup
  Future<void> processNewNotifications() async {
    try {
      // Reload notifications to get the latest ones
      await getNotificationList(true);

      if (_notificationList != null && _notificationList!.isNotEmpty) {
        // Get the most recent notification (first in the sorted list)
        final NotificationModel latestNotification = _notificationList!.first;

        // Save it for popup display
        saveLatestNotificationForPopup(latestNotification);

        print(
            '🔔 NotificationController: Processed ${_notificationList!.length} notifications, latest: ${latestNotification.data?.title}');
      }
    } catch (e) {
      print(
          '🔔 NotificationController: Error processing new notifications: $e');
    }
  }
}
