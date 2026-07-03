
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // تأكد أنها مضافة

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
// ── Voice call (additive): open the incoming-call screen for call pushes.
import 'package:sixam_mart/features/call/data/models/call_model.dart';
import 'package:sixam_mart/features/call/presentation/screens/incoming_call_screen.dart';
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

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      // Tapping a notification we displayed ourselves (foreground) routes to
      // the right screen via its JSON payload — same logic as a tap from
      // background/terminated below.
      onDidReceiveNotificationResponse: _onLocalNotificationResponse,
    );

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
    // Incoming voice call (additive): show the full-screen incoming-call UI.
    if (NotificationService._openIncomingCallIfNeeded(message.data)) return;
    if (_shouldSuppressForegroundOrderNotification(message)) {
      debugPrint(
          '🔕 NotificationService: Suppressed pending/unpaid order notification during payment webview');
      return;
    }
    if (message.notification != null) {
      // Foreground: show the notification, but DON'T navigate — navigation
      // only happens when the user actually taps it (handled by
      // _onLocalNotificationResponse).
      await NotificationService.showNotification(message);

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
        // Save notification for popup display
        _saveNotificationForPopup(message);
        // App was launched by tapping this notification: route to its screen
        // once the first route is mounted (the router isn't ready yet here).
        Future.delayed(const Duration(seconds: 1),
            () => _navigateFromData(message.data));
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
      // JSON (not toString) so the tap handler can decode `type`/`order_id`.
      payload: jsonEncode(message.data),
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
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        SecureLog.logRedactedToken(
            'fcm device token=${SecureLog.maskToken(token)}');
      }
    } catch (e) {
      // SERVICE_NOT_AVAILABLE شائع عند ضعف الشبكة أو غياب Google Play Services.
      // لا نوقف التدفّق — سيُجلب الـ token لاحقاً عبر onTokenRefresh.
      if (kDebugMode) {
        debugPrint('🔔 NotificationService: getToken failed (سيُعاد لاحقاً): $e');
      }
    }
  }

  // Background tap (app alive, in background): FCM delivers the tapped message
  // here — route straight to its screen.
  void _handleNotificationTap(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  // Foreground local-notification tap: decode the JSON payload we attached in
  // showNotification(), then route through the same logic.
  static void _onLocalNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map) {
        _navigateFromData(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 notification payload decode failed: $e');
    }
  }

  /// The SINGLE source of truth for notification routing (unifying the two
  /// previously-conflicting systems). Maps the backend `type` + `order_id` to a
  /// route via the shared [NotificationHelper.convertNotification] parser.
  /// Voice-call routing (additive): if [data] is an incoming-call push, open the
  /// incoming-call screen and return true so the caller stops normal handling.
  static bool _openIncomingCallIfNeeded(Map<String, dynamic> data) {
    if (data['type']?.toString() != 'incoming_call') return false;
    try {
      final payload =
          IncomingCallPayload.fromData(Map<String, dynamic>.from(data));
      Get.to<void>(() => IncomingCallScreen(payload: payload));
    } catch (_) {}
    return true;
  }

  static void _navigateFromData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    // Incoming voice call takes over routing when present.
    if (_openIncomingCallIfNeeded(data)) return;
    try {
      final NotificationBodyModel body =
          NotificationHelper.convertNotification(Map<String, dynamic>.from(data));
      final int? orderId = int.tryParse(data['order_id']?.toString() ?? '');
      switch (body.notificationType) {
        case NotificationType.order:
        case NotificationType.trip:
          if (orderId != null) {
            Get.toNamed(RouteHelper.getOrderDetailsRoute(orderId,
                fromNotification: true));
          } else {
            Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
          }
          break;
        case NotificationType.message:
          Get.toNamed(RouteHelper.getChatRoute(
              notificationBody: body,
              conversationID: body.conversationId,
              fromNotification: true));
          break;
        case NotificationType.add_fund:
        case NotificationType.referral_earn:
        case NotificationType.cashback:
          Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true));
          break;
        case NotificationType.loyalty_point:
          Get.toNamed(RouteHelper.getLoyaltyRoute(fromNotification: true));
          break;
        case NotificationType.block:
        case NotificationType.unblock:
          Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.notification));
          break;
        default:
          // general / otp / referral_code / unknown → notifications list.
          Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 notification routing failed: $e');
    }
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

  /// Shared with [NotificationHelper] — suppress "order placed" while digital payment is pending.
  static bool shouldSuppressPendingDigitalOrderNotification(
      RemoteMessage message) {
    if (!isPendingOrderPlacementNotification(message)) {
      return false;
    }
    if (!Get.isRegistered<CheckoutController>()) {
      return false;
    }
    return Get.find<CheckoutController>()
        .suppressPendingOrderPlacementNotifications;
  }

  static bool isPendingOrderPlacementNotification(RemoteMessage message) {
    final String title = (message.notification?.title ?? '').toLowerCase();
    final String body = (message.notification?.body ?? '').toLowerCase();
    if (title.contains('successfully placed') ||
        body.contains('successfully placed') ||
        title.contains('is_successfully_placed') ||
        body.contains('is_successfully_placed')) {
      return true;
    }
    final Map<String, dynamic> data = message.data;
    final String paymentStatus =
        (data['payment_status'] ?? '').toString().toLowerCase();
    final bool hasOrderId = data['order_id'] != null;
    final String type = (data['type'] ?? data['notification_type'] ?? '')
        .toString()
        .toLowerCase();
    final bool isOrderLike = hasOrderId ||
        type.contains('order') ||
        title.contains('order') ||
        body.contains('order') ||
        title.contains('طلب') ||
        body.contains('طلب');
    if (!isOrderLike) {
      return false;
    }
    return paymentStatus.isEmpty ||
        paymentStatus == 'unpaid' ||
        paymentStatus == 'pending' ||
        paymentStatus == 'created';
  }

  bool _shouldSuppressForegroundOrderNotification(RemoteMessage message) {
    if (shouldSuppressPendingDigitalOrderNotification(message)) {
      debugPrint(
          '🔕 NotificationService: Suppressed pending digital-order placement notification');
      return true;
    }

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
