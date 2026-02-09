import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/helpers/notification_translation_helper.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Professional notification popup dialog widget with full translation support
/// and modern UI design for order status updates and notifications
class NotificationPopUpDialogWidget extends StatefulWidget {
  final PayloadModel payloadModel;
  const NotificationPopUpDialogWidget(this.payloadModel, {super.key});

  @override
  State<NotificationPopUpDialogWidget> createState() =>
      _NewRequestDialogState();
}

class _NewRequestDialogState extends State<NotificationPopUpDialogWidget> {
  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  void _startAlarm() async {
    try {
      final AudioPlayer audio = AudioPlayer();
      await audio.play(AssetSource('notification.wav'));
    } catch (e) {
      // Silently handle audio playback errors to prevent app crashes
      // The notification popup will still display even if sound fails
      debugPrint('⚠️ NotificationPopUpDialogWidget: Failed to play notification sound: $e');
    }
  }

  /// Returns contextual icon based on notification type
  IconData _getNotificationIcon() {
    final String? type = widget.payloadModel.type?.toLowerCase();

    switch (type) {
      case 'order':
      case 'order_status':
        return Icons.receipt_long;
      case 'message':
        return Icons.message;
      case 'delivery':
        return Icons.delivery_dining;
      case 'payment':
        return Icons.payment;
      case 'general':
        return Icons.notifications_active;
      default:
        return Icons.notifications;
    }
  }

  /// Returns contextual color based on notification type
  Color _getNotificationColor(BuildContext context) {
    final String? type = widget.payloadModel.type?.toLowerCase();

    switch (type) {
      case 'order':
      case 'order_status':
        return Theme.of(context).primaryColor;
      case 'message':
        return Colors.blue;
      case 'delivery':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  /// Builds translated title with order ID badge
  Widget _buildTranslatedTitle(BuildContext context) {
    final String translatedTitle =
        NotificationTranslationHelper.translateNotificationTitle(
            widget.payloadModel.title ?? '');

    return Text(
      translatedTitle,
      textAlign: TextAlign.center,
      style: robotoBold.copyWith(
        fontSize: Dimensions.fontSizeExtraLarge,
        color: Theme.of(context).textTheme.bodyLarge?.color,
        height: 1.3,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Builds translated notification body
  Widget _buildTranslatedBody(BuildContext context) {
    final String translatedBody =
        NotificationTranslationHelper.translateNotificationDescription(
            widget.payloadModel.body ?? '');

    return Text(
      translatedBody,
      textAlign: TextAlign.center,
      style: robotoRegular.copyWith(
        fontSize: Dimensions.fontSizeDefault,
        height: 1.6,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
        letterSpacing: 0.1,
      ),
    );
  }

  /// Builds notification image if available
  Widget _buildNotificationImage() {
    final bool hasImage = widget.payloadModel.image != null &&
        widget.payloadModel.image != 'null' &&
        widget.payloadModel.image!.isNotEmpty;

    if (!hasImage) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FadeInImage.assetNetwork(
          image: widget.payloadModel.image!,
          height: 140,
          width: double.infinity,
          placeholder: Images.placeholder,
          fit: BoxFit.cover,
          imageCacheWidth: 800,
          imageCacheHeight: 300,
          imageErrorBuilder: (context, error, stackTrace) {
            return Image.asset(
              Images.placeholder,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }

  /// Builds notification type badge
  Widget _buildTypeBadge(BuildContext context) {
    final String? type = widget.payloadModel.type;
    if (type == null || type.isEmpty) return const SizedBox.shrink();

    String displayType = type.toUpperCase();
    // Translate common types
    if (type.toLowerCase() == 'order' || type.toLowerCase() == 'order_status') {
      displayType = 'order_notification'.tr.toUpperCase();
    } else if (type.toLowerCase() == 'message') {
      displayType = 'message'.tr.toUpperCase();
    } else if (type.toLowerCase() == 'delivery') {
      displayType = 'delivery_notification'.tr.toUpperCase();
    } else if (type.toLowerCase() == 'payment') {
      displayType = 'payment_notification'.tr.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _getNotificationColor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getNotificationColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        displayType,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeSmall - 1,
          color: _getNotificationColor(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Handles notification action when user taps "View Order" button
  void _handleNotificationAction() {
    // Close dialog first
    Get.back();

    try {
      final bool hasOrderId = widget.payloadModel.orderId != null &&
          widget.payloadModel.orderId!.isNotEmpty &&
          widget.payloadModel.orderId != 'null' &&
          widget.payloadModel.orderId != '';

      if (hasOrderId) {
        // Navigate to order details
        final int? orderId = int.tryParse(widget.payloadModel.orderId!);
        if (orderId != null) {
          Get.toNamed(RouteHelper.getOrderDetailsRoute(orderId));
        }
      } else if (widget.payloadModel.type?.toLowerCase() == 'message') {
        // Navigate to chat
        Get.toNamed(RouteHelper.getChatRoute(notificationBody: null));
      } else {
        // Navigate to notifications list
        Get.toNamed(RouteHelper.getNotificationRoute());
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
      // Fallback to notification list
      Get.toNamed(RouteHelper.getNotificationRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOrderId = widget.payloadModel.orderId != null &&
        widget.payloadModel.orderId!.isNotEmpty &&
        widget.payloadModel.orderId != 'null' &&
        widget.payloadModel.orderId != '';

    final bool showViewButton =
        hasOrderId || widget.payloadModel.type?.toLowerCase() == 'message';

    final Color notificationColor = _getNotificationColor(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: notificationColor.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Header with Gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      notificationColor,
                      notificationColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Icon with better styling
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getNotificationIcon(),
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Notification Label
                    Expanded(
                      child: Text(
                        'notification'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Close Button - more subtle
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Get.back(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title with better spacing
                        _buildTranslatedTitle(context),
                        
                        // Order ID Badge - right after title if exists
                        if (hasOrderId) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: notificationColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: notificationColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 16,
                                  color: notificationColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'ID: ${widget.payloadModel.orderId}',
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: notificationColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Body text
                        _buildTranslatedBody(context),

                        // Notification Image (if available)
                        _buildNotificationImage(),

                        // Type Badge - more subtle
                        _buildTypeBadge(context),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // Modern Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Dismiss Button - more subtle
                    if (!showViewButton)
                      Expanded(
                        child: _buildDismissButton(context, notificationColor),
                      )
                    else ...[
                      Expanded(
                        child: _buildDismissButton(context, notificationColor),
                      ),
                      const SizedBox(width: 12),
                      // View Order Button - primary action
                      Expanded(
                        flex: 2,
                        child: _buildViewButton(
                          context,
                          notificationColor,
                          hasOrderId,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context, Color notificationColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              'dismiss'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewButton(
    BuildContext context,
    Color notificationColor,
    bool hasOrderId,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleNotificationAction,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                notificationColor,
                notificationColor.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: notificationColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasOrderId ? 'view_order'.tr : 'view_details'.tr,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
