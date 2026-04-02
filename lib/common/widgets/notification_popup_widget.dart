import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/widgets/notifiation_popup_dialog_widget.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/backend_message_translator.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class NotificationPopupWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback? onViewDetails;

  const NotificationPopupWidget({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusLarge),
                  topRight: Radius.circular(Dimensions.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      'notification'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(
                          Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notification content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification image
                    if (notification.imageFullUrl != null &&
                        notification.imageFullUrl!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 150,
                        margin: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                                notification.imageFullUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    // Notification title
                    if (notification.data?.title != null &&
                        notification.data!.title!.isNotEmpty)
                      Text(
                        notification.data!.title!,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),

                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    // Notification description
                    if (notification.data?.description != null &&
                        notification.data!.description!.isNotEmpty)
                      Text(
                        notification.data!.description!,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                      ),

                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // Notification type badge
                    if (notification.data?.type != null &&
                        notification.data!.type!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall,
                          vertical: Dimensions.paddingSizeExtraSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        child: Text(
                          notification.data!.type!.toUpperCase(),
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(Dimensions.radiusLarge),
                  bottomRight: Radius.circular(Dimensions.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeSmall),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'dismiss'.tr,
                        style: robotoMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onDismiss();
                        _handleNotificationAction(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeSmall),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                      ),
                      child: Text(
                        'view_details'.tr,
                        style: robotoMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationAction(BuildContext context) {
    if (onViewDetails != null) {
      onViewDetails!();
      return;
    }

    // Default action based on notification type
    final notificationType = notification.data?.type;
    if (notificationType != null) {
      switch (notificationType.toLowerCase()) {
        case 'order':
          // Navigate to orders screen
          Get.toNamed<String>(RouteHelper.getOrderRoute());
          break;
        case 'message':
          // Navigate to messages screen
          Get.toNamed<String>(RouteHelper.getChatRoute(notificationBody: null));
          break;
        case 'offer':
        case 'promotion':
          // Navigate to offers screen
          Get.toNamed<String>(RouteHelper.getMainRoute('offers'));
          break;
        case 'wallet':
        case 'payment':
          // Navigate to wallet screen
          Get.toNamed<String>(RouteHelper.getWalletRoute());
          break;
        default:
          // Navigate to notifications screen
          Get.toNamed<String>(RouteHelper.getNotificationRoute());
          break;
      }
    } else {
      // Fallback to notifications screen
      Get.toNamed<String>(RouteHelper.getNotificationRoute());
    }
  }
}

// Helper function to show notification popup with professional dialog and translation
void showNotificationPopup({
  required NotificationModel notification,
  VoidCallback? onDismiss,
  VoidCallback? onViewDetails,
}) {
  // Convert notification to PayloadModel with translations
  final payload = _convertNotificationToPayload(notification);

  // Show professional notification dialog
  Get.dialog<void>(
    NotificationPopUpDialogWidget(payload),
  );

  // Execute callback when dialog is dismissed
  if (onDismiss != null) {
    Future.delayed(Duration.zero, onDismiss);
  }
}

/// Converts NotificationModel to PayloadModel with automatic translation
PayloadModel _convertNotificationToPayload(NotificationModel notification) {
  // Get raw messages
  final rawTitle = notification.data?.title ?? '';
  final rawBody = notification.data?.description ?? '';

  // Translate messages
  // BackendMessageTranslator handles placeholder replacement automatically
  final translatedTitle = BackendMessageTranslator.translate(rawTitle);
  final translatedBody = BackendMessageTranslator.translate(rawBody);

  // Extract order ID if present in the text (for navigation)
  String? orderId;
  // ignore: deprecated_member_use
  final orderIdMatch = RegExp(r'\d+').firstMatch(rawBody);
  if (orderIdMatch != null) {
    orderId = orderIdMatch.group(0);
  }

  return PayloadModel(
    title: translatedTitle.isNotEmpty ? translatedTitle : rawTitle,
    body: translatedBody.isNotEmpty ? translatedBody : rawBody,
    orderId: orderId ?? '',
    type: notification.data?.type ?? 'general',
    image: notification.imageFullUrl ?? notification.data?.imageFullUrl,
  );
}
