import 'package:get/get.dart';

class NotificationTranslationHelper {
  /// Translates notification title and description by replacing static English text
  /// with translated equivalents while preserving dynamic content like order numbers
  static String translateNotificationTitle(String? originalTitle) {
    if (originalTitle == null || originalTitle.isEmpty) return '';

    String translated = originalTitle;

    // Map static English text to translation keys
    translated =
        translated.replaceAll('Order Notification', 'order_notification'.tr);
    translated = translated.replaceAll(
        'Payment Notification', 'payment_notification'.tr);
    translated = translated.replaceAll(
        'Delivery Notification', 'delivery_notification'.tr);
    translated = translated.replaceAll(
        'General Notification', 'general_notification'.tr);
    translated =
        translated.replaceAll('Update Available', 'update_available'.tr);

    return translated;
  }

  static String translateNotificationDescription(String? originalDescription) {
    if (originalDescription == null || originalDescription.isEmpty) return '';

    String translated = originalDescription;

    // Map static English text to translation keys while preserving dynamic content
    translated = translated.replaceAll('Your order', 'your_order'.tr);
    translated = translated.replaceAll(
        'is successfully placed', 'is_successfully_placed'.tr);
    translated =
        translated.replaceAll('is being prepared', 'is_being_prepared'.tr);
    translated =
        translated.replaceAll('is out for delivery', 'is_out_for_delivery'.tr);
    translated =
        translated.replaceAll('has been delivered', 'has_been_delivered'.tr);
    translated = translated.replaceAll(
        'payment has been received', 'payment_has_been_received'.tr);
    translated = translated.replaceAll(
        'order has been cancelled', 'order_has_been_cancelled'.tr);
    translated = translated.replaceAll('is ready', 'order_is_ready'.tr);
    translated =
        translated.replaceAll('is ready for pickup', 'order_is_ready'.tr);
    translated =
        translated.replaceAll('Order Ready', 'order_ready_notification'.tr);
    translated =
        translated.replaceAll('Update Available', 'update_available'.tr);
    translated = translated.replaceAll('Bug fixes', 'bug_fixes'.tr);

    return translated;
  }
}
