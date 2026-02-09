// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/foundation.dart'; // تأكد أنها مضافة

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/util/backend_message_translator.dart';

/// 🔧 BACKGROUND MESSAGE HANDLER (must be top-level)
/// This handler is called when the app is in the background or terminated
/// CRITICAL: Must be top-level function with @pragma annotation for release builds
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print('📱 Background message received: ${message.messageId}');
    print("📱 Title: ${message.notification?.title ?? message.data['title']}");
    print("📱 Body: ${message.notification?.body ?? message.data['body']}");
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

  // Initialize notification service

  Future<void> initialize() async {
    // ✅ اشتراك بالتوبيك فقط على المنصات غير الويب
    if (!kIsWeb) {
      _firebaseMessaging.subscribeToTopic('all');
    } else {
      print('⛔ Skipping topic subscription: not supported on web.');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('notification_icon'); // Use notification_icon for consistency
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Create notification channel BEFORE initializing (critical for release builds)
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
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
        print('✅ Notification channel created: AzizBaffoun');
      }
    }

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    if (!kIsWeb && Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        
      );
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    FirebaseMessaging.onMessage.listen(_onMessage);

    final NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _firebaseMessaging.getInitialMessage().then(_onInitialMessage);
    }

    _getDeviceToken();
  }

  // Foreground notification
  Future<void> _onMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');
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
      print('Terminated state message: ${message.notification?.title}');
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
  }

  Future<void> _getDeviceToken() async {
    final String? token = await _firebaseMessaging.getToken();
    print('Device Token: $token');
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

        // Create NotificationModel from RemoteMessage
        final notificationModel = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch, // Use timestamp as ID
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
        );

        // Save for popup display
        notificationController
            .saveLatestNotificationForPopup(notificationModel);
        print(
            '🔔 NotificationService: Saved notification for popup: ${message.notification?.title}');
      } else {
        print(
            '🔔 NotificationService: NotificationController not registered yet');
      }
    } catch (e) {
      print('🔔 NotificationService: Error saving notification for popup: $e');
    }
  }
}
