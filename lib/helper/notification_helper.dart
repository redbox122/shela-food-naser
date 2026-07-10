import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/demo_reset_dialog_widget.dart';
import 'package:sixam_mart/common/widgets/taxi_make_payment_bottomsheet.dart';
import 'package:sixam_mart/features/chat/controllers/chat_controller.dart';
import 'package:sixam_mart/features/chat/enums/user_type_enum.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/screens/taxi_order_details_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/firebase/my_notification_service.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/backend_message_translator.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:sixam_mart/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart/features/notification/widgets/notifiation_popup_dialog_widget.dart';

class NotificationHelper {
  static Future<void> initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    const androidInitialize =
        AndroidInitializationSettings('notification_icon');
    const iOSInitialize = DarwinInitializationSettings();
    const initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);

    // Request notification permissions for Android 13+
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();

      // Create notification channel with MAX IMPORTANCE (for heads-up banners)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'AzizBaffoun', // channel id (matches manifest)
        'AzizBaffoun', // channel name
        description: 'Notifications for new orders and messages',
        importance: Importance.max, // ⭐ KEY: This enables heads-up banners
      );

      await androidPlugin.createNotificationChannel(channel);
    }

    flutterLocalNotificationsPlugin.initialize(initializationsSettings,
        onDidReceiveNotificationResponse: (NotificationResponse load) async {
      try {
        if (load.payload!.isNotEmpty) {
          final NotificationBodyModel payload =
              NotificationBodyModel.fromJson(jsonDecode(load.payload!) as Map<String, dynamic>);

          final Map<NotificationType, Function> notificationActions = {
            NotificationType.order: () {
              if (AuthHelper.isGuestLoggedIn()) {
                Get.to(() =>
                    const DashboardScreen(pageIndex: 2));
              } else {
                Get.toNamed(RouteHelper.getOrderDetailsRoute(
                    int.parse(payload.orderId.toString()),
                    fromNotification: true));
              }
            },
            NotificationType.block: () => Get.toNamed(
                RouteHelper.getSignInRoute(RouteHelper.notification)),
            NotificationType.unblock: () => Get.toNamed(
                RouteHelper.getSignInRoute(RouteHelper.notification)),
            NotificationType.message: () => Get.toNamed(
                RouteHelper.getChatRoute(
                    notificationBody: payload,
                    conversationID: payload.conversationId,
                    fromNotification: true)),
            NotificationType.otp: () => null,
            NotificationType.add_fund: () =>
                Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
            NotificationType.referral_earn: () =>
                Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
            NotificationType.cashback: () =>
                Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
            NotificationType.loyalty_point: () => Get.toNamed(
                RouteHelper.getLoyaltyRoute(fromNotification: true)),
            NotificationType.general: () => Get.toNamed(
                RouteHelper.getNotificationRoute(fromNotification: true)),
            NotificationType.trip: () => Get.to(() => TaxiOrderDetailsScreen(
                tripId: int.parse(payload.orderId.toString()))),
            NotificationType.coupon: () =>
                Get.toNamed(RouteHelper.getCouponRoute()),
          };

          notificationActions[payload.notificationType]?.call();
        }
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        debugPrint("onMessage: ${message.data['type']}/${message.data}");
      }
      if (message.data['type'] == 'demo_reset') {
        Get.dialog(const DemoResetDialogWidget(), barrierDismissible: false);
      }
      if (message.data['type'] == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.messages)) {
        if (AuthHelper.isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
          if (Get.find<ChatController>()
                  .messageModel!
                  .conversation!
                  .id
                  .toString() ==
              message.data['conversation_id'].toString()) {
            Get.find<ChatController>().getMessages(
              1,
              NotificationBodyModel(
                notificationType: NotificationType.message,
                adminId: message.data['sender_type'] == UserType.admin.name
                    ? 0
                    : null,
                restaurantId:
                    message.data['sender_type'] == UserType.vendor.name
                        ? 0
                        : null,
                deliverymanId:
                    message.data['sender_type'] == UserType.delivery_man.name
                        ? 0
                        : null,
              ),
              null,
              int.parse(message.data['conversation_id'].toString()),
            );
          } else {
            NotificationHelper.showNotification(
                message, flutterLocalNotificationsPlugin);
          }
        }
      } else if (message.data['type'] == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.conversation)) {
        if (AuthHelper.isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
        }
        NotificationHelper.showNotification(
            message, flutterLocalNotificationsPlugin);
      } else if (message.data['type'] == 'demo_reset') {
      } else if (message.data['type'] == 'trip_status' &&
          message.data['status'] == 'completed' &&
          message.data['order_id'] != '' &&
          message.data['order_id'] != null) {
        if (!Get.currentRoute.contains('/TaxiOrderDetailsScreen')) {
          Get.bottomSheet(
              TaxiMakePaymentBottomSheet(orderId: (message.data['order_id'] as String?) ?? ''));
        }
        Get.find<TaxiOrderController>().getTripList(1);
        Get.find<TaxiOrderController>().getTripList(1, isRunning: false);
        if (Get.currentRoute.contains('/TaxiOrderDetailsScreen')) {
          Get.find<TaxiOrderController>().getTripDetails(
              int.parse(message.data['order_id']?.toString() ?? ''),
              willUpdate: false);
        }
      } else {
        if (NotificationService.shouldSuppressPendingDigitalOrderNotification(
            message)) {
          if (kDebugMode) {
            debugPrint(
                '🔕 NotificationHelper: Suppressed pending digital-order placement notification');
          }
          return;
        }
        NotificationHelper.showNotification(
            message, flutterLocalNotificationsPlugin);
        if (AuthHelper.isLoggedIn()) {
          if (message.data['type'] != 'trip_status') {
            Get.find<OrderController>().getRunningOrders(1);
            Get.find<OrderController>().getHistoryOrders(1);
          }

          Get.find<NotificationController>().getNotificationList(true);
          if (message.data['type'] == 'trip_status' &&
              message.data['order_id'] != '' &&
              message.data['order_id'] != null) {
            if (Get.isBottomSheetOpen!) {
              Get.back();
            }
            if (Get.currentRoute.contains('/TaxiOrderDetailsScreen')) {
              await Get.find<TaxiOrderController>().getTripDetails(
                  int.parse(message.data['order_id']?.toString() ?? ''),
                  willUpdate: false);
            }
            Get.find<TaxiOrderController>().getTripList(1);
            Get.find<TaxiOrderController>().getTripList(1, isRunning: false);
          }
        } else if (message.data['type'] == 'trip_status' &&
            message.data['order_id'] != '' &&
            message.data['order_id'] != null) {
          if (Get.isBottomSheetOpen!) {
            Get.back();
          }
          if (Get.currentRoute.contains('/TaxiOrderDetailsScreen')) {
            await Get.find<TaxiOrderController>().getTripDetails(
                int.parse(message.data['order_id']?.toString() ?? ''),
                willUpdate: false);
          }
        }
      }

      final Map<String, String> payloadData = {
        'title': '${message.data['title']}',
        'body': '${message.data['body']}',
        'order_id': '${message.data['order_id']}',
        'image': '${message.data['image']}',
        'type': '${message.data['type']}',
      };

      final PayloadModel payload = PayloadModel.fromJson(payloadData);

      if (kIsWeb) {
        showDialog(
            context: Get.context!,
            builder: (context) => Center(
                  child: NotificationPopUpDialogWidget(payload),
                ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('onOpenApp: ${message.data}');
      }
      try {
        if (message.data.isNotEmpty) {
          final NotificationBodyModel notificationBody =
              convertNotification(message.data);

          final Map<NotificationType, Function> notificationActions = {
            NotificationType.order: () => Get.toNamed(
                RouteHelper.getOrderDetailsRoute(
                    int.parse(message.data['order_id']?.toString() ?? ''),
                    fromNotification: true)),
            NotificationType.block: () => Get.toNamed(
                RouteHelper.getSignInRoute(RouteHelper.notification)),
            NotificationType.unblock: () => Get.toNamed(
                RouteHelper.getSignInRoute(RouteHelper.notification)),
            NotificationType.message: () => Get.toNamed(
                RouteHelper.getChatRoute(
                    notificationBody: notificationBody,
                    conversationID: notificationBody.conversationId,
                    fromNotification: true)),
            NotificationType.otp: () => null,
            NotificationType.add_fund: () =>
                Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
            NotificationType.referral_earn: () =>
                Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
            NotificationType.cashback: () =>
                Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
            NotificationType.loyalty_point: () => Get.toNamed(
                RouteHelper.getLoyaltyRoute(fromNotification: true)),
            NotificationType.general: () => Get.toNamed(
                RouteHelper.getNotificationRoute(fromNotification: true)),
            NotificationType.trip: () => Get.to(() => TaxiOrderDetailsScreen(
                tripId: int.parse(message.data['order_id']?.toString() ?? ''))),
          };

          notificationActions[notificationBody.notificationType]?.call();
        }
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
    });
  }

  static Future<void> showNotification(
      RemoteMessage message, FlutterLocalNotificationsPlugin fln) async {
    if (!GetPlatform.isIOS) {
      String? title;
      String? body;
      String? orderID;
      String? image;
      final NotificationBodyModel notificationBody =
          convertNotification(message.data);

final Map<String, dynamic> data = message.data;

title = data['title']?.toString();
body = data['body']?.toString();
orderID = data['order_id']?.toString();

final imageValue = data['image']?.toString();

image = (imageValue != null && imageValue.isNotEmpty)
    ? imageValue.startsWith('http')
        ? imageValue
        : '${AppConstants.baseUrl}/storage/app/public/notification/$imageValue'
    : null;


if (image != null && image.isNotEmpty) {
  try {
    await showBigPictureNotificationHiddenLargeIcon(
      title,
      body,
      orderID,
      notificationBody,
      image,
      fln,
    );
  } catch (e) {
    await showBigTextNotification(
      title,
      body,
      orderID,
      notificationBody,
      fln,
    );
  }
} else {
  await showBigTextNotification(
    title,
    body,
    orderID,
    notificationBody,
    fln,
  );
}

    }
  }

  static Future<void> showTextNotification(
      String title,
      String body,
      String orderID,
      NotificationBodyModel? notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'AzizBaffoun',
      AppConstants.appName,
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<void> showBigTextNotification(
      String? title,
      String? body,
      String? orderID,
      NotificationBodyModel? notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body ?? '',
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'AzizBaffoun',
      AppConstants.appName,
      importance: Importance.max,
      styleInformation: bigTextStyleInformation,
      priority: Priority.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
      String? title,
      String? body,
      String? orderID,
      NotificationBodyModel? notificationBody,
      String image,
      FlutterLocalNotificationsPlugin fln) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath =
        await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'AzizBaffoun',
      AppConstants.appName,
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      priority: Priority.max,
      styleInformation: bigPictureStyleInformation,
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<String> _downloadAndSaveFile(
      String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final dio_pkg.Response<List<int>> response = await dio_pkg.Dio().get<List<int>>(
      url,
      options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
    );
    final File file = File(filePath);
    await file.writeAsBytes(response.data ?? []);
    return filePath;
  }

  static NotificationBodyModel convertNotification(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'referral_code':
        return NotificationBodyModel(
            notificationType: NotificationType.general);
      case 'referral_earn':
        return NotificationBodyModel(
            notificationType: NotificationType.referral_earn);
      case 'cashback':
        return NotificationBodyModel(
            notificationType: NotificationType.cashback);
      case 'loyalty_point':
        return NotificationBodyModel(
            notificationType: NotificationType.loyalty_point);
      case 'otp':
        return NotificationBodyModel(notificationType: NotificationType.otp);
      case 'add_fund':
        return NotificationBodyModel(
            notificationType: NotificationType.add_fund);
      case 'block':
        return NotificationBodyModel(notificationType: NotificationType.block);
      case 'unblock':
        return NotificationBodyModel(
            notificationType: NotificationType.unblock);
      case 'order_status':
        return _handleOrderNotification(data);
      case 'trip_status':
        return _handleTripNotification(data);
      case 'message':
        return _handleMessageNotification(data);
      default:
        return NotificationBodyModel(
            notificationType: NotificationType.general);
    }
  }

  static NotificationBodyModel _handleOrderNotification(
      Map<String, dynamic> data) {
    final orderId = data['order_id'] as String?;
    return NotificationBodyModel(
      orderId: int.tryParse(orderId ?? '') ?? 0,
      notificationType: NotificationType.order,
    );
  }

  static NotificationBodyModel _handleTripNotification(
      Map<String, dynamic> data) {
    final orderId = data['order_id'] as String?;
    return NotificationBodyModel(
      orderId: int.tryParse(orderId ?? '') ?? 0,
      notificationType: NotificationType.trip,
    );
  }

  static NotificationBodyModel _handleMessageNotification(
      Map<String, dynamic> data) {
    final conversationId = data['conversation_id'];
    final senderType = data['sender_type'];

    return NotificationBodyModel(
      notificationType: NotificationType.message,
      deliverymanId: senderType == 'delivery_man' ? 0 : null,
      adminId: senderType == 'admin' ? 0 : null,
      restaurantId: senderType == 'vendor1' ? 0 : null,
      conversationId: int.parse(conversationId.toString()),
    );
  }
}

/// Background message handler MUST be top-level and annotated
@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('📱 Background notification received!');
    debugPrint(
        "📱 Notification title: ${message.notification?.title ?? message.data['title']}");
    debugPrint(
        "📱 Notification body: ${message.notification?.body ?? message.data['body']}");
  }

  // Initialize local notifications plugin for background notifications
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize Android notification channel
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('notification_icon');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initSettings);

  // Create/update notification channel with heads-up enabled
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'AzizBaffoun',
    'AzizBaffoun',
    description: 'Notifications for new orders and messages',
    importance: Importance.max, // ⭐ KEY for heads-up banners
  );

  final androidPlugin =
      localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(channel);
  }

  // Extract title and body from backend payload
  final String? titleRaw = message.notification?.title ?? (message.data['title'] as String?);
  final String? bodyRaw = message.notification?.body ?? (message.data['body'] as String?);

  if (titleRaw != null && bodyRaw != null) {
    // Extract placeholders from notification data
    final Map<String, String> placeholders =
        BackendMessageTranslator.extractPlaceholdersFromData(message.data);

    // Translate title and body with placeholder replacement
    final String title = BackendMessageTranslator.translate(
      titleRaw,
      replacements: placeholders,
    );
    final String body = BackendMessageTranslator.translate(
      bodyRaw,
      replacements: placeholders,
    );

    if (kDebugMode) {
      debugPrint('📱 Translated title: $title');
      debugPrint('📱 Translated body: $body');
    }

    // Enhanced notification with rich styling
    final BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: 'Tap to open app',
      htmlFormatSummaryText: true,
    );

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'AzizBaffoun',
      'AzizBaffoun',
      channelDescription: 'Notifications for new orders and messages',
      importance: Importance.max, // ⭐ KEY for heads-up banners
      priority: Priority.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
      colorized: true, // Enable colored notification
      ticker: 'New notification',
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      styleInformation: bigTextStyle,
      largeIcon: const DrawableResourceAndroidBitmap('notification_icon'),
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );

    if (kDebugMode) {
      debugPrint('✅ Background notification displayed with enhanced design');
    }
  }
}

class PayloadModel {
  PayloadModel({
    this.title,
    this.body,
    this.orderId,
    this.image,
    this.type,
  });

  String? title;
  String? body;
  String? orderId;
  String? image;
  String? type;

  factory PayloadModel.fromRawJson(String str) =>
      PayloadModel.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => json.encode(toJson());

factory PayloadModel.fromJson(Map<String, dynamic> json) => PayloadModel(
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      orderId: json['order_id']?.toString(),
      image: json['image']?.toString(),
      type: json['type']?.toString(),
    );


  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'order_id': orderId,
        'image': image,
        'type': type,
      };
}
