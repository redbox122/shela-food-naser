// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/app_init_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/core/isolate/json_isolate_helper.dart';
import 'package:get/get.dart';

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
        print('🚀 AppInitService: Calling /api/v1/app-init endpoint');
        print('   - Headers: $headers');
      }

      final Response response = await apiClient.getData(
        AppConstants.appInitUri,
        headers: headers,
      );

      if (kDebugMode) {
        print('📊 AppInitService: Response status: ${response.statusCode}');
      }

      // 🛠️ FIX 3: Handle 304 Not Modified as success (data hasn't changed)
      // 304 means data is unchanged - use local cache, do NOT trigger failure fallback
      if (response.statusCode == 304) {
        if (kDebugMode) {
          print('✅ AppInitService: 304 LOGIC VERIFICATION - 304 Not Modified received');
          print('   - Status: ${response.statusCode}');
          print('   - This is a SUCCESS case, not an error');
          print('   - SplashController will load ModuleModel from Hive app_config box');
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
          final parsed = await JsonIsolateHelper.parseUnifiedPayload(response.body as String);
          jsonData = parsed;
        } else if (response.body is Map<String, dynamic>) {
          // Response is already parsed
          jsonData = response.body as Map<String, dynamic>;
        } else if (response.body is Map) {
          // Response is already parsed but with dynamic keys
          jsonData = Map<String, dynamic>.from(response.body as Map<dynamic, dynamic>);
        } else {
          if (kDebugMode) {
            print('⚠️ AppInitService: Unexpected response body type: ${response.body.runtimeType}');
          }
          return null;
        }
        
        final appInitModel = AppInitModel.fromJson(jsonData);
        
        if (kDebugMode) {
          print('✅ AppInitService: Successfully parsed app-init data');
          print('   - Config: ${appInitModel.config != null ? "✓" : "✗"}');
          print('   - Modules: ${appInitModel.modules?.length ?? 0}');
          print('   - Zones: ${appInitModel.zones?.length ?? 0}');
          print('   - User Zone ID: ${appInitModel.userZoneId}');
          print('   - Business Settings: ${appInitModel.businessSettings != null ? "✓" : "✗"}');
        }

        return appInitModel;
      } else {
        // ⚡ ERROR UI: Handle 500 and other errors gracefully - fallback to Hive cache
        if (kDebugMode) {
          print('⚠️ AppInitService: Non-200 status code: ${response.statusCode}');
          if (response.statusCode == 500) {
            print('   - ⚠️ ERROR UI: 500 Server Error detected');
            print('   - Will fallback to Hive app_config box (no error dialog shown)');
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
        print('❌ AppInitService: Error calling app-init endpoint');
        print('   - Error: $e');
        print('   - Stack trace: $stackTrace');
        print('   - ⚠️ ERROR UI: Will fallback to Hive app_config box (no error dialog shown)');
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
        print('⚠️ AppInitService: App-init endpoint not available: $e');
      }
      return false;
    }
  }
}
