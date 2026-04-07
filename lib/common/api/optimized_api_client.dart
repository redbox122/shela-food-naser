
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/api/api_call_manager.dart';
import 'package:sixam_mart/helper/address_helper.dart';

/// Optimized API client that extends the base ApiClient with call management
class OptimizedApiClient extends ApiClient {
  OptimizedApiClient({
    required super.appBaseUrl,
    required super.sharedPreferences,
  });

  /// Optimized GET request with deduplication and caching
  Future<Response<dynamic>> getDataOptimized(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool handleError = true,
    bool changeBaseUrl = false,
    Uri? newUri,
    Duration cacheDuration = const Duration(minutes: 5),
    bool enableCaching = true,
    bool enableDebouncing = true,
  }) async {
    // Generate unique call ID
    final callId = ApiCallManager.generateCallId(uri, query);

    // Ensure headers are valid
    ensureHeadersAreValid();

    return await ApiCallManager.instance.executeCall(
      callId,
      () => getData(
        uri,
        query: query,
        headers: headers,
        handleError: handleError,
        changeBaseUrl: changeBaseUrl,
        newUri: newUri,
      ),
      cacheDuration: cacheDuration,
      enableCaching: enableCaching,
      enableDebouncing: enableDebouncing,
    );
  }

  /// Optimized POST request with deduplication
  Future<Response<dynamic>> postDataOptimized(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    int? timeout,
    bool handleError = true,
    Duration debounceDuration = const Duration(milliseconds: 500),
    bool enableDebouncing = true,
  }) async {
    // Generate unique call ID for POST requests
    final callId = ApiCallManager.generateCallId(
        uri, body is Map ? Map<String, dynamic>.from(body) : null);

    // Ensure headers are valid
    ensureHeadersAreValid();

    return await ApiCallManager.instance.executeCall(
      callId,
      () => postData(
        uri,
        body,
        headers: headers,
        timeout: timeout,
        handleError: handleError,
      ),
      debounceDuration: debounceDuration,
      enableCaching: false, // Don't cache POST requests
      enableDebouncing: enableDebouncing,
    );
  }

  /// Batch multiple API calls efficiently
  Future<Map<String, Response<dynamic>>> batchGetCalls(
    Map<String, Map<String, dynamic>> calls, {
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final results = <String, Response<dynamic>>{};

    // Execute all calls concurrently
    final futures = calls.entries.map((entry) async {
      final response = await getDataOptimized(
        entry.key,
        query: entry.value,
        cacheDuration: cacheDuration,
      );
      return MapEntry(entry.key, response);
    });

    final responses = await Future.wait(futures);

    for (final entry in responses) {
      results[entry.key] = entry.value;
    }

    if (kDebugMode) {
      debugPrint('📦 Batch completed: ${results.length} calls');
    }

    return results;
  }

  /// Smart refresh that only reloads necessary data
  Future<void> smartRefresh({
    bool forceRefresh = false,
    List<String>? specificEndpoints,
  }) async {
    if (forceRefresh) {
      // Clear all cache for force refresh
      ApiCallManager.instance.clearCache();
    }

    // If specific endpoints provided, only clear those
    if (specificEndpoints != null) {
      for (final endpoint in specificEndpoints) {
        ApiCallManager.instance.clearCache(endpoint);
      }
    }

    if (kDebugMode) {
      debugPrint('🔄 Smart refresh completed');
    }
  }

  /// Get API performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return ApiCallManager.instance.getStatistics();
  }

  /// Preload critical data for better performance
  Future<void> preloadCriticalData() async {
    try {
      // Preload essential data that's always needed
      final criticalCalls = <String, Map<String, dynamic>>{
        '/api/v1/config/get-zone-id': <String, dynamic>{
          'lat': AddressHelper.getUserAddressFromSharedPref()?.latitude ??
              '24.604301879077966',
          'lng': AddressHelper.getUserAddressFromSharedPref()?.longitude ??
              '46.59593515098095',
        },
        '/api/v1/module': <String, dynamic>{},
        '/api/v1/banners': <String, dynamic>{},
      };

      await batchGetCalls(criticalCalls,
          cacheDuration: const Duration(minutes: 10));

      if (kDebugMode) {
        debugPrint('⚡ Critical data preloaded');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error preloading critical data: $e');
      }
    }
  }
}
