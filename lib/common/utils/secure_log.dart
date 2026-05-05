import 'package:flutter/foundation.dart';

/// Redacts secrets for logs. Never log full tokens in release or scan builds.
class SecureLog {
  SecureLog._();

  static const String _redacted = '[REDACTED]';

  /// Mask JWT-like tokens: first 8 + ... + last 4 (min length 16 to show both parts).
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) {
      return _redacted;
    }
    if (token == '@' || token == 'null') {
      return token;
    }
    final String t = token.trim();
    if (t.length <= 12) {
      return '${t.substring(0, t.length.clamp(0, 4))}…';
    }
    return '${t.substring(0, 8)}…${t.substring(t.length - 4)}';
  }

  /// Keep country code hint + last 4 digits when long enough.
  static String maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return _redacted;
    }
    final String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) {
      return '…$digits';
    }
    return '…${digits.substring(digits.length - 4)}';
  }

  /// Coerce dynamic header maps (e.g. Dio) then mask secrets.
  static Map<String, String> maskHeadersDynamic(Map<String, dynamic>? headers) {
    if (headers == null || headers.isEmpty) {
      return <String, String>{};
    }
    final Map<String, String> asString = <String, String>{};
    for (final MapEntry<String, dynamic> e in headers.entries) {
      asString[e.key] = e.value?.toString() ?? '';
    }
    return maskHeaders(asString);
  }

  /// Map of header keys to safe display values (Authorization → masked bearer).
  static Map<String, String> maskHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) {
      return <String, String>{};
    }
    final Map<String, String> out = <String, String>{};
    for (final MapEntry<String, String> e in headers.entries) {
      final String k = e.key;
      final String lower = k.toLowerCase();
      if (lower == 'authorization' || lower == 'cookie' || lower == 'set-cookie') {
        final String v = e.value;
        if (lower == 'authorization' && v.toLowerCase().startsWith('bearer ')) {
          final String raw = v.substring(7).trim();
          out[k] = 'Bearer ${maskToken(raw)}';
        } else {
          out[k] = _redacted;
        }
      } else {
        out[k] = e.value;
      }
    }
    return out;
  }

  static String headersForDebugLog(Map<String, String>? headers) {
    if (!kDebugMode) {
      return '[SECURE_LOG][MASKED_HEADERS] (disabled)';
    }
    final Map<String, String> masked = maskHeaders(headers);
    debugPrint('[SECURE_LOG][MASKED_HEADERS] keys=${masked.keys.join(",")}');
    return masked.toString();
  }

  static void logRedactedToken(String context) {
    if (kDebugMode) {
      debugPrint('[SECURE_LOG][REDACTED_TOKEN] $context');
    }
  }
}
