import 'dart:convert';
import 'package:flutter/foundation.dart';

/// JSON Isolate Helper
/// ⚡ PERFORMANCE: Moves heavy JSON encoding/decoding operations off the main thread
/// 
/// This utility prevents frame drops (jank) by running jsonDecode/jsonEncode in isolates.
/// Use this for:
/// - API response parsing (large payloads)
/// - Cache serialization/deserialization
/// - Any JSON operation on data > 10KB
/// 
/// Estimated Impact: Reduces 50-100ms main thread blocking per large JSON operation
class JsonIsolateHelper {
  /// Threshold in bytes above which we use isolate processing
  /// Below this threshold, the overhead of spawning an isolate is not worth it
  static const int _isolateThreshold = 10 * 1024; // 10KB

  // ============================================================
  // GENERIC JSON OPERATIONS
  // ============================================================

  /// Decode JSON string to Map in isolate (for large payloads)
  /// Falls back to main thread for small payloads to avoid isolate overhead
  static Future<Map<String, dynamic>> decodeJson(String jsonString) async {
    if (jsonString.length < _isolateThreshold) {
      // Small payload - decode on main thread (faster than isolate overhead)
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return await compute(_decodeJsonIsolate, jsonString);
  }

  static Map<String, dynamic> _decodeJsonIsolate(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Decode JSON string to List in isolate (for large payloads)
  static Future<List<dynamic>> decodeJsonList(String jsonString) async {
    if (jsonString.length < _isolateThreshold) {
      return jsonDecode(jsonString) as List<dynamic>;
    }
    return await compute(_decodeJsonListIsolate, jsonString);
  }

  static List<dynamic> _decodeJsonListIsolate(String jsonString) {
    return jsonDecode(jsonString) as List<dynamic>;
  }

  /// Encode Map to JSON string in isolate (for large payloads)
  static Future<String> encodeJson(Map<String, dynamic> data) async {
    // Estimate size based on number of entries (rough heuristic)
    if (data.length < 50) {
      return jsonEncode(data);
    }
    return await compute(_encodeJsonIsolate, data);
  }

  static String _encodeJsonIsolate(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Encode List to JSON string in isolate (for large payloads)
  static Future<String> encodeJsonList(List<dynamic> data) async {
    if (data.length < 50) {
      return jsonEncode(data);
    }
    return await compute(_encodeJsonListIsolate, data);
  }

  static String _encodeJsonListIsolate(List<dynamic> data) {
    return jsonEncode(data);
  }

  // ============================================================
  // API RESPONSE PARSING
  // ============================================================

  /// Parse API response body in isolate
  /// Use this in ApiClient.handleResponse for large responses
  static Future<dynamic> parseApiResponse(String responseBody) async {
    if (responseBody.length < _isolateThreshold) {
      try {
        return jsonDecode(responseBody);
      } catch (e) {
        return responseBody;
      }
    }
    return await compute(_parseApiResponseIsolate, responseBody);
  }

  static dynamic _parseApiResponseIsolate(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } catch (e) {
      return responseBody;
    }
  }

  // ============================================================
  // CACHE-SPECIFIC OPERATIONS
  // ============================================================

  /// Serialize banner data for caching
  static Future<String> serializeBannerData(Map<String, dynamic> bannerData) async {
    return await compute(_serializeBannerDataIsolate, bannerData);
  }

  static String _serializeBannerDataIsolate(Map<String, dynamic> bannerData) {
    return jsonEncode(bannerData);
  }

  /// Deserialize banner data from cache
  static Future<Map<String, dynamic>> deserializeBannerData(String jsonString) async {
    if (jsonString.length < _isolateThreshold) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return await compute(_deserializeBannerDataIsolate, jsonString);
  }

  static Map<String, dynamic> _deserializeBannerDataIsolate(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Serialize store data for caching
  static Future<String> serializeStoreData(Map<String, dynamic> storeData) async {
    return await compute(_serializeStoreDataIsolate, storeData);
  }

  static String _serializeStoreDataIsolate(Map<String, dynamic> storeData) {
    return jsonEncode(storeData);
  }

  /// Deserialize store data from cache
  static Future<Map<String, dynamic>> deserializeStoreData(String jsonString) async {
    if (jsonString.length < _isolateThreshold) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return await compute(_deserializeStoreDataIsolate, jsonString);
  }

  static Map<String, dynamic> _deserializeStoreDataIsolate(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Serialize offers data for caching
  static Future<String> serializeOffersData(Map<String, dynamic> offersData) async {
    return await compute(_serializeOffersDataIsolate, offersData);
  }

  static String _serializeOffersDataIsolate(Map<String, dynamic> offersData) {
    return jsonEncode(offersData);
  }

  /// Deserialize offers data from cache
  static Future<Map<String, dynamic>> deserializeOffersData(String jsonString) async {
    if (jsonString.length < _isolateThreshold) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return await compute(_deserializeOffersDataIsolate, jsonString);
  }

  static Map<String, dynamic> _deserializeOffersDataIsolate(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // ============================================================
  // BATCH OPERATIONS (for multiple items)
  // ============================================================

  /// Parse multiple JSON strings in parallel using isolates
  /// Useful when loading multiple cache entries at once
  static Future<List<Map<String, dynamic>>> parseMultipleJson(List<String> jsonStrings) async {
    if (jsonStrings.isEmpty) return [];
    
    // For small batches, process sequentially on main thread
    if (jsonStrings.length <= 3) {
      return jsonStrings.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    }

    return await compute(_parseMultipleJsonIsolate, jsonStrings);
  }

  static List<Map<String, dynamic>> _parseMultipleJsonIsolate(List<String> jsonStrings) {
    return jsonStrings.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  // ============================================================
  // UNIFIED ENDPOINT PARSING (BFF API v2)
  // ============================================================

  /// Parse unified home endpoint response in isolate
  /// 
  /// ⚡ PERFORMANCE: Any response larger than 65KB is parsed in background
  /// Prevents frame drops (jank) during splash-to-home transition
  /// 
  /// Usage:
  /// ```dart
  /// final jsonString = response.body.toString();
  /// final jsonMap = await JsonIsolateHelper.parseUnifiedPayload(jsonString);
  /// ```
  static Future<Map<String, dynamic>> parseUnifiedPayload(String jsonString) async {
    // Use 65KB threshold for unified endpoint (larger than standard 10KB)
    // Unified responses are typically 65KB+ and MUST be parsed in isolate
    const int unifiedThreshold = 65 * 1024; // 65KB
    
    if (jsonString.length < unifiedThreshold) {
      // Small payload - parse on main thread (faster than isolate overhead)
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    
    // Large payload - parse in isolate to prevent jank
    return await compute(_parseUnifiedPayloadIsolate, jsonString);
  }

  static Map<String, dynamic> _parseUnifiedPayloadIsolate(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}

