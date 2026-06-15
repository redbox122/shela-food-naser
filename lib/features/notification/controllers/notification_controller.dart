import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/domain/service/notification_service_interface.dart';
import 'package:sixam_mart/services/notification_popup_service.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class NotificationController extends GetxController implements GetxService {
  final NotificationServiceInterface notificationServiceInterface;
  NotificationController({required this.notificationServiceInterface});

  List<NotificationModel>? _notificationList;
  List<NotificationModel>? get notificationList => _notificationList;

  bool _hasNotification = false;
  bool get hasNotification => _hasNotification;
  bool _hasError = false;
  bool get hasError => _hasError;

  // Task 1: Reactive unread notification signal
  final RxBool hasUnread = false.obs;

  Future<int> getNotificationList(bool reload) async {
    if (_notificationList == null || reload) {
      try {
        _hasError = false;
        final List<NotificationModel>? notificationList =
            await notificationServiceInterface.getNotificationList();

        if (kDebugMode) {
          appLogger.debug(
              '[NotificationController] fetched count=${notificationList?.length ?? -1}');
        }

        if (notificationList != null) {
          _notificationList = [];
          _notificationList!.addAll(notificationList);
          _notificationList!.sort((a, b) {
            return DateConverter.isoStringToLocalDate(a.updatedAt!).compareTo(
              DateConverter.isoStringToLocalDate(b.updatedAt!),
            );
          });
          final Iterable<NotificationModel> iterable =
              _notificationList!.reversed;
          _notificationList = iterable.toList();
          _hasNotification =
              _notificationList!.length != getSeenNotificationCount();

          // Badge = there are notifications the user hasn't opened the page for
          // yet (count exceeds the last-seen count). Opening the notifications
          // page saves seenCount = length, which clears the badge.
          final int seenCount = getSeenNotificationCount() ?? 0;
          final bool hasUnreadNotifications =
              _notificationList!.length > seenCount;
          hasUnread.value = hasUnreadNotifications;
          if (kDebugMode) {
            appLogger.debug(
                '[NotificationController] hasUnread=$hasUnreadNotifications count=${_notificationList!.length} seen=$seenCount');
          }
        } else {
          _notificationList = <NotificationModel>[];
          _hasNotification = false;
          hasUnread.value = false;
          if (kDebugMode) {
            appLogger.warning(
                '[NotificationController] notificationList is null, using empty list');
          }
        }
      } catch (e) {
        _hasError = true;
        _notificationList = <NotificationModel>[];
        _hasNotification = false;
        hasUnread.value = false;
        if (kDebugMode) {
          appLogger.error(
              '[NotificationController] getNotificationList failed: $e', e);
        }
      } finally {
        update();
      }
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

  void saveLatestNotificationForPopup(NotificationModel notification) {
    try {
      NotificationPopupService.saveNotificationForPopup(notification);
      if (kDebugMode) {
        appLogger.debug(
            '[NotificationController] Saved notification for popup: ${notification.data?.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            '[NotificationController] Error saving popup notification: $e', e);
      }
    }
  }

  Future<void> checkAndShowNotificationPopup() async {
    try {
      await NotificationPopupService.checkAndShowNotificationPopup();
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            '[NotificationController] Error checking popup notification: $e', e);
      }
    }
  }

  void clearNotificationPopup() {
    try {
      NotificationPopupService.clearNotificationPopup();
      if (kDebugMode) {
        appLogger.debug('[NotificationController] Cleared popup notification');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            '[NotificationController] Error clearing popup notification: $e', e);
      }
    }
  }

  bool hasPendingNotificationPopup() {
    try {
      return NotificationPopupService.hasPendingNotificationPopup();
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            '[NotificationController] Error checking pending popup notification: $e', e);
      }
      return false;
    }
  }

  NotificationModel? getLatestNotificationForPopup() {
    try {
      return NotificationPopupService.getLatestNotificationForPopup();
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            '[NotificationController] Error getting latest popup notification: $e', e);
      }
      return null;
    }
  }

  Future<void> processNewNotifications() async {
    try {
      await getNotificationList(true);

      if (_notificationList != null && _notificationList!.isNotEmpty) {
        final NotificationModel latestNotification = _notificationList!.first;
        saveLatestNotificationForPopup(latestNotification);

        if (kDebugMode) {
          appLogger.info(
              '[NotificationController] Processed ${_notificationList!.length} notifications, latest: ${latestNotification.data?.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            '[NotificationController] Error processing notifications: $e', e);
      }
    }
  }
}
