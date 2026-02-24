import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/hive_cache_config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sixam_mart/features/location/domain/models/delivery_man_last_location.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/domain/repositories/location_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class LocationRepository implements LocationRepositoryInterface {
  final ApiClient apiClient;

  // Zone cache constants
  static const String _zoneCacheKey = 'cached_zone_data';
  static const String _zoneCacheTimeKey = 'cached_zone_timestamp';
  static final int _zoneCacheTTL =
      HiveCacheConfig.zoneTTL.inMilliseconds; // 24h by config
  
  // Cache key for getAllZones (all zones list)
  static const String _allZonesCacheKey = 'cached_all_zones_data';
  static const String _allZonesCacheTimeKey = 'cached_all_zones_timestamp';

  LocationRepository({required this.apiClient});

  /// Clear zone cache (call when address changes or to clear old cached zones without polygons)
  static Future<void> clearZoneCache() async {
    try {
      // Clear SharedPreferences cache
      final prefs = Get.find<SharedPreferences>();
      await prefs.remove(_zoneCacheKey);
      await prefs.remove(_zoneCacheTimeKey);
      await prefs.remove(_allZonesCacheKey);
      await prefs.remove(_allZonesCacheTimeKey);
      debugPrint('🗑️ Zone cache cleared from SharedPreferences');
      
      // Clear Hive cache
      try {
        final box = await Hive.openLazyBox<String>(HiveCacheConfig.zoneCacheBoxName);
        await box.clear();
        await box.close();
        debugPrint('🗑️ Zone cache cleared from Hive');
      } catch (e) {
        debugPrint('⚠️ Error clearing Hive zone cache: $e');
      }
    } catch (e) {
      debugPrint('❌ Error clearing zone cache: $e');
    }
  }

  /// Clean up address by removing redundant parts like "الرياض" (Riyadh)
  String _cleanAddress(String address) {
    if (address.isEmpty) return address;

    // Remove redundant "الرياض" (Riyadh) from the end
    String cleanedAddress = address;

    // Remove "، الرياض" (comma + Riyadh) from the end
    if (cleanedAddress.endsWith('، الرياض')) {
      cleanedAddress = cleanedAddress.substring(0, cleanedAddress.length - 7);
    }

    // Remove "الرياض" (Riyadh) from the end
    if (cleanedAddress.endsWith('الرياض')) {
      cleanedAddress = cleanedAddress.substring(0, cleanedAddress.length - 5);
    }

    // Remove "، السعودية" (comma + Saudi Arabia) from the end
    if (cleanedAddress.endsWith('، السعودية')) {
      cleanedAddress = cleanedAddress.substring(0, cleanedAddress.length - 9);
    }

    // Remove "السعودية" (Saudi Arabia) from the end
    if (cleanedAddress.endsWith('السعودية')) {
      cleanedAddress = cleanedAddress.substring(0, cleanedAddress.length - 7);
    }

    // Clean up any trailing commas or spaces
    cleanedAddress = cleanedAddress.trim();
    if (cleanedAddress.endsWith(',')) {
      cleanedAddress =
          cleanedAddress.substring(0, cleanedAddress.length - 1).trim();
    }

    return cleanedAddress;
  }

  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    try {
      final Response response = await apiClient.getData(
          '${AppConstants.geocodeUri}?lat=${latLng.latitude}&lng=${latLng.longitude}',
          handleError: false);
      String address = 'Unknown Location Found';

      // Add null safety and proper response validation
      if (response.statusCode == 200 && response.body != null) {
        // Handle different response structures
        if (response.body is Map) {
          final Map<String, dynamic> responseBody =
              Map<String, dynamic>.from(response.body as Map);

          // Check for Google Maps API response structure
          if (responseBody.containsKey('status') &&
              responseBody['status'] == 'OK') {
            if (responseBody.containsKey('results') &&
                responseBody['results'] is List) {
              final List results = responseBody['results'] as List;
              if (results.isNotEmpty && results[0] is Map) {
                final Map firstResult = results[0] as Map;
                address = firstResult['formatted_address']?.toString() ??
                    'Unknown Location Found';
              }
            }
          }
          // Check for alternative response structure (without 'status' field)
          else if (responseBody.containsKey('results') &&
              responseBody['results'] is List) {
            final List results = responseBody['results'] as List;
            if (results.isNotEmpty && results[0] is Map) {
              final Map firstResult = results[0] as Map;
              address = firstResult['formatted_address']?.toString() ??
                  'Unknown Location Found';
            }
          }
          // Check for error messages
          else if (responseBody.containsKey('error_message')) {
            address = 'Error: ${responseBody['error_message']}';
          }
        }

        // Clean up the address by removing redundant parts
        address = _cleanAddress(address);

        debugPrint(
            '\x1B[32m  getAddressFromGeocode /////////////   $address  \x1B[0m');
      } else {
        // 🔥 UX FIX: Don't show error for geocoding failures
        // Geocoding is just address lookup - not critical location failure
        // The location itself might be valid even if geocoding fails
        // User can still proceed and choose location manually from map
        debugPrint('⚠️ getAddressFromGeocode: Geocoding API returned error - using fallback address');
        debugPrint('   → This is not a critical failure - user can still choose location from map');
        // No error snackbar - geocoding is optional, location selection is not blocked
      }

      return address;
    } catch (e) {
      debugPrint('\x1B[31m  getAddressFromGeocode Error: $e  \x1B[0m');
      // 🔥 FIX: Don't show error snackbar here - let caller handle it
      // This is just geocoding (address lookup), not critical location failure
      // The location itself might be valid even if geocoding fails
      debugPrint('⚠️ getAddressFromGeocode: Geocoding failed, returning fallback address');
      return 'Unknown Location Found';
    }
  }

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng,
      {bool handleError = false}) async {
    try {
      // Generate cache key from coordinates
      final cacheKey = '$lat,$lng';
      final prefs = Get.find<SharedPreferences>();

      // Check cache first
      final cachedData = prefs.getString(_zoneCacheKey);
      final cachedTime = prefs.getInt(_zoneCacheTimeKey);
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (cachedData != null && cachedTime != null) {
        final cacheAge = currentTime - cachedTime;
        if (cacheAge < _zoneCacheTTL) {
          try {
            final Map<String, dynamic> cached = jsonDecode(cachedData) as Map<String, dynamic>;
            if (cached['key'] == cacheKey) {
              debugPrint(
                  '✅ Zone cache HIT (age: ${(cacheAge / 1000 / 60).toStringAsFixed(1)}min)');
              final zoneModel = ZoneModel.fromJson(cached['data'] as Map<String, dynamic>);
              // Extract metadata from cached data if available
              Map<String, dynamic>? metadata;
              if (cached.containsKey('metadata') && cached['metadata'] != null) {
                metadata = cached['metadata'] as Map<String, dynamic>;
              }
              
              return ZoneResponseModel(true, '', zoneModel.zoneIds ?? [],
                  zoneModel.zoneData ?? [], [], 200, metadata);
            }
          } catch (e) {
            debugPrint('⚠️ Zone cache parse error: $e');
            // Continue to API call if cache fails
          }
        } else {
          debugPrint(
              '🕐 Zone cache EXPIRED (age: ${(cacheAge / 1000 / 60).toStringAsFixed(1)}min)');
        }
      }

      debugPrint('🌐 Zone cache MISS - calling API');

      // Make API call
      final Response response = await apiClient.getData(
          '${AppConstants.zoneUri}?lat=$lat&lng=$lng',
          handleError: handleError);

      if (response.statusCode == 200 && response.body != null) {
        // Cache the response
        try {
          final cacheData = {
            'key': cacheKey,
            'data': response.body,
          };
          await prefs.setString(_zoneCacheKey, jsonEncode(cacheData));
          await prefs.setInt(_zoneCacheTimeKey, currentTime);
          debugPrint('💾 Zone data cached for $cacheKey');
        } catch (e) {
          debugPrint('⚠️ Failed to cache zone data: $e');
        }

        ZoneResponseModel responseModel;
        final responseBody = response.body as Map<String, dynamic>;
        final zoneModel = ZoneModel.fromJson(responseBody);
        final List<int>? zoneIds = zoneModel.zoneIds;
        final List<ZoneData>? zoneData = zoneModel.zoneData;
        
        // 🔥 Extract metadata if available (Backend guidance for Flutter)
        Map<String, dynamic>? metadata;
        if (responseBody.containsKey('metadata') && responseBody['metadata'] != null) {
          metadata = responseBody['metadata'] as Map<String, dynamic>;
          debugPrint('📋 ZoneResponse metadata received: $metadata');
        }
        
        responseModel = ZoneResponseModel(
            true, '', zoneIds ?? [], zoneData ?? [], [], response.statusCode, metadata);
        
        // ⚡ TASK 1: Save zone ID and coordinates to Hive session_config box
        if (responseModel.isSuccess && zoneIds != null && zoneIds.isNotEmpty && lat != null && lng != null) {
          try {
            await HiveHomeCacheService().saveLastKnownZone(
              zoneId: zoneIds[0],
              latitude: lat,
              longitude: lng,
            );
            if (kDebugMode) {
              debugPrint('💾 LocationRepository: Saved zone ID ${zoneIds[0]} to Hive session_config');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ LocationRepository: Error saving zone to Hive - $e');
            }
            // Don't throw - continue even if cache save fails
          }
        }
        
        return responseModel;
      } else {
        // 🔥 Extract metadata from error response if available
        Map<String, dynamic>? metadata;
        try {
          if (response.body != null && response.body is Map<String, dynamic>) {
            final responseBody = response.body as Map<String, dynamic>;
            if (responseBody.containsKey('metadata') && responseBody['metadata'] != null) {
              metadata = responseBody['metadata'] as Map<String, dynamic>;
              debugPrint('📋 ZoneResponse metadata (error): $metadata');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Failed to parse metadata from error response: $e');
        }
        
        return ZoneResponseModel(false, response.statusText ?? 'Request failed',
            [], [], [], response.statusCode, metadata);
      }
    } catch (e) {
      debugPrint('\x1B[31m  getZone Error: $e  \x1B[0m');
      return ZoneResponseModel(false, 'Error: $e', [], [], [], 0, null);
    }
  }

  @override
  Future<Response> searchLocation(String text) async {
    try {
      return await apiClient
          .getData('${AppConstants.searchLocationUri}?search_text=$text');
    } catch (e) {
      debugPrint('\x1B[31m  searchLocation Error: $e  \x1B[0m');
      return Response(statusCode: 0, statusText: 'Search failed: $e');
    }
  }

  @override
  Future<LocationDeliveryModel> Location_Delivery_man(String orderID) async {
    try {
      final Response response =
          await apiClient.getData('${AppConstants.lastLocationUri}$orderID');

      if (response.statusCode == 200 && response.body != null) {
        debugPrint('\x1B[32m  /${response.statusCode}  \x1B[0m');
        return LocationDeliveryModel.fromJson(response.body as Map<String, dynamic>);
      } else {
        throw Exception(
            'فشل في جلب موقع رجل التوصيل: ${response.statusText ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('\x1B[31m  Location_Delivery_man Error: $e  \x1B[0m');
      rethrow;
    }
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Response> get(String? id) async {
    try {
      final Response response = await apiClient
          .getData('${AppConstants.placeDetailsUri}?placeid=$id');
      return response;
    } catch (e) {
      debugPrint('\x1B[31m  get place details Error: $e  \x1B[0m');
      return Response(
          statusCode: 0, statusText: 'Failed to get place details: $e');
    }
  }

  @override
  Future<List<ZoneDataModel>> getAllZones() async {
    try {
      // 🔥 CRITICAL FIX: Force fresh API call for zones (no 304 caching)
      // Zones are critical business logic - must always fetch fresh data
      // Adding cache-busting headers to prevent 304 responses
      final Response response = await apiClient.getData(
        '${AppConstants.allZonesUri}?_t=${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // 🔥 CRITICAL FIX: Zones MUST come from /api/v1/zone/list with formated_coordinates
      // ❌ app-init cache does NOT have formated_coordinates - cannot use it for polygons
      // ✅ Only use SharedPreferences cache if it has formated_coordinates
      if (response.statusCode == 304) {
        debugPrint(
            '\x1B[33m  getAllZones: 304 Not Modified - checking cache for zones with coordinates  \x1B[0m');
        
        // 🔥 FIX 1: DO NOT use app-init cache for zones (it doesn't have formated_coordinates)
        // app-init cache only has zone IDs, not polygon coordinates
        debugPrint('⏭️ Skipping app-init cache - zones need formated_coordinates from API');
        
        // 🔥 FIX 2: Only use SharedPreferences cache if it has zones with formated_coordinates
        try {
          final prefs = Get.find<SharedPreferences>();
          final cachedData = prefs.getString(_allZonesCacheKey);
          final cachedTime = prefs.getInt(_allZonesCacheTimeKey);
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          
          if (cachedData != null && cachedTime != null) {
            final cacheAge = currentTime - cachedTime;
            if (cacheAge < _zoneCacheTTL) {
              try {
                final List<dynamic> cachedZonesJson = jsonDecode(cachedData) as List<dynamic>;
                final List<ZoneDataModel> cachedZones = [];
                int zonesWithCoords = 0;
                
                for (var zoneJson in cachedZonesJson) {
                  final zone = ZoneDataModel.fromJson(zoneJson as Map<String, dynamic>);
                  cachedZones.add(zone);
                  
                  // Check if this cached zone has formated_coordinates
                  if (zone.formatedCoordinates != null && zone.formatedCoordinates!.isNotEmpty) {
                    zonesWithCoords++;
                  }
                }
                
                // 🔥 CRITICAL: Only return cached zones if they have formated_coordinates
                if (cachedZones.isNotEmpty && zonesWithCoords > 0) {
                  debugPrint(
                      '\x1B[32m  getAllZones: Loaded ${cachedZones.length} zones from SharedPreferences cache (304) - $zonesWithCoords with coordinates - age: ${(cacheAge / 1000 / 60).toStringAsFixed(1)}min  \x1B[0m');
                  return cachedZones;
                } else {
                  debugPrint(
                      '\x1B[33m  getAllZones: Cached zones exist but NONE have formated_coordinates - forcing API call  \x1B[0m');
                  // Fall through to force API call
                }
              } catch (e) {
                debugPrint('⚠️ Error parsing cached zones from SharedPreferences: $e');
              }
            } else {
              debugPrint('🕐 Cached zones expired (age: ${(cacheAge / 1000 / 60).toStringAsFixed(1)}min)');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error loading zones from SharedPreferences cache after 304: $e');
        }
        
        // 🔥 FIX 3: If cache doesn't have formated_coordinates, force API call by returning empty
        // This will trigger a fresh API call in the controller
        debugPrint(
            '\x1B[33m  getAllZones: 304 but cache missing formated_coordinates - returning empty to force API call  \x1B[0m');
        return [];
      }
      
      if (response.statusCode == 200 && response.body != null) {
        // 🔥 DEBUG: Print raw response to diagnose parsing issues
        debugPrint('🔍 RAW ZONES RESPONSE => ${jsonEncode(response.body)}');
        
        final List<ZoneDataModel> zones = [];
        int zonesWithCoordinates = 0;
        int zonesWithoutCoordinates = 0;

        // Handle both response formats: direct array or wrapped in 'zones' object
        if (response.body is List) {
          // Direct array response: [{id: 1, name: "Zone"...}, ...]
          for (var v in (response.body as List)) {
            if (v is Map<String, dynamic>) {
              // 🔥 DEBUG: Print each zone raw data
              debugPrint('🔍 RAW ZONE => ${jsonEncode(v)}');
              final zone = ZoneDataModel.fromJson(v);
              final hasCoordinates = zone.formatedCoordinates != null && zone.formatedCoordinates!.isNotEmpty;
              if (hasCoordinates) {
                zonesWithCoordinates++;
                debugPrint('✅ PARSED ZONE => id: ${zone.id}, name: ${zone.name}, formatedCoordinates: ${zone.formatedCoordinates!.length} points');
              } else {
                zonesWithoutCoordinates++;
                debugPrint('⚠️ PARSED ZONE => id: ${zone.id}, name: ${zone.name}, ❌ NO formatedCoordinates (polygon will not render)');
                debugPrint('   → Backend must return formated_coordinates array for polygon rendering');
                debugPrint('   → Zone validation will still work via get-zone-id endpoint');
              }
              zones.add(zone);
            }
          }
        } else if (response.body is Map && (response.body as Map)['zones'] != null) {
          // Wrapped response: {zones: [{id: 1, name: "Zone"...}, ...]}
          final zonesList = (response.body as Map)['zones'];
          if (zonesList is List) {
            for (var v in zonesList) {
              if (v is Map<String, dynamic>) {
                // 🔥 DEBUG: Print each zone raw data
                debugPrint('🔍 RAW ZONE => ${jsonEncode(v)}');
                final zone = ZoneDataModel.fromJson(v);
                final hasCoordinates = zone.formatedCoordinates != null && zone.formatedCoordinates!.isNotEmpty;
                if (hasCoordinates) {
                  zonesWithCoordinates++;
                  debugPrint('✅ PARSED ZONE => id: ${zone.id}, name: ${zone.name}, formatedCoordinates: ${zone.formatedCoordinates!.length} points');
                } else {
                  zonesWithoutCoordinates++;
                  debugPrint('⚠️ PARSED ZONE => id: ${zone.id}, name: ${zone.name}, ❌ NO formatedCoordinates (polygon will not render)');
                  debugPrint('   → Backend must return formated_coordinates array for polygon rendering');
                  debugPrint('   → Zone validation will still work via get-zone-id endpoint');
                }
                zones.add(zone);
              }
            }
          }
        }

        debugPrint(
            '\x1B[32m  getAllZones: Fetched ${zones.length} zones from ${AppConstants.allZonesUri}  \x1B[0m');
        
        // 🎯 CRITICAL DIAGNOSTIC: Report coordinate status
        if (zonesWithoutCoordinates > 0) {
          debugPrint('\x1B[33m  ⚠️ WARNING: $zonesWithoutCoordinates zone(s) missing formated_coordinates  \x1B[0m');
          debugPrint('   → These zones will NOT render green polygons on map');
          debugPrint('   → Backend must update /api/v1/zone/list to include formated_coordinates');
          debugPrint('   → See: lib/features/location/documentation/ZONE_API_CONTRACT.md');
        }
        if (zonesWithCoordinates > 0) {
          debugPrint('\x1B[32m  ✅ $zonesWithCoordinates zone(s) have coordinates - polygons will render  \x1B[0m');
        }
        
        // 🔥 CRITICAL: Cache zones in SharedPreferences for 304 handling
        try {
          final prefs = Get.find<SharedPreferences>();
          final zonesJson = zones.map((z) => z.toJson()).toList();
          await prefs.setString(_allZonesCacheKey, jsonEncode(zonesJson));
          await prefs.setInt(_allZonesCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
          debugPrint('💾 getAllZones: Cached ${zones.length} zones for 304 handling');
        } catch (e) {
          debugPrint('⚠️ Error caching zones: $e');
        }
        
        return zones;
      } else if (response.statusCode == 404) {
        // ⚡ TASK 2: 404 means endpoint not found - return empty but log clearly
        // Controller will preserve existing zones
        debugPrint(
            '\x1B[33m  getAllZones: 404 Not Found - endpoint may not exist. Controller will preserve existing zones.  \x1B[0m');
        return [];
      } else {
        debugPrint(
            '\x1B[31m  getAllZones Error: ${response.statusCode} - ${response.statusText}  \x1B[0m');
        return [];
      }
    } catch (e) {
      debugPrint('\x1B[31m  getAllZones Error: $e  \x1B[0m');
      // ⚡ TASK 2: Return empty on error - controller will preserve existing zones
      return [];
    }
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
