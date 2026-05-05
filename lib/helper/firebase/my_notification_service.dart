
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // تأكد أنها مضافة

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/backend_message_translator.dart';
import 'package:sixam_mart/common/utils/secure_log.dart';

/// 🔧 BACKGROUND MESSAGE HANDLER (must be top-level)
/// This handler is called when the app is in the background or terminated
/// CRITICAL: Must be top-level function with @pragma annotation for release builds
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    debugPrint('📱 Background message received: ${message.messageId}');
    debugPrint("📱 Title: ${message.notification?.title ?? message.data['title']}");
    debugPrint("📱 Body: ${message.notification?.body ?? message.data['body']}");
  }

  if (message.notification != null) {
    await NotificationService.showNotification(message);
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool isNotificationTapped = false;
  static bool _isInitialized = false;
  static bool _backgroundHandlerRegistered = false;

  /// Registers the FCM background message handler exactly once per isolate.
  ///
  /// The flag is flipped BEFORE the native call so any reentrant invocation
  /// (e.g. from a plugin callback that triggers initialization again) is
  /// short-circuited even if the previous call has not returned yet.
  static void registerBackgroundHandlerOnce() {
    if (_backgroundHandlerRegistered) {
      if (kDebugMode) {
        debugPrint('[FCM][BACKGROUND_HANDLER_ALREADY_REGISTERED_SKIP]');
      }
      return;
    }
    _backgroundHandlerRegistered = true;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      if (kDebugMode) {
        debugPrint('[FCM][BACKGROUND_HANDLER_REGISTERED]');
      }
    } catch (e) {
      // If the registration itself throws, leave the flag set so we do not
      // retry — Firebase considers a duplicate registration an error too.
      if (kDebugMode) {
        debugPrint('[FCM][BACKGROUND_HANDLER_REGISTRATION_ERROR] $e');
      }
    }
  }

  // Initialize notification service

  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint(
            '⏭️ NotificationService: initialize skipped (already initialized)');
      }
      return;
    }

    // ✅ اشتراك بالتوبيك فقط على المنصات غير الويب
    if (!kIsWeb) {
      _firebaseMessaging.subscribeToTopic('all');
    } else {
      debugPrint('⛔ Skipping topic subscription: not supported on web.');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
            'notification_icon'); // Use notification_icon for consistency
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Create notification channel BEFORE initializing (critical for release builds)
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Request notification permissions for Android 13+
        await androidPlugin.requestNotificationsPermission();

        // Create notification channel with MAX IMPORTANCE (for heads-up banners)
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'AzizBaffoun', // Must match AndroidManifest
          'AzizBaffoun',
          description: 'Notifications for new orders and messages',
          importance: Importance.max, // Critical for heads-up notifications
        );

        await androidPlugin.createNotificationChannel(channel);
        debugPrint('✅ Notification channel created: AzizBaffoun');
      }
    }

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    if (!kIsWeb && Platform.isIOS) {
      await _firebaseMessaging.requestPermission();
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    FirebaseMessaging.onMessage.listen(_onMessage);

    final NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _firebaseMessaging.getInitialMessage().then(_onInitialMessage);
    }

    _getDeviceToken();
    _isInitialized = true;
  }

  // Foreground notification
  Future<void> _onMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.notification?.title}');
    if (_shouldSuppressForegroundOrderNotification(message)) {
      debugPrint(
          '🔕 NotificationService: Suppressed pending/unpaid order notification during payment webview');
      return;
    }
    if (message.notification != null) {
      await NotificationService.showNotification(message);
      _handleNotificationTap(message);

      // Save notification for popup display
      _saveNotificationForPopup(message);
    }
  }

  // Terminated notification
  Future<void> _onInitialMessage(RemoteMessage? message) async {
    if (message != null) {
      debugPrint('Terminated state message: ${message.notification?.title}');
      if (_shouldSuppressForegroundOrderNotification(message)) {
        debugPrint(
            '🔕 NotificationService: Suppressed pending/unpaid initial order notification during payment webview');
        return;
      }
      if (message.notification != null) {
        await NotificationService.showNotification(message);
        _handleNotificationTap(message);

        // Save notification for popup display
        _saveNotificationForPopup(message);
      }
    }
  }

  // Make notification static so background can call it
  static Future<void> showNotification(RemoteMessage message) async {
    // Extract placeholders from notification data
    final Map<String, String> placeholders =
        BackendMessageTranslator.extractPlaceholdersFromData(message.data);

    // Translate title and body with placeholder replacement
    final String? titleRaw = message.notification?.title;
    final String? bodyRaw = message.notification?.body;

    final String? title = titleRaw != null
        ? BackendMessageTranslator.translate(titleRaw,
            replacements: placeholders)
        : null;
    final String? body = bodyRaw != null
        ? BackendMessageTranslator.translate(bodyRaw,
            replacements: placeholders)
        : null;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'AzizBaffoun', // Must match AndroidManifest channel ID
      'AzizBaffoun', // Must match AndroidManifest channel name
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
      payload: message.data.toString(),
    );

    await _persistRemoteMessageToLocalLog(message);
  }

  static NotificationModel _toNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      data: Data(
        title: message.notification?.title ?? 'Notification',
        description:
            message.notification?.body ?? 'You have a new notification',
        imageFullUrl: message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl,
        type: (message.data['type'] as String?) ?? 'general',
      ),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      imageFullUrl: message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      status: 0,
    );
  }

  static Future<void> _persistRemoteMessageToLocalLog(
      RemoteMessage message) async {
    try {
      final NotificationModel notificationModel = _toNotificationModel(message);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> existing = prefs
              .getStringList(AppConstants.localNotificationLogList)
              ?.toList() ??
          <String>[];

      existing.insert(0, jsonEncode(notificationModel.toJson()));
      if (existing.length > 100) {
        existing.removeRange(100, existing.length);
      }
      await prefs.setStringList(
          AppConstants.localNotificationLogList, existing);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔔 NotificationService: Failed to persist local log: $e');
      }
    }
  }

  Future<void> _getDeviceToken() async {
    final String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      SecureLog.logRedactedToken('fcm device token=${SecureLog.maskToken(token)}');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (isNotificationTapped) return;
    isNotificationTapped = true;
  }

  // Save notification for popup display
  void _saveNotificationForPopup(RemoteMessage message) {
    try {
      if (Get.isRegistered<NotificationController>()) {
        final notificationController = Get.find<NotificationController>();

        final notificationModel = _toNotificationModel(message);

        // Save for popup display
        notificationController
            .saveLatestNotificationForPopup(notificationModel);
        debugPrint(
            '🔔 NotificationService: Saved notification for popup: ${message.notification?.title}');
      } else {
        debugPrint(
            '🔔 NotificationService: NotificationController not registered yet');
      }
    } catch (e) {
      debugPrint('🔔 NotificationService: Error saving notification for popup: $e');
    }
  }

  bool _shouldSuppressForegroundOrderNotification(RemoteMessage message) {
    final String currentRoute = Get.currentRoute.toLowerCase();
    final bool isOnPaymentWebView =
        currentRoute.contains('myfatoorahpaymentwebviewscreen'.toLowerCase());
    if (!isOnPaymentWebView) {
      return false;
    }
    final Map<String, dynamic> data = message.data;
    final String type = (data['type'] ?? data['notification_type'] ?? '')
        .toString()
        .toLowerCase();
    final String title = (message.notification?.title ?? '').toLowerCase();
    final String body = (message.notification?.body ?? '').toLowerCase();
    final String paymentStatus =
        (data['payment_status'] ?? '').toString().toLowerCase();
    final String orderStatus =
        (data['order_status'] ?? '').toString().toLowerCase();
    final bool hasOrderId = data['order_id'] != null;
    final bool isOrderLike = hasOrderId ||
        type.contains('order') ||
        title.contains('order') ||
        body.contains('order') ||
        title.contains('طلب') ||
        body.contains('طلب');
    if (!isOrderLike) {
      return false;
    }
    const Set<String> pendingPaymentStates = <String>{
      '',
      'unpaid',
      'pending',
      'created',
    };
    const Set<String> nonFinalOrderStates = <String>{
      '',
      'pending',
      'confirmed',
      'processing',
      'accepted',
      'handover',
      'picked_up',
      'out_for_delivery',
      'ongoing',
    };
    return pendingPaymentStates.contains(paymentStatus) ||
        nonFinalOrderStates.contains(orderStatus);
  }
}
