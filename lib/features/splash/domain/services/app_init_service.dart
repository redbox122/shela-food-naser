
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/app_init_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/core/isolate/json_isolate_helper.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/utils/secure_log.dart';

/// Service for calling the app-init endpoint introduced by the backend team
/// This consolidates multiple startup API calls into a single request
class AppInitService {
  final ApiClient apiClient;

  AppInitService({required this.apiClient});

  /// Call the /api/v1/app-init endpoint to get all startup data
  /// Returns AppInitModel with config, modules, zones, and business settings
  ///
  /// With [gracefulFallback], returns null on error instead of throwing
  Future<AppInitModel?> getAppInitData({
    Map<String, String>? headers,
    bool gracefulFallback = true,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 AppInitService: Calling /api/v1/app-init endpoint');
        if (headers != null && headers.isNotEmpty) {
          debugPrint(
              '   - Headers (masked): ${SecureLog.maskHeaders(headers)}');
        }
        debugPrint(
            '   - Startup owner: ${headers?['X-Startup-Owner'] ?? 'unknown'} | no-retry: ${headers?['X-No-Retry'] ?? 'false'}');
        debugPrint(
            '   - Header readiness: zone=${headers?.containsKey('zoneId') == true}, lat=${headers?.containsKey('latitude') == true}, lng=${headers?.containsKey('longitude') == true}');
      }

      final Response response = await apiClient.getData(
        AppConstants.appInitUri,
        headers: headers,
      );

      if (kDebugMode) {
        debugPrint('📊 AppInitService: Response status: ${response.statusCode}');
      }

      // 🛠️ FIX 3: Handle 304 Not Modified as success (data hasn't changed)
      // 304 means data is unchanged - use local cache, do NOT trigger failure fallback
      if (response.statusCode == 304) {
        if (kDebugMode) {
          debugPrint(
              '✅ AppInitService: 304 LOGIC VERIFICATION - 304 Not Modified received');
          debugPrint('   - Status: ${response.statusCode}');
          debugPrint('   - This is a SUCCESS case, not an error');
          debugPrint(
              '   - SplashController will load ModuleModel from Hive app_config box');
        }
        // 304 is a success - data hasn't changed, continue using cached config
        // Return null to indicate no new data (but this is SUCCESS, not failure)
        // The caller (SplashController) will use cached data from Hive
        return null;
      }

      if (response.statusCode == 200) {
        // ⚡ PERFORMANCE: Parse JSON in isolate for large responses (>65KB)
        // This prevents frame drops (jank) during splash-to-home transition
        Map<String, dynamic> jsonData;
        if (response.body is String) {
          // Response is string - parse in isolate if large
          final parsed = await JsonIsolateHelper.parseUnifiedPayload(
              response.body as String);
          jsonData = parsed;
        } else if (response.body is Map<String, dynamic>) {
          // Response is already parsed
          jsonData = response.body as Map<String, dynamic>;
        } else if (response.body is Map) {
          // Response is already parsed but with dynamic keys
          jsonData =
              Map<String, dynamic>.from(response.body as Map<dynamic, dynamic>);
        } else {
          if (kDebugMode) {
            debugPrint(
                '⚠️ AppInitService: Unexpected response body type: ${response.body.runtimeType}');
          }
          return null;
        }

        final appInitModel = AppInitModel.fromJson(jsonData);

        if (kDebugMode) {
          debugPrint('✅ AppInitService: Successfully parsed app-init data');
          debugPrint('   - Config: ${appInitModel.config != null ? "✓" : "✗"}');
          debugPrint('   - Modules: ${appInitModel.modules?.length ?? 0}');
          debugPrint('   - Zones: ${appInitModel.zones?.length ?? 0}');
          debugPrint('   - User Zone ID: ${appInitModel.userZoneId}');
          debugPrint(
              '   - Business Settings: ${appInitModel.businessSettings != null ? "✓" : "✗"}');
        }

        return appInitModel;
      } else {
        // ⚡ ERROR UI: Handle 500 and other errors gracefully - fallback to Hive cache
        if (kDebugMode) {
          debugPrint(
              '⚠️ AppInitService: Non-200 status code: ${response.statusCode}');
          if (response.statusCode == 500) {
            debugPrint('   - ⚠️ ERROR UI: 500 Server Error detected');
            debugPrint(
                '   - Will fallback to Hive app_config box (no error dialog shown)');
          }
        }

        // ⚡ ERROR UI: Always use graceful fallback for 500 errors (don't throw)
        // This ensures app falls back to Hive cache instead of showing error dialog
        if (!gracefulFallback && response.statusCode != 500) {
          throw Exception('App-init endpoint returned ${response.statusCode}');
        }
        // For 500 errors or gracefulFallback=true, return null to trigger Hive cache fallback
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ AppInitService: Error calling app-init endpoint');
        debugPrint('   - Error: $e');
        debugPrint('   - Stack trace: $stackTrace');
        debugPrint(
            '   - ⚠️ ERROR UI: Will fallback to Hive app_config box (no error dialog shown)');
      }

      // ⚡ ERROR UI: Always use graceful fallback (don't throw) to prevent error dialogs
      // This ensures app falls back to Hive cache instead of showing "Server Error" dialog
      // Even if gracefulFallback=false, we still return null to trigger Hive fallback
      return null;
    }
  }

  /// Check if app-init endpoint is available (for graceful degradation)
  /// This can be used to test if the backend supports the new endpoint
  Future<bool> isAppInitAvailable() async {
    try {
      final Response response = await apiClient.getData(
        AppConstants.appInitUri,
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AppInitService: App-init endpoint not available: $e');
      }
      return false;
    }
  }
}
