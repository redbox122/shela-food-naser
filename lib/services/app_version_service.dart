import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:in_app_update/in_app_update.dart'; // DISABLED - causes crashes
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/security/certificate_pinning.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class AppVersionService {
  static const String _versionCheckEndpoint = AppConstants.appVersionCheckUri;

  // Singleton pattern
  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification plugin
  Future<void> initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  /// Check for app updates
  Future<VersionCheckResult> checkForUpdates() async {
    try {
      // Get current app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final String platform = (!kIsWeb && Platform.isAndroid) ? 'android' : 'ios';

      // Make API call
      final dio = dio_pkg.Dio();
      CertificatePinning.apply(dio);
      final response = await dio.get<dynamic>(
        '${AppConstants.baseUrl}$_versionCheckEndpoint',
        queryParameters: {'platform': platform, 'current': currentVersion},
        options: dio_pkg.Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (s) => s != null,
        ),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = response.data;
        if (decoded is Map<String, dynamic>) {
          return VersionCheckResult.fromJson(decoded);
        }
        return VersionCheckResult(
          updateAvailable: false,
          isForceUpdate: false,
          latestVersion: currentVersion,
          minSupportedVersion: currentVersion,
          currentVersion: currentVersion,
          releaseNotes: '',
          storeUrl: '',
        );
      } else {
        return VersionCheckResult(
          updateAvailable: false,
          isForceUpdate: false,
          latestVersion: currentVersion,
          minSupportedVersion: currentVersion,
          currentVersion: currentVersion,
          releaseNotes: '',
          storeUrl: '',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('Error checking for updates: $e', e);
      }
      return VersionCheckResult(
        updateAvailable: false,
        isForceUpdate: false,
        latestVersion: '',
        minSupportedVersion: '',
        currentVersion: '',
        releaseNotes: '',
        storeUrl: '',
      );
    }
  }

  /// Launch app store for update
  Future<void> launchStore(String storeUrl) async {
    try {
      final Uri url = Uri.parse(storeUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('Error launching store: $e', e);
      }
    }
  }

  /// Try in-app update for Android (DISABLED - causes crashes)
  Future<bool> tryInAppUpdate() async {
    // DISABLED: Play Store InAppUpdate causes crashes on some devices
    // (low battery, low disk space, etc.)
    if (kDebugMode) {
      appLogger.info('InAppUpdate disabled to prevent crashes');
    }
    return false;
  }

  /// Show update notification
  Future<void> showUpdateNotification(VersionCheckResult result) async {
    await initializeNotifications();

    const androidDetails = AndroidNotificationDetails(
      'app_updates',
      'App Updates',
      channelDescription: 'Notifications for app updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1001,
      result.isForceUpdate ? 'update_required'.tr : 'update_available'.tr,
      'new_version_available'.tr,
      details,
    );
  }

  /// Save last check time to avoid too frequent checks
  Future<void> saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_version_check', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get last check time
  Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_version_check');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Check if enough time has passed since last check (24 hours)
  Future<bool> shouldCheckForUpdates() async {
    // TEMPORARILY DISABLED - Always check for updates
    return true;

    // final lastCheck = await getLastCheckTime();
    // if (lastCheck == null) return true;

    // final now = DateTime.now();
    // final difference = now.difference(lastCheck);
    // return difference.inHours >= 24;
  }

  /// Force immediate update check (for testing)
  Future<void> clearLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_version_check');
  }

  /// Save notification shown time
  Future<void> saveNotificationShownTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_update_notification', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get notification shown time
  Future<DateTime?> getNotificationShownTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_update_notification');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Check if notification should be shown (not shown in last 6 hours)
  Future<bool> shouldShowNotification() async {
    final lastNotification = await getNotificationShownTime();
    if (lastNotification == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastNotification);
    return difference.inHours >= 6;
  }
}

class VersionCheckResult {
  final bool updateAvailable;
  final bool isForceUpdate;
  final String latestVersion;
  final String minSupportedVersion;
  final String currentVersion;
  final String releaseNotes;
  final String storeUrl;

  VersionCheckResult({
    required this.updateAvailable,
    required this.isForceUpdate,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.storeUrl,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      updateAvailable: json.parseBool('update_available'),
      isForceUpdate: json.getStringValue('action') == 'force',
      latestVersion: json.parseStringOrEmpty('latest_version'),
      minSupportedVersion: json.parseStringOrEmpty('min_supported_version'),
      currentVersion: json.parseStringOrEmpty('current_version'),
      releaseNotes: json.parseStringOrEmpty('release_notes'),
      storeUrl: json.parseStringOrEmpty('store_url'),
    );
  }
}
