import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/domain/repository/notification_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class NotificationRepository implements NotificationRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  NotificationRepository(
      {required this.apiClient, required this.sharedPreferences});

  @override
  Future<List<NotificationModel>?> getList({int? offset}) async {
    List<NotificationModel>? notificationList;
    final Response response = await apiClient.getData(AppConstants.notificationUri);
    if (response.statusCode == 200) {
      notificationList = [];
      for (var notification in (response.body as List)) {
        notificationList.add(NotificationModel.fromJson(notification as Map<String, dynamic>));
      }
    }
    return notificationList;
  }

  @override
  void saveSeenNotificationCount(int count) {
    sharedPreferences.setInt(AppConstants.notificationCount, count);
  }

  @override
  int? getSeenNotificationCount() {
    return sharedPreferences.getInt(AppConstants.notificationCount);
  }

  @override
  List<int> getNotificationIdList() {
    List<String>? list = [];
    if (sharedPreferences.containsKey(AppConstants.notificationIdList)) {
      list = sharedPreferences.getStringList(AppConstants.notificationIdList);
    }
    final List<int> notificationIdList = [];
    if (list != null) {
      for (final id in list) {
        notificationIdList.add(jsonDecode(id) as int);
      }
    }
    return notificationIdList;
  }

  @override
  void addSeenNotificationIdList(List<int> notificationList) {
    final List<String> list = [];
    for (final int id in notificationList) {
      list.add(jsonEncode(id));
    }
    sharedPreferences.setStringList(AppConstants.notificationIdList, list);
  }

  @override
  void saveLatestNotificationForPopup(NotificationModel notification) {
    final String notificationJson = jsonEncode(notification.toJson());
    sharedPreferences.setString(
        AppConstants.latestNotificationForPopup, notificationJson);
    sharedPreferences.setBool(AppConstants.hasUnshownNotificationPopup, true);
  }

  @override
  NotificationModel? getLatestNotificationForPopup() {
    final String? notificationJson =
        sharedPreferences.getString(AppConstants.latestNotificationForPopup);
    if (notificationJson != null && notificationJson.isNotEmpty) {
      try {
        final Map<String, dynamic> json = jsonDecode(notificationJson) as Map<String, dynamic>;
        return NotificationModel.fromJson(json);
      } catch (e) {
        print('Error parsing notification popup data: $e');
        return null;
      }
    }
    return null;
  }

  @override
  void clearLatestNotificationForPopup() {
    sharedPreferences.remove(AppConstants.latestNotificationForPopup);
    sharedPreferences.setBool(AppConstants.hasUnshownNotificationPopup, false);
  }

  @override
  bool hasUnshownNotificationPopup() {
    return sharedPreferences
            .getBool(AppConstants.hasUnshownNotificationPopup) ??
        false;
  }

  @override
  void markNotificationPopupAsShown() {
    sharedPreferences.setBool(AppConstants.hasUnshownNotificationPopup, false);
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
