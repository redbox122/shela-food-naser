import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/bootstrap_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// ⚠️ DEPRECATED: This service is no longer used.
/// Bootstrap endpoint (/api/v1/bootstrap) has been replaced by:
/// - /api/v1/app-init (for startup config)
/// - /api/v2/home-unified (for home screen data)
///
/// Service for calling the bootstrap endpoint with ETag support
/// Consolidates all home screen data into a single API call
@Deprecated(
    'Use AppInitService for startup and HomeUnifiedService for home data')
class BootstrapService {
  final ApiClient apiClient;
  static const String _etagPrefix = 'etag_bootstrap_';

  BootstrapService({required this.apiClient});

  /// Get bootstrap data with ETag support for conditional requests
  ///
  /// Returns BootstrapModel if successful, null if failed or 304 Not Modified
  /// If 304 is returned, the cached data should be used
  Future<BootstrapModel?> getBootstrapData({
    bool forceRefresh = false,
    Map<String, String>? customHeaders,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 BootstrapService: Calling /api/v1/bootstrap endpoint');
      }

      // Get current module and zone for ETag key
      final splashController = Get.find<SplashController>();
      final moduleId = splashController.module?.id;
      List<int> zoneIds = [];
      final address = AddressHelper.getUserAddressFromSharedPref();
      if (address?.zoneIds != null) {
        zoneIds = address!.zoneIds!;
      }

      // Build ETag storage key
      final etagKey = _getEtagKey(moduleId, zoneIds);

      // Get stored ETag if not forcing refresh
      String? storedEtag;
      if (!forceRefresh) {
        final prefs = await SharedPreferences.getInstance();
        storedEtag = prefs.getString(etagKey);
        if (kDebugMode) {
          debugPrint(
              '📦 BootstrapService: Found stored ETag: ${storedEtag?.safeSubstring(20)}');
        }
      }

      // Prepare headers
      final headers = <String, String>{};
      if (customHeaders != null) {
        headers.addAll(customHeaders);
      }

      // Add If-None-Match header if we have a stored ETag
      if (storedEtag != null && !forceRefresh) {
        headers['If-None-Match'] = storedEtag;
        if (kDebugMode) {
          debugPrint(
              '📤 BootstrapService: Sending If-None-Match header for conditional request');
        }
      }

      // Make API call
      final response = await apiClient.getData(
        AppConstants.bootstrapUri,
        headers: headers,
      );

      if (kDebugMode) {
        debugPrint('📊 BootstrapService: Response status: ${response.statusCode}');
      }

      // Handle 304 Not Modified
      if (response.statusCode == 304) {
        if (kDebugMode) {
          debugPrint(
              '✅ BootstrapService: 304 Not Modified - data unchanged, use cached data');
        }
        // Return a special marker to indicate 304 (not an error)
        // We'll use a special BootstrapModel instance to indicate 304
        return BootstrapModel(); // Empty model with a flag
      }

      // Handle errors (404, 500, etc.)
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
              '❌ BootstrapService: Error response - status ${response.statusCode}');
        }
        return null; // Signal error - should fallback
      }

      // Handle successful response
      if (response.statusCode == 200 && response.body != null) {
        try {
          // Debug: Log response structure
          if (kDebugMode) {
            debugPrint(
                '🔍 BootstrapService: Response body type: ${response.body.runtimeType}');
            final body = response.body;

            if (body is Map) {
              final bodyMap = Map<String, dynamic>.from(body);

              debugPrint(
                  '🔍 BootstrapService: Response keys: ${bodyMap.keys.toList()}');
              if (bodyMap.containsKey('data')) {
                final data = bodyMap['data'];
                debugPrint('🔍 BootstrapService: Data type: ${data.runtimeType}');
                if (data is Map) {
                  final dataMap = Map<String, dynamic>.from(data);

                  debugPrint(
                      '🔍 BootstrapService: Data keys: ${dataMap.keys.toList()}');
                  // Check problematic fields
                  if (dataMap.containsKey('promotional_banners')) {
                    debugPrint(
                        '🔍 BootstrapService: promotional_banners type: ${dataMap['promotional_banners'].runtimeType}');
                  }
                  if (dataMap.containsKey('banners')) {
                    debugPrint(
                        '🔍 BootstrapService: banners type: ${dataMap['banners'].runtimeType}');
                  }
                }
              }
            }
          }

          final body = response.body;

          if (body is! Map) {
            throw Exception('Invalid bootstrap response body');
          }

          final bootstrapModel = BootstrapModel.fromJson(
            Map<String, dynamic>.from(body),
          );

          // Store ETag if available (would need to extract from response headers)
          // This will be handled by ApiClient ETag support

          if (kDebugMode) {
            debugPrint('✅ BootstrapService: Successfully parsed bootstrap data');
            debugPrint(
                '   - Business Settings: ${bootstrapModel.businessSettings != null ? "✓" : "✗"}');
            debugPrint(
                '   - Banners: ${bootstrapModel.banners != null ? "✓" : "✗"}');
            debugPrint(
                '   - Promotional Banners: ${bootstrapModel.promotionalBanners != null ? "✓" : "✗"}');
            debugPrint('   - Categories: ${bootstrapModel.categories?.length ?? 0}');
            debugPrint(
                '   - Stores Popular: ${bootstrapModel.storesPopular?.stores?.length ?? 0}');
            debugPrint('   - Stores: ${bootstrapModel.stores?.stores?.length ?? 0}');
            debugPrint('   - Brands: ${bootstrapModel.brands?.length ?? 0}');
            debugPrint('   - Offers: ${bootstrapModel.offers?.data.length ?? 0}');
            if (bootstrapModel.meta != null) {
              debugPrint('   - Cache Hit: ${bootstrapModel.meta!.cacheHit}');
              debugPrint(
                  '   - Response Time: ${bootstrapModel.meta!.responseTimeMs}ms');
            }
          }

          return bootstrapModel;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ BootstrapService: Error parsing bootstrap response');
            debugPrint('   - Error: $e');
            debugPrint('   - Error Type: ${e.runtimeType}');
            debugPrint('   - Stack trace: $stackTrace');
            // Log response structure for debugging
            final body = response.body;

            if (body is Map) {
              final bodyMap = Map<String, dynamic>.from(body);
              debugPrint('   - Response structure: ${bodyMap.keys.toList()}');
              if (bodyMap.containsKey('data')) {
                final data = bodyMap['data'];
                debugPrint('   - Data type: ${data.runtimeType}');
                if (data is Map) {
                  final dataMap = Map<String, dynamic>.from(data);
                  debugPrint('   - Data keys: ${dataMap.keys.toList()}');
                } else if (data is List) {
                  debugPrint('   - Data is a List with ${(data).length} items');
                }
              }
            }
          }
          rethrow;
        }
      }

      if (kDebugMode) {
        debugPrint(
            '⚠️ BootstrapService: Non-200 status code: ${response.statusCode}');
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ BootstrapService: Error calling bootstrap endpoint');
        debugPrint('   - Error: $e');
        debugPrint('   - Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Store ETag for a specific module+zone combination
  Future<void> storeEtag(int? moduleId, List<int> zoneIds, String etag) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final etagKey = _getEtagKey(moduleId, zoneIds);
      await prefs.setString(etagKey, etag);
      if (kDebugMode) {
        debugPrint(
            '💾 BootstrapService: Stored ETag for module $moduleId, zones $zoneIds');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BootstrapService: Error storing ETag: $e');
      }
    }
  }

  /// Clear stored ETag for a specific module+zone combination
  Future<void> clearEtag(int? moduleId, List<int> zoneIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final etagKey = _getEtagKey(moduleId, zoneIds);
      await prefs.remove(etagKey);
      if (kDebugMode) {
        debugPrint(
            '🗑️ BootstrapService: Cleared ETag for module $moduleId, zones $zoneIds');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BootstrapService: Error clearing ETag: $e');
      }
    }
  }

  /// Clear all stored ETags (useful when module/zone changes)
  Future<void> clearAllEtags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_etagPrefix)) {
          await prefs.remove(key);
        }
      }
      if (kDebugMode) {
        debugPrint('🗑️ BootstrapService: Cleared all stored ETags');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BootstrapService: Error clearing all ETags: $e');
      }
    }
  }

  /// Get ETag storage key for module+zone combination
  String _getEtagKey(int? moduleId, List<int> zoneIds) {
    final zoneIdsStr = zoneIds.join(',');
    return '$_etagPrefix${moduleId ?? 'no_module'}_$zoneIdsStr';
  }

  /// Check if bootstrap endpoint is available (for graceful degradation)
  Future<bool> isBootstrapAvailable() async {
    try {
      final response = await apiClient.getData(
        AppConstants.bootstrapUri,
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200 || response.statusCode == 304;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ BootstrapService: Bootstrap endpoint not available: $e');
      }
      return false;
    }
  }
}
