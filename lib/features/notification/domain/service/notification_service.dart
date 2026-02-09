import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/domain/repository/notification_repository_interface.dart';
import 'package:sixam_mart/features/notification/domain/service/notification_service_interface.dart';

class NotificationService implements NotificationServiceInterface {
  final NotificationRepositoryInterface notificationRepositoryInterface;
  NotificationService({required this.notificationRepositoryInterface});

  @override
  Future<List<NotificationModel>?> getNotificationList() async {
    final result = await notificationRepositoryInterface.getList();
    return result is List<NotificationModel>? ? result : null;
  }

  @override
  void saveSeenNotificationCount(int count) {
    notificationRepositoryInterface.saveSeenNotificationCount(count);
  }

  @override
  int? getSeenNotificationCount() {
    return notificationRepositoryInterface.getSeenNotificationCount();
  }

  @override
  List<int> getNotificationIdList() {
    return notificationRepositoryInterface.getNotificationIdList();
  }

  @override
  void addSeenNotificationIdList(List<int> notificationList) {
    notificationRepositoryInterface.addSeenNotificationIdList(notificationList);
  }

}