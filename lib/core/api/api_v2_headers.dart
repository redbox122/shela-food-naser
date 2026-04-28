import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

/// API v2 Headers Utility
/// 
/// ⚡ BFF API v2: Generates required headers for all v2 endpoints
/// 
/// Required Headers:
/// - `zoneId`: JSON array of zone IDs (e.g., "[2,4,3,5]")
/// - `moduleId`: Module ID (3=grocery, 6=food, 7=pharmacy)
/// - `latitude`: User latitude (optional, for distance calculation)
/// - `longitude`: User longitude (optional, for distance calculation)
/// - `X-Store-Version-Hash`: Store hash for conditional requests (future)
/// - `Accept-Language`: Language preference (ar or en)
class ApiV2Headers {
  /// Get headers for BFF v2 endpoints
  /// 
  /// [zoneIds] - Optional zone IDs (will use user address if not provided)
  /// [moduleId] - Optional module ID (will use current module if not provided)
  /// [latitude] - Optional latitude (will use user address if not provided)
  /// [longitude] - Optional longitude (will use user address if not provided)
  /// [storeVersionHash] - Optional store hash for conditional requests
  /// [languageCode] - Optional language code (defaults to 'ar')
  static Map<String, String> getHeaders({
    List<int>? zoneIds,
    int? moduleId,
    double? latitude,
    double? longitude,
    String? storeVersionHash,
    String? languageCode,
  }) {
    // Get user address for zone and location data
    final AddressModel? addressModel = AddressHelper.getUserAddressFromSharedPref();
    
    // Resolve zone IDs: explicit param → SharedPrefs address → ApiClient headers (Hive fallback)
    List<int> resolvedZoneIds = zoneIds?.isNotEmpty == true
        ? zoneIds!
        : (addressModel?.zoneIds?.isNotEmpty == true
            ? addressModel!.zoneIds!
            : _getZoneIdsFromApiClientHeaders());
    if (resolvedZoneIds.isEmpty && kDebugMode) {
      appLogger.warning('⚠️ ApiV2Headers: No zone IDs found - backend will reject');
    }
    
    // Resolve module ID
    final int? resolvedModuleId = moduleId ?? ModuleHelper.getModule()?.id;
    
    // Resolve coordinates
    final String? resolvedLatitude =
        latitude?.toString() ?? addressModel?.latitude;
    final String? resolvedLongitude =
        longitude?.toString() ?? addressModel?.longitude;
    
    // Build headers map
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      AppConstants.zoneId: jsonEncode(resolvedZoneIds),
      AppConstants.localizationKey: languageCode ?? 'ar',
    };
    if (resolvedLatitude != null && resolvedLongitude != null) {
      headers[AppConstants.latitude] = resolvedLatitude;
      headers[AppConstants.longitude] = resolvedLongitude;
    }
    
    // Add module ID if available
    if (resolvedModuleId != null) {
      headers[AppConstants.moduleId] = resolvedModuleId.toString();
    }
    
    // Add store version hash for conditional requests (future feature)
    if (storeVersionHash != null && storeVersionHash.isNotEmpty) {
      headers['X-Store-Version-Hash'] = storeVersionHash;
    }
    
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      appLogger.debug('🔧 ApiV2Headers: Generated headers');
      appLogger.debug('   zoneId: ${headers[AppConstants.zoneId]}');
      appLogger.debug('   moduleId: ${headers[AppConstants.moduleId]}');
      appLogger.debug('   latitude: ${headers[AppConstants.latitude]}');
      appLogger.debug('   longitude: ${headers[AppConstants.longitude]}');
    }
    
    return headers;
  }

  /// Get headers for home-unified endpoint
  /// 
  /// Convenience method specifically for /api/v2/home-unified
  static Map<String, String> getHomeUnifiedHeaders({
    List<int>? zoneIds,
    int? moduleId,
    double? latitude,
    double? longitude,
    String? languageCode,
  }) {
    return getHeaders(
      zoneIds: zoneIds,
      moduleId: moduleId,
      latitude: latitude,
      longitude: longitude,
      languageCode: languageCode,
    );
  }

  /// Get headers for checkout/store-summary endpoint
  /// 
  /// Includes store version hash for cache validation
  static Map<String, String> getStoreSummaryHeaders({
    required int storeId,
    String? storeVersionHash,
    List<int>? zoneIds,
    int? moduleId,
    String? languageCode,
  }) {
    return getHeaders(
      zoneIds: zoneIds,
      moduleId: moduleId,
      storeVersionHash: storeVersionHash,
      languageCode: languageCode,
    );
  }

  /// Fallback: read zone IDs from ApiClient headers (injected from Hive cache)
  static List<int> _getZoneIdsFromApiClientHeaders() {
    try {
      if (Get.isRegistered<ApiClient>()) {
        final zoneHeader = Get.find<ApiClient>().getHeader()[AppConstants.zoneId];
        if (zoneHeader != null && zoneHeader.isNotEmpty) {
          final decoded = jsonDecode(zoneHeader);
          if (decoded is List && decoded.isNotEmpty) {
            return decoded.map((e) => e as int).toList();
          }
        }
      }
    } catch (_) {}
    return <int>[];
  }

  /// Validate if headers are complete for v2 endpoints
  /// 
  /// Returns true if all required headers are present and valid
  static bool validateHeaders(Map<String, String> headers) {
    // Check required headers
    if (!headers.containsKey(AppConstants.zoneId)) {
      if (kDebugMode) {
        appLogger.error('❌ ApiV2Headers: Missing zoneId header');
      }
      return false;
    }
    
    if (!headers.containsKey(AppConstants.moduleId)) {
      if (kDebugMode) {
        appLogger.error('❌ ApiV2Headers: Missing moduleId header');
      }
      return false;
    }
    
    // Validate zone ID format (should be JSON array)
    try {
      final zoneId = headers[AppConstants.zoneId]!;
      final decoded = jsonDecode(zoneId);
      if (decoded is! List || decoded.isEmpty) {
        if (kDebugMode) {
          appLogger.error('❌ ApiV2Headers: Invalid zoneId format: $zoneId');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('❌ ApiV2Headers: Failed to parse zoneId: $e', e);
      }
      return false;
    }
    
    return true;
  }
}

