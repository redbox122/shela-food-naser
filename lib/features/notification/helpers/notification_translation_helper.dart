import 'package:get/get.dart';

class NotificationTranslationHelper {
  /// Translates notification title and description by replacing static English text
  /// with translated equivalents while preserving dynamic content like order numbers
  static String translateNotificationTitle(String? originalTitle) {
    if (originalTitle == null || originalTitle.isEmpty) return '';

    String translated = originalTitle.trim();

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

    // Normalize ambiguous wallet-box title to clearer Arabic wording
    if (translated.contains('وأضاف الصندوق') ||
        translated.contains('اضاف الصندوق') ||
        translated.toLowerCase().contains('added box')) {
      translated = 'إضافة إلى المحفظة';
    }

    return translated;
  }

  static String translateNotificationDescription(String? originalDescription) {
    if (originalDescription == null || originalDescription.isEmpty) return '';

    String translated = originalDescription.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Dynamic patterns (order id/name) that old static replaceAll cannot handle reliably.
    // Example: "Order 232 is canceled by your request"
    final RegExp canceledOrderPattern =
        RegExp(r'Order\s+(\d+)\s+is\s+canceled\s+by\s+your\s+request', caseSensitive: false);
    translated = translated.replaceAllMapped(canceledOrderPattern, (m) {
      return 'تم إلغاء طلبك رقم ${m.group(1)} بناءً على طلبك';
    });

    // Example: "Your order 232 is successfully placed"
    final RegExp placedOrderPattern =
        RegExp(r'Your\s+order\s+(\d+)\s+is\s+successfully\s+placed', caseSensitive: false);
    translated = translated.replaceAllMapped(placedOrderPattern, (m) {
      return 'تم تقديم طلبك رقم ${m.group(1)} بنجاح';
    });

    // Example: "Gaber , Your order 232 is successfully placed"
    final RegExp placedOrderWithNamePattern = RegExp(
      r'([^,]+)\s*,\s*Your\s+order\s+(\d+)\s+is\s+successfully\s+placed',
      caseSensitive: false,
    );
    translated = translated.replaceAllMapped(placedOrderWithNamePattern, (m) {
      final String userName = (m.group(1) ?? '').trim();
      final String orderId = m.group(2) ?? '';
      return '$userName، تم تقديم طلبك رقم $orderId بنجاح';
    });

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

    // Keep wallet message clear and fully Arabic
    if (translated.contains('تمت إضافة الصندوق إلى محفظتك') ||
        translated.toLowerCase().contains('box added to your wallet')) {
      translated = 'تمت إضافة الصندوق إلى محفظتك';
    }

    return translated;
  }
}
