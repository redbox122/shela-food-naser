import 'package:get/get.dart';

/// Utility class for translating backend English messages to current locale
/// with automatic placeholder replacement support.
///
/// Usage:
/// ```dart
/// String translated = BackendMessageTranslator.translate(
///   'FCM token updated successfully!',
/// );
///
/// String withPlaceholders = BackendMessageTranslator.translate(
///   '{userName}, Your order {orderId} is successfully placed',
///   replacements: {'userName': 'John', 'orderId': '12345'},
/// );
/// ```
class BackendMessageTranslator {
  // Cache for mapping English messages to translation keys
  static final Map<String, String> _messageKeyCache = {};

  // Map of English messages to their translation keys
  static final Map<String, String> _messageToKeyMap = {
    // API Response Messages - Authentication & Account
    'FCM token updated successfully!': 'backend_fcm_token_updated',
    'Invalid FCM token provided. Token cannot be empty or placeholder.':
        'backend_invalid_fcm_token',
    'FCM token format appears invalid. Please ensure you are sending a valid Firebase Cloud Messaging token.':
        'backend_invalid_fcm_format',
    'OTP found, you can proceed': 'backend_otp_found',
    'Password changed successfully.': 'backend_password_changed',
    'User authenticated successfully.': 'backend_user_authenticated',
    'User authentication failed.': 'backend_user_auth_failed',
    'Nafath request not found.': 'backend_nafath_not_found',

    // API Response Messages - Order Management
    'Order accepted successfully': 'backend_order_accepted',
    'Status updated': 'backend_status_updated',

    // E-Commerce Module Notifications
    '{userName}, Your order {orderId} is successfully placed':
        'backend_order_pending_ecommerce',
    '{userName}, Your order {orderId} is confirmed':
        'backend_order_confirmed_ecommerce',
    '{userName}, Your order is Processing by {storeName}':
        'backend_order_processing_ecommerce',
    'Delivery man is on the way. For this order {orderId}':
        'backend_order_handover',
    'Order {orderId} Refunded successfully': 'backend_order_refunded',
    'Order {orderId} Refund request is canceled': 'backend_refund_canceled',
    '{userName}, Your order {orderId} is ready for delivery':
        'backend_out_for_delivery',
    'Your order {orderId} is delivered': 'backend_order_delivered',
    'Your order {orderId} has been assigned to a delivery man':
        'backend_delivery_assigned',
    'Order {orderId} delivered successfully': 'backend_delivery_completed',
    'Order {orderId} is canceled by your request': 'backend_order_canceled',

    // Food Module Notifications
    '{userName}, Your food is started for cooking by {storeName}':
        'backend_order_processing_food',

    // Parcel Module Notifications
    '{userName}, Your parcel order is successfully placed':
        'backend_order_pending_parcel',
    'Your parcel id {orderId} is delivered': 'backend_order_delivered_parcel',
    'parcel id {orderId} delivered successfully':
        'backend_delivery_completed_parcel',
    'parcel id {orderId} is canceled': 'backend_order_canceled_parcel',

    // Error Messages - Validation
    'The cm firebase token field is required.': 'backend_fcm_token_required',

    // Error Messages - Business Logic
    'digital_payment_is_disable': 'backend_digital_payment_disabled',
    'Customer not found': 'backend_customer_not_found',
    'Amount not found': 'backend_amount_not_found',
    'Payment not found': 'backend_payment_not_found',
    'Add your paymen ref first': 'add_payment_ref_first',
    'Add your payment ref first': 'add_payment_ref_first',
  };

  /// Translates a backend English message to the current locale.
  ///
  /// If [replacements] are provided, replaces all {placeholder} patterns
  /// with their corresponding values.
  ///
  /// Falls back to the original English message if no translation is found.
  static String translate(
    String englishMessage, {
    Map<String, String>? replacements,
  }) {
    if (englishMessage.isEmpty) return englishMessage;

    // Check cache first
    String? translationKey = _messageKeyCache[englishMessage];

    // If not in cache, look up in the map
    if (translationKey == null) {
      translationKey = _messageToKeyMap[englishMessage];
      if (translationKey != null) {
        _messageKeyCache[englishMessage] = translationKey;
      }
    }

    // Get translated message or fallback to original
    String translated =
        translationKey != null ? translationKey.tr : englishMessage;

    // If translation key doesn't exist in locale, GetX returns the key itself
    // In that case, use the original English message
    if (translated == translationKey) {
      translated = englishMessage;
    }

    // Replace placeholders if provided
    if (replacements != null && replacements.isNotEmpty) {
      translated = replaceAllPlaceholders(translated, replacements);
    }

    return translated;
  }

  /// Replaces all {placeholder} patterns in a message with provided values.
  ///
  /// Uses regex to find all patterns like {userName}, {orderId}, etc.
  /// If a placeholder value is not provided, keeps the placeholder as-is.
  static String replaceAllPlaceholders(
    String message,
    Map<String, String> values,
  ) {
    if (message.isEmpty || values.isEmpty) return message;

    // Pattern to match {placeholder}
    // ignore: deprecated_member_use
    final RegExp placeholderPattern = RegExp(r'\{(\w+)\}');

    return message.replaceAllMapped(placeholderPattern, (Match match) {
      final String placeholderName = match.group(1)!;
      // Return the value if exists, otherwise keep the placeholder
      return values[placeholderName] ?? match.group(0)!;
    });
  }

  /// Extracts placeholder data from notification payload.
  ///
  /// Common placeholder keys from backend:
  /// - userName, user_name
  /// - orderId, order_id
  /// - storeName, store_name
  static Map<String, String> extractPlaceholdersFromData(
    Map<String, dynamic> data,
  ) {
    final Map<String, String> placeholders = {};

    // Extract common placeholders with both snake_case and camelCase support
    if (data.containsKey('userName') || data.containsKey('user_name')) {
      placeholders['userName'] =
          data['userName']?.toString() ?? data['user_name']?.toString() ?? '';
    }

    if (data.containsKey('orderId') || data.containsKey('order_id')) {
      placeholders['orderId'] =
          data['orderId']?.toString() ?? data['order_id']?.toString() ?? '';
    }

    if (data.containsKey('storeName') || data.containsKey('store_name')) {
      placeholders['storeName'] =
          data['storeName']?.toString() ?? data['store_name']?.toString() ?? '';
    }

    // Also check for any key that might be used directly
    data.forEach((key, value) {
      if (value != null &&
          (key == 'name' ||
              key == 'title' ||
              key.endsWith('_name') ||
              key.endsWith('Name'))) {
        // Convert snake_case to camelCase if needed
        final String camelKey = key.replaceAllMapped(
          // ignore: deprecated_member_use
          RegExp(r'_([a-z])'),
          (match) => match.group(1)!.toUpperCase(),
        );
        placeholders[camelKey] = value.toString();
      }
    });

    return placeholders;
  }

  /// Clears the message key cache.
  /// Useful for testing or when translation files are updated.
  static void clearCache() {
    _messageKeyCache.clear();
  }
}
