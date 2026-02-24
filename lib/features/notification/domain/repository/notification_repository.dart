import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/domain/repository/notification_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class NotificationRepository implements NotificationRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  NotificationRepository(
      {required this.apiClient, required this.sharedPreferences});

  @override
  Future<List<NotificationModel>?> getList({int? offset}) async {
    final List<NotificationModel> localNotificationLog =
        _getLocalNotificationLog();
    try {
      final Response response =
          await apiClient.getData(AppConstants.notificationUri);

      if (kDebugMode) {
        appLogger.debug(
            '[NotificationRepo] status=${response.statusCode} bodyType=${response.body.runtimeType}');
      }

      if (response.statusCode == 200) {
        final List<NotificationModel> notificationList = [];
        final dynamic rawBody = response.body;

        if (rawBody is List) {
          for (final dynamic notification in rawBody) {
            if (notification is Map<String, dynamic>) {
              notificationList
                  .add(NotificationModel.fromJson(notification));
            } else if (notification is Map) {
              notificationList.add(NotificationModel.fromJson(
                  Map<String, dynamic>.from(notification)));
            }
          }
        } else if (rawBody is Map<String, dynamic> && rawBody['data'] is List) {
          for (final dynamic notification in rawBody['data'] as List) {
            if (notification is Map<String, dynamic>) {
              notificationList
                  .add(NotificationModel.fromJson(notification));
            } else if (notification is Map) {
              notificationList.add(NotificationModel.fromJson(
                  Map<String, dynamic>.from(notification)));
            }
          }
        }

        if (localNotificationLog.isNotEmpty) {
          return _mergeAndDedupeNotifications(
            primary: notificationList,
            secondary: localNotificationLog,
          );
        }
        return notificationList;
      }

      // 304 / error: prefer local log, otherwise return empty list to avoid endless loader.
      if (localNotificationLog.isNotEmpty) {
        return localNotificationLog;
      }
      return <NotificationModel>[];
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('[NotificationRepo] getList failed: $e', e);
      }
      if (localNotificationLog.isNotEmpty) {
        return localNotificationLog;
      }
      return <NotificationModel>[];
    }
  }

  List<NotificationModel> _getLocalNotificationLog() {
    final List<String> rawLogs =
        sharedPreferences.getStringList(AppConstants.localNotificationLogList) ??
            <String>[];

    final List<NotificationModel> parsed = <NotificationModel>[];
    for (final raw in rawLogs) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          parsed.add(NotificationModel.fromJson(decoded));
        } else if (decoded is Map) {
          parsed.add(NotificationModel.fromJson(
              Map<String, dynamic>.from(decoded)));
        }
      } catch (e) {
        if (kDebugMode) {
          appLogger.warning('Failed to parse local notification log entry: $e');
        }
      }
    }
    return parsed;
  }

  List<NotificationModel> _mergeAndDedupeNotifications({
    required List<NotificationModel> primary,
    required List<NotificationModel> secondary,
  }) {
    final List<NotificationModel> merged = <NotificationModel>[
      ...primary,
      ...secondary,
    ];

    final Set<String> seen = <String>{};
    final List<NotificationModel> unique = <NotificationModel>[];
    for (final notification in merged) {
      final key =
          '${notification.id}|${notification.createdAt}|${notification.data?.title}|${notification.data?.description}';
      if (seen.add(key)) {
        unique.add(notification);
      }
    }
    return unique;
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
        if (kDebugMode) {
          appLogger.error('Error parsing notification popup data: $e', e);
        }
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
