import 'dart:convert';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';

/// Tiny stale-while-revalidate helper for list/detail screens: read the last
/// response instantly (so a tab/screen paints without a shimmer), then let the
/// caller revalidate from the network and [write] the fresh payload back.
///
/// Backed by SharedPreferences (already held by [ApiClient]); values are raw
/// decoded JSON, so callers reuse their existing parsing.
class SimpleJsonCache {
  const SimpleJsonCache._();

  static ApiClient? get _api =>
      Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;

  /// Returns the cached JSON for [key] (already decoded), or null if absent /
  /// corrupt.
  static dynamic read(String key) {
    try {
      final s = _api?.sharedPreferences.getString(key);
      return s == null ? null : jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  /// Persists [data] (any JSON-encodable value) under [key]. Failures are
  /// swallowed — caching is best-effort and never blocks the UI.
  static Future<void> write(String key, dynamic data) async {
    try {
      await _api?.sharedPreferences.setString(key, jsonEncode(data));
    } catch (_) {/* non-fatal */}
  }
}
