import 'package:sixam_mart/interfaces/repository_interface.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';

abstract class NotificationRepositoryInterface extends RepositoryInterface {
  void saveSeenNotificationCount(int count);
  int? getSeenNotificationCount();
  List<int> getNotificationIdList();
  void addSeenNotificationIdList(List<int> notificationList);

  // Notification popup methods
  void saveLatestNotificationForPopup(NotificationModel notification);
  NotificationModel? getLatestNotificationForPopup();
  void clearLatestNotificationForPopup();
  bool hasUnshownNotificationPopup();
  void markNotificationPopupAsShown();
}
