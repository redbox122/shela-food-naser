import 'dart:convert';

import 'package:dio/dio.dart' hide Response;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/cart_suggested_item_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/recommended_product_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/store/domain/repositories/store_repository_interface.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/store/domain/models/subcategory_samples_model.dart';
import 'package:sixam_mart/features/store/domain/models/slim_menu_model.dart';
import 'package:sixam_mart/core/isolate/json_isolate_helper.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class StoreRepository implements StoreRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  StoreRepository({required this.apiClient, required this.sharedPreferences});

  List<Store> _sortOpenFirst(List<Store> stores,
      {bool thenByDistance = false}) {
    stores.sort((a, b) {
      final aOpen = a.isOpen == true;
      final bOpen = b.isOpen == true;
      if (aOpen != bOpen) {
        return aOpen ? -1 : 1; // open first, closed last
      }

      if (thenByDistance) {
        final aDistance = a.distance;
        final bDistance = b.distance;
        if (aDistance == null && bDistance == null) return 0;
        if (aDistance == null) return 1;
        if (bDistance == null) return -1;
        return aDistance.compareTo(bDistance);
      }

      return 0;
    });
    return stores;
  }

  /// Helper method to filter stores by current module ID
  /// This is a safeguard in case backend doesn't filter correctly
  List<Store> _filterStoresByModule(List<Store> stores) {
    final currentModuleId = Get.find<SplashController>().module?.id;
    if (currentModuleId == null) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ StoreRepository: expectedModuleId is null, skipping module filter');
      }
      return stores; // No module selected, return all (backward compatibility)
    }

    final originalCount = stores.length;
    final filtered = stores.where((store) {
      if (store.moduleId != null) {
        final matches = store.moduleId == currentModuleId;
        if (!matches && kDebugMode) {
          debugPrint(
              '⚠️ StoreRepository: Filtered out store ${store.id} (module_id: ${store.moduleId}, expected: $currentModuleId)');
        }
        return matches;
      } else {
        // If moduleId is null, include it (backward compatibility)
        return true;
      }
    }).toList();

    if (kDebugMode && originalCount != filtered.length) {
      debugPrint(
          '✅ StoreRepository: Filtered stores for module $currentModuleId: ${filtered.length} stores (from $originalCount)');
    }

    return _sortOpenFirst(filtered);
  }

  @override
  Future getList(
      {int? offset,
      bool isStoreList = false,
      String? filterBy,
      bool isPopularStoreList = false,
      String? type,
      String? id,
      bool isLatestStoreList = false,
      bool isFeaturedStoreList = false,
      bool isVisitAgainStoreList = false,
      bool isStoreRecommendedItemList = false,
      int? storeId,
      bool isStoreBannerList = false,
      bool isRecommendedStoreList = false,
      bool isTopOfferStoreList = false,
      bool subCategoryList = false,
      DataSourceEnum? source,
      bool? recentlyAdded,
      bool? highestRated,
      bool? fastestDelivery,
      double? minPrice,
      double? maxPrice,
      String? sortBy,
      CancelToken? cancelToken,
      int? limit}) async {
    if (isStoreList) {
      return await _getStoreList(offset!, filterBy!, type!,
          source: source ?? DataSourceEnum.client,
          recentlyAdded: recentlyAdded,
          highestRated: highestRated,
          fastestDelivery: fastestDelivery,
          minPrice: minPrice,
          maxPrice: maxPrice,
          sortBy: sortBy,
          limit: limit);
    } else if (isPopularStoreList) {
      return await _getPopularStoreList(type!,
          source: source ?? DataSourceEnum.client);
    } else if (isLatestStoreList) {
      return await _getLatestStoreList(type!,
          source: source ?? DataSourceEnum.client);
    } else if (isFeaturedStoreList) {
      return await _getFeaturedStoreList(
          source: source ?? DataSourceEnum.client);
    } else if (isVisitAgainStoreList) {
      return await _getVisitAgainStoreList(
          source: source ?? DataSourceEnum.client);
    } else if (isStoreRecommendedItemList) {
      return await _getStoreRecommendedItemList(storeId,
          cancelToken: cancelToken);
    } else if (isStoreBannerList) {
      return await _getStoreBannerList(storeId, cancelToken: cancelToken);
    } else if (isRecommendedStoreList) {
      return await _getRecommendedStoreList(
          source: source ?? DataSourceEnum.client);
    } else if (isTopOfferStoreList) {
      return await _getTopOfferStoreList(
          source: source ?? DataSourceEnum.client);
    } else if (subCategoryList) {
      return await _getSubCategoryList(parentID: id);
    }
  }

  Future<StoreModel?> _getStoreList(
      int offset, String filterBy, String storeType,
      {required DataSourceEnum source,
      bool? recentlyAdded,
      bool? highestRated,
      bool? fastestDelivery,
      double? minPrice,
      double? maxPrice,
      String? sortBy,
      int? limit}) async {
    StoreModel? storeModel;
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id?.toString() ?? 'no_module';
    // Check if Food module needs nearby filter for cache key
    final isFoodModule =
        splashController.module?.moduleType.toString() == AppConstants.food;
    final shouldUseNearbyFilter = isFoodModule && filterBy == 'all';
    final filterParam = shouldUseNearbyFilter ? '&filter=nearby' : '';

    // For Food module with nearby filter, include location in cache key
    // This ensures cache is invalidated when location changes
    String locationHash = '';
    if (shouldUseNearbyFilter) {
      final addressModel = AddressHelper.getUserAddressFromSharedPref();
      if (addressModel?.latitude != null && addressModel?.longitude != null) {
        // Create a location hash (rounded to ~10m precision for better cache invalidation)
        // This ensures even small location changes trigger fresh data fetch
        final double? lat = double.tryParse(addressModel!.latitude!);
        final double? lng = double.tryParse(addressModel.longitude!);
        if (lat != null && lng != null) {
          final roundedLat = (lat * 1000).round() / 1000;
          final roundedLng = (lng * 1000).round() / 1000;
          locationHash =
              '-loc_${roundedLat.toStringAsFixed(3)}_${roundedLng.toStringAsFixed(3)}';
        }
      }
    }

    // Build filter query string for cache key
    final List<String> cacheFilterParams = [];
    if (recentlyAdded == true) cacheFilterParams.add('recently_added');
    if (highestRated == true) cacheFilterParams.add('min_rating_4.5');
    if (fastestDelivery == true) cacheFilterParams.add('max_delivery_30');
    if (minPrice != null && minPrice > 0) {
      cacheFilterParams.add('min_price_${minPrice.toStringAsFixed(0)}');
    }
    if (maxPrice != null && maxPrice < 1000) {
      cacheFilterParams.add('max_price_${maxPrice.toStringAsFixed(0)}');
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      cacheFilterParams.add('sort_$sortBy');
    }
    final filterCacheKey = cacheFilterParams.isNotEmpty
        ? '-filters_${cacheFilterParams.join('_')}'
        : '';

    // 🔑 Separate cache by zone so one zone's store list never bleeds into
    // another after switching location/zone. (moduleId, storeType, filterBy,
    // offset, limit, filters and coordinates are already part of the key.)
    String zoneHash = '';
    final List<int>? zoneIdsForCache =
        AddressHelper.getUserAddressFromSharedPref()?.zoneIds;
    if (zoneIdsForCache != null && zoneIdsForCache.isNotEmpty) {
      final List<int> sortedZones = List<int>.from(zoneIdsForCache)..sort();
      zoneHash = '-zone_${sortedZones.join('_')}';
    }

    // 🔒 PHASE 3: Use limit parameter (default to 12 if not provided)
    final effectiveLimit = limit ?? 12;
    const cacheSchemaVersion = 'store_cache_v4';
    final String cacheId =
        '${AppConstants.storeUri}/$filterBy?store_type=$storeType&offset=$offset&limit=$effectiveLimit$filterParam-$moduleId$zoneHash$locationHash$filterCacheKey-$cacheSchemaVersion';

    switch (source) {
      case DataSourceEnum.client:
        try {
          // Ensure headers are valid before making API call
          apiClient.ensureHeadersAreValid();

          // Get proper headers with zoneId
          AddressModel? addressModel =
              AddressHelper.getUserAddressFromSharedPref();

          // If no address is available, try to get zone data from current location
          if (addressModel == null ||
              addressModel.zoneIds == null ||
              addressModel.zoneIds!.isEmpty) {
            if (kDebugMode) {
              appLogger.warning(
                  '⚠️ No address data available, attempting to get zone data...');
            }
            // Try to get zone data from current position (backend is source of truth)
            try {
              final locationController = Get.find<LocationController>();
              final position = locationController.position;
              final bool hasValidPosition =
                  position.latitude != 0.0 || position.longitude != 0.0;
              if (hasValidPosition) {
                final zoneResponse = await locationController.getZone(
                  position.latitude.toString(),
                  position.longitude.toString(),
                  false,
                  handleError: true,
                );

                if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
                  addressModel = AddressModel(
                    latitude: position.latitude.toString(),
                    longitude: position.longitude.toString(),
                    zoneIds: zoneResponse.zoneIds,
                    zoneData: zoneResponse.zoneData,
                    areaIds: zoneResponse.areaIds,
                  );
                  if (kDebugMode) {
                    appLogger.info(
                        '✅ Zone data obtained from current position: ${zoneResponse.zoneIds}');
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                appLogger.error('❌ Failed to get zone data: $e', e);
              }
            }
          }

          final Map<String, String> headers = apiClient.updateHeader(
            sharedPreferences.getString(AppConstants.token),
            addressModel?.zoneIds,
            addressModel?.areaIds,
            sharedPreferences.getString(AppConstants.languageCode),
            Get.find<SplashController>().module?.id,
            addressModel?.latitude,
            addressModel?.longitude,
            setHeader: false,
          );

          // Debug: Print headers to verify zone IDs are included
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '🔧 Updated headers with zone IDs: ${addressModel?.zoneIds}, coords: ${addressModel?.latitude}, ${addressModel?.longitude}');
          }

          // For Food module, add filter=nearby to sort by distance (nearest first)
          // This automatically calculates distance and sorts restaurants by proximity
          final isFoodModule = splashController.module?.moduleType.toString() ==
              AppConstants.food;
          final shouldUseNearbyFilter = isFoodModule && filterBy == 'all';
          final filterParam = shouldUseNearbyFilter ? '&filter=nearby' : '';

          // Build filter query parameters
          final List<String> filterParams = [];

          if (recentlyAdded == true) {
            filterParams.add('recently_added=true');
          }

          if (highestRated == true) {
            filterParams.add('min_rating=4.5');
          }

          if (fastestDelivery == true) {
            filterParams.add('max_delivery_time=30');
          }

          if (minPrice != null && minPrice > 0) {
            filterParams.add('min_price=${minPrice.toStringAsFixed(2)}');
          }

          if (maxPrice != null && maxPrice < 1000) {
            filterParams.add('max_price=${maxPrice.toStringAsFixed(2)}');
          }

          if (sortBy != null && sortBy.isNotEmpty) {
            filterParams.add('sort_by=$sortBy');
          }

          final filterQueryString =
              filterParams.isNotEmpty ? '&${filterParams.join('&')}' : '';

          if (kDebugMode && AppConstants.enableVerboseLogs) {
            final safeHeaders = Map<String, String>.from(headers);
            if (safeHeaders.containsKey('Authorization')) {
              safeHeaders['Authorization'] = 'Bearer ***';
            }
            appLogger.debug(
                '🏪 Making stores API call: ${AppConstants.storeUri}/$filterBy?store_type=$storeType&offset=$offset&limit=$effectiveLimit$filterParam$filterQueryString');
            appLogger.debug('🏪 Headers: $safeHeaders');
            if (shouldUseNearbyFilter) {
              appLogger.debug(
                  '📍 Food module detected - using filter=nearby to sort by distance (nearest first)');
            }
            if (filterQueryString.isNotEmpty) {
              appLogger.debug('🔍 Filter parameters: $filterQueryString');
            }
          }

          // Debug: Verify moduleId is in headers
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug('🔍 StoreRepository: API call headers check:');
            final nonNullHeaders = headers;
            appLogger.debug(
                '   - moduleId in headers: ${nonNullHeaders.containsKey(AppConstants.moduleId)}');
            if (nonNullHeaders.containsKey(AppConstants.moduleId)) {
              appLogger.debug(
                  '   - moduleId value: ${nonNullHeaders[AppConstants.moduleId]}');
            }
            appLogger.debug(
                '   - zoneId in headers: ${nonNullHeaders.containsKey(AppConstants.zoneId)}');
            if (nonNullHeaders.containsKey(AppConstants.zoneId)) {
              appLogger.debug(
                  '   - zoneId value: ${nonNullHeaders[AppConstants.zoneId]}');
            }
            appLogger.debug(
                '   - latitude in headers: ${nonNullHeaders.containsKey(AppConstants.latitude)}');
            appLogger.debug(
                '   - longitude in headers: ${nonNullHeaders.containsKey(AppConstants.longitude)}');
          }

          final String mainUrl =
              '${AppConstants.storeUri}/$filterBy?store_type=$storeType&offset=$offset&limit=$effectiveLimit$filterParam$filterQueryString';
          if (kDebugMode) {
            debugPrint(
                '[StoreList][REQUEST] uri=$mainUrl etag=enabled '
                'module=${headers[AppConstants.moduleId] ?? headers['module-id']} '
                'zone=${headers[AppConstants.zoneId] ?? headers['zone-id']} '
                'lat=${headers[AppConstants.latitude]} lng=${headers[AppConstants.longitude]} '
                'filterBy=$filterBy storeType=$storeType offset=$offset limit=$effectiveLimit nearby=$shouldUseNearbyFilter');
          }
          Response response = await apiClient.getData(
            mainUrl,
            headers: headers,
          );
          if (kDebugMode) {
            final int rawCount = (response.body is Map &&
                    (response.body as Map)['stores'] is List)
                ? ((response.body as Map)['stores'] as List).length
                : 0;
            debugPrint(
                '[StoreList][RAW_RESPONSE] status=${response.statusCode} '
                'totalSize=${(response.body is Map) ? (response.body as Map)['total_size'] : 'n/a'} rawStores=$rawCount');
          }

          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '   📡 SECTION 3 API REPO - Response status: ${response.statusCode}');
            appLogger.debug(
                '   📦 SECTION 3 API REPO - Response body type: ${response.body.runtimeType}');
          }
          // ⚡ TASK 4: Pagination Retry Logic - Backend bug with filter=nearby.
          // If the nearby filter returns 0 stores on this 200 response — whether
          // total_size is 0 OR > 0 — retry once WITHOUT filter=nearby so the user
          // sees the same stores Home shows (Home does not use filter=nearby).
          // (Previously this only fired when total_size > 0, so a nearby response
          // with total_size=0 / 0 stores fell through and showed the empty state.)
          final bool nearbyReturnedEmpty = response.statusCode == 200 &&
              shouldUseNearbyFilter &&
              offset >= 1 &&
              response.body is Map &&
              (((response.body as Map)['stores'] as List?)?.isEmpty ?? true);
          if (nearbyReturnedEmpty) {
            final dynamic nearbyTotalSize =
                (response.body as Map)['total_size'];
            if (kDebugMode) {
              appLogger.warning(
                  '⚠️ TASK 4: filter=nearby returned 0 stores for offset=$offset, totalSize=$nearbyTotalSize');
              debugPrint(
                  '[StoreList] retry_without_nearby reason=nearby_empty');
            }
            // Retry without filter=nearby
            response = await apiClient.getData(
              '${AppConstants.storeUri}/$filterBy?store_type=$storeType&offset=$offset&limit=$effectiveLimit$filterQueryString',
              headers: headers,
            );
            if (kDebugMode) {
              final int retryStoresCount = (response.body is Map &&
                      (response.body as Map)['stores'] is List)
                  ? ((response.body as Map)['stores'] as List).length
                  : 0;
              appLogger.info(
                  '   ✅ TASK 4: Retry result: $retryStoresCount stores (without filter=nearby)');
              debugPrint(
                  '[StoreList][RAW_RESPONSE_RETRY] status=${response.statusCode} '
                  'totalSize=${(response.body is Map) ? (response.body as Map)['total_size'] : 'n/a'} rawStores=$retryStoresCount');
            }
          }

          // ⚡ FIX: Check status code type explicitly to handle 304 correctly
          final statusCode = response.statusCode;
          if (statusCode == 200) {
            storeModel =
                StoreModel.fromJson(response.body as Map<String, dynamic>);

            // ⚠️ WARNING: Check for backend pagination bug
            if (kDebugMode &&
                storeModel.totalSize != null &&
                storeModel.totalSize! > 0) {
              final limit = int.tryParse(storeModel.limit ?? '12') ?? 12;
              final totalPages = (storeModel.totalSize! / limit).ceil();
              if (AppConstants.enableVerboseLogs) {
                appLogger.debug(
                    '   - Pagination info: $totalPages pages (${storeModel.totalSize} stores / $limit per page)');
              }

              // Warn if API returns 0 stores but totalSize suggests there should be more
              if (storeModel.stores != null &&
                  storeModel.stores!.isEmpty &&
                  storeModel.offset != null &&
                  storeModel.offset! > 1 &&
                  storeModel.offset! < totalPages) {
                appLogger.warning(
                    '   ⚠️ BACKEND PAGINATION BUG: API returned 0 stores for offset=${storeModel.offset} but totalSize=${storeModel.totalSize} suggests there should be more stores.');
                appLogger.warning(
                    '   → This is likely a backend issue with filter=nearby pagination.');
                if (shouldUseNearbyFilter) {
                  appLogger.warning(
                      '   → The filter=nearby parameter may be causing pagination issues on the backend.');
                }
              }
            }
            if (storeModel.stores != null &&
                storeModel.stores!.isNotEmpty &&
                kDebugMode &&
                AppConstants.enableVerboseLogs) {
              final firstStore = storeModel.stores!.first;
              appLogger.debug(
                  '   - First store: id=${firstStore.id}, name=${firstStore.name}, moduleId=${firstStore.moduleId}, distance=${firstStore.distance}');

              // Log distance info for Food module
              if (shouldUseNearbyFilter) {
                final storesWithDistance =
                    storeModel.stores!.where((s) => s.distance != null).length;
                appLogger.debug(
                    '📍 Distance info: $storesWithDistance/${storeModel.stores!.length} stores have distance data');
                if (storeModel.stores!.isNotEmpty) {
                  final distances = storeModel.stores!
                      .where((s) => s.distance != null)
                      .map((s) => s.distance!)
                      .toList();
                  if (distances.isNotEmpty) {
                    distances.sort();
                    appLogger.debug(
                        '📍 Distance range: ${distances.first.toStringAsFixed(1)}m - ${distances.last.toStringAsFixed(1)}m');
                  }
                }
              }
            }

            // Get current module ID for filtering
            final currentModuleId = Get.find<SplashController>().module?.id;

            // ⚠️ CRITICAL: Client-side filtering - only include stores matching current module
            // This is a safeguard in case backend doesn't filter correctly
            if (currentModuleId != null && storeModel.stores != null) {
              final originalCount = storeModel.stores!.length;
              storeModel.stores = storeModel.stores!.where((store) {
                if (store.moduleId != null) {
                  final matches = store.moduleId == currentModuleId;
                  if (!matches && kDebugMode) {
                    debugPrint(
                        '⚠️ StoreRepository: Filtered out store ${store.id} (module_id: ${store.moduleId}, expected: $currentModuleId)');
                  }
                  return matches;
                } else {
                  // If moduleId is null, include it (backward compatibility)
                  return true;
                }
              }).toList();

              // For Food module with nearby filter, ensure open stores first then nearest distance.
              // This is a fallback in case backend doesn't sort correctly
              if (shouldUseNearbyFilter &&
                  storeModel.stores != null &&
                  storeModel.stores!.isNotEmpty) {
                _sortOpenFirst(storeModel.stores!, thenByDistance: true);
                if (kDebugMode && AppConstants.enableVerboseLogs) {
                  appLogger.debug(
                      '📍 Client-side sorted ${storeModel.stores!.length} restaurants: open first, then distance');
                }
              }

              // ⚠️ CRITICAL FIX: Don't overwrite totalSize with filtered count!
              // totalSize should remain the API's total count (300+) for pagination to work
              // The filtered count is just for the current page, not the total available stores
              // Keeping original totalSize allows pagination to load more stores correctly
              if (kDebugMode) {
                debugPrint(
                    '✅ StoreRepository: Loaded ${storeModel.stores!.length} stores for module $currentModuleId (filtered from $originalCount)');
                debugPrint(
                    '   📊 Preserving totalSize: ${storeModel.totalSize} (for pagination) - filtered stores in this page: ${storeModel.stores!.length}');
                debugPrint(
                    '[StoreList][CLIENT_FILTER] before=$originalCount after=${storeModel.stores!.length} reason=module');
              }
            }

            // 🔧 VIEW-ALL FALLBACK: /stores/get-stores/all can return 0 stores for
            // a module/zone where Home's /stores/popular DOES return stores
            // (backend discrepancy). On the first page, if get-stores/all is
            // empty, reuse the exact source Home uses so "رؤية الكل" shows the
            // same restaurants instead of an empty state.
            if (offset == 1 &&
                (storeModel.stores == null || storeModel.stores!.isEmpty)) {
              if (kDebugMode) {
                debugPrint(
                    '[StoreList] get_stores_all_empty -> fallback_to_popular type=$storeType');
              }
              final List<Store>? popularStores = await _getPopularStoreList(
                  storeType,
                  source: DataSourceEnum.client);
              if (popularStores != null && popularStores.isNotEmpty) {
                storeModel.stores = popularStores;
                storeModel.totalSize = popularStores.length;
                if (kDebugMode) {
                  debugPrint(
                      '[StoreList] fallback_to_popular stores=${popularStores.length} final_source=popular');
                }
              }
            }

            // ✅ FIXED: GET-STORES/ALL endpoint now includes cover_photo_full_url
            // SlimStoreResource has been updated to include cover_photo_full_url
            // Frontend Store.fromJson parser will automatically pick it up

            // Cache the filtered results
            LocalClient.organize(DataSourceEnum.client, cacheId,
                jsonEncode(storeModel.toJson()), apiClient.getHeader());
          } else if (statusCode == 304) {
            // ⚡ ETAG SUPPORT: 304 Not Modified means use Hive cache for CURRENT module only
            if (kDebugMode) {
              debugPrint(
                  '⚡ StoreRepository: 304 Not Modified - loading from Hive cache for current module');
            }
            final int? currentModuleId =
                Get.find<SplashController>().module?.id;
            if (currentModuleId != null) {
              final cacheService = HiveHomeCacheService();
              storeModel = await cacheService.loadStores(
                currentModuleId,
                validateLocation: shouldUseNearbyFilter,
              );
            }

            // Fallback to LocalClient cache (ETag payload cache for this endpoint).
            if (storeModel == null) {
              final String? cacheResponseData = await LocalClient.organize(
                  DataSourceEnum.local, cacheId, null, null);
              if (cacheResponseData != null) {
                try {
                  storeModel = StoreModel.fromJson(
                      jsonDecode(cacheResponseData) as Map<String, dynamic>);
                } catch (_) {
                  storeModel = null;
                }
              }
            }

            final int cachedStoreCount = storeModel?.stores?.length ?? 0;
            if (kDebugMode) {
              debugPrint('[StoreCache] 304_cache_hit stores_count=$cachedStoreCount');
            }

            // 🔧 Treat an empty/zero cache on 304 as a cache MISS. An empty Hive
            // entry must never be shown as the final result — that is what caused
            // "no restaurants available" on /stores?page=all even though Home had
            // stores. Force a fresh, ETag-less fetch instead.
            if (storeModel == null || cachedStoreCount == 0) {
              if (kDebugMode) {
                debugPrint(
                    '⚠️ StoreRepository: 304 with empty/missing cache - forcing fresh fetch');
                debugPrint(
                    '[StoreCache] empty_cache_on_304 -> force_refresh_no_etag');
              }
              if (currentModuleId != null) {
                await HiveHomeCacheService().clearModuleCache(currentModuleId);
              }
              final String freshUrl =
                  '${AppConstants.storeUri}/$filterBy?store_type=$storeType&offset=$offset&limit=$effectiveLimit$filterParam$filterQueryString';
              if (kDebugMode) {
                debugPrint(
                    '[StoreList][REQUEST] uri=$freshUrl etag=disabled '
                    'module=$currentModuleId filterBy=$filterBy storeType=$storeType '
                    'offset=$offset limit=$effectiveLimit nearby=$shouldUseNearbyFilter');
              }
              // Clear ETag to avoid repeated 304 when cache is missing
              await HiveHomeCacheService().clearETagForUri(freshUrl);
              Response freshResponse =
                  await apiClient.getData(freshUrl, useEtag: false);
              int rawFreshCount = (freshResponse.body is Map &&
                      (freshResponse.body as Map)['stores'] is List)
                  ? ((freshResponse.body as Map)['stores'] as List).length
                  : 0;
              if (kDebugMode) {
                debugPrint(
                    '[StoreList][RAW_RESPONSE] status=${freshResponse.statusCode} '
                    'totalSize=${(freshResponse.body is Map) ? (freshResponse.body as Map)['total_size'] : 'n/a'} rawStores=$rawFreshCount');
              }

              // 🔧 Mirror the main path's TASK 4 logic: if the food "nearby"
              // filter returns 0 stores (backend nearby/pagination quirk), retry
              // once WITHOUT filter=nearby so /stores?page=all shows the same
              // stores Home shows. Without this retry the fresh fetch could stay
              // at 0 and re-show the empty state.
              if (freshResponse.statusCode == 200 &&
                  shouldUseNearbyFilter &&
                  rawFreshCount == 0) {
                final String noNearbyUrl =
                    '${AppConstants.storeUri}/$filterBy?store_type=$storeType&offset=$offset&limit=$effectiveLimit$filterQueryString';
                if (kDebugMode) {
                  debugPrint(
                      '[StoreList][REQUEST] retry_without_nearby uri=$noNearbyUrl etag=disabled');
                }
                await HiveHomeCacheService().clearETagForUri(noNearbyUrl);
                final Response retryResp =
                    await apiClient.getData(noNearbyUrl, useEtag: false);
                final int retryCount = (retryResp.body is Map &&
                        (retryResp.body as Map)['stores'] is List)
                    ? ((retryResp.body as Map)['stores'] as List).length
                    : 0;
                if (kDebugMode) {
                  debugPrint(
                      '[StoreList][RAW_RESPONSE] retry_without_nearby status=${retryResp.statusCode} rawStores=$retryCount');
                }
                if (retryResp.statusCode == 200 && retryCount > 0) {
                  freshResponse = retryResp;
                  rawFreshCount = retryCount;
                }
              }

              if (freshResponse.statusCode == 200 &&
                  freshResponse.body is Map<String, dynamic>) {
                storeModel = StoreModel.fromJson(
                    freshResponse.body as Map<String, dynamic>);
                if (currentModuleId != null && storeModel.stores != null) {
                  final int originalCount = storeModel.stores!.length;
                  storeModel.stores = storeModel.stores!.where((store) {
                    if (store.moduleId != null) {
                      return store.moduleId == currentModuleId;
                    }
                    return true;
                  }).toList();
                  if (kDebugMode) {
                    debugPrint(
                        '✅ StoreRepository: Fresh stores filtered for module $currentModuleId: ${storeModel.stores!.length} (from $originalCount)');
                    debugPrint(
                        '[StoreList][CLIENT_FILTER] before=$originalCount after=${storeModel.stores!.length} reason=module');
                  }
                }
                // Cache repaired data for next 304
                await LocalClient.organize(DataSourceEnum.client, cacheId,
                    jsonEncode(storeModel.toJson()), apiClient.getHeader());
              } else {
                if (kDebugMode) {
                  debugPrint(
                      '❌ StoreRepository: Fresh fetch failed after 304 - using fallback');
                }
                storeModel = await _getFallbackStoreList(offset);
              }
            }
          } else {
            debugPrint(
                '❌ Stores API returned ${response.statusCode}, using fallback');
            storeModel = await _getFallbackStoreList(offset);
          }
          if (kDebugMode) {
            final String finalSource = statusCode == 200
                ? 'api'
                : (statusCode == 304 ? 'cache_or_refresh' : 'fallback');
            debugPrint(
                '[StoreList] final_source=$finalSource totalSize=${storeModel?.totalSize ?? 0} stores=${storeModel?.stores?.length ?? 0}');
          }
        } catch (e) {
          debugPrint('❌ Stores API failed: $e, using fallback');
          storeModel = await _getFallbackStoreList(offset);
        }
        break;

      case DataSourceEnum.local:
        // For Food module with nearby filter, check if location changed
        // If location changed, skip cache and fetch fresh data with new distance calculations
        if (shouldUseNearbyFilter) {
          final currentAddress = AddressHelper.getUserAddressFromSharedPref();
          if (currentAddress?.latitude != null &&
              currentAddress?.longitude != null) {
            // Use same precision as cache key (10m precision)
            final double? lat = double.tryParse(currentAddress!.latitude!);
            final double? lng = double.tryParse(currentAddress.longitude!);

            if (lat != null && lng != null) {
              final currentLat = (lat * 1000).round() / 1000;
              final currentLng = (lng * 1000).round() / 1000;
              final currentLocationHash =
                  '-loc_${currentLat.toStringAsFixed(3)}_${currentLng.toStringAsFixed(3)}';

              // If cache key location doesn't match current location, skip cache
              if (!cacheId.contains(currentLocationHash)) {
                if (kDebugMode) {
                  appLogger.debug(
                      '📍 Location changed detected - skipping cache to get fresh distance data');
                  appLogger.debug('   Cache key: $cacheId');
                  appLogger.debug('   Current location: $currentLocationHash');
                }
                // Force API call instead of using cache
                storeModel = await _getStoreList(offset, filterBy, storeType,
                    source: DataSourceEnum.client);
                break;
              }
            }
          }
        }

        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          storeModel = StoreModel.fromJson(
              jsonDecode(cacheResponseData) as Map<String, dynamic>);

          // Get current module ID for filtering cached data too
          final currentModuleId = Get.find<SplashController>().module?.id;

          // ⚠️ CRITICAL: Filter cached stores by module ID too
          if (currentModuleId != null && storeModel.stores != null) {
            final originalCount = storeModel.stores!.length;
            storeModel.stores = storeModel.stores!.where((store) {
              if (store.moduleId != null) {
                return store.moduleId == currentModuleId;
              } else {
                // If moduleId is null, include it (backward compatibility)
                return true;
              }
            }).toList();
            if (shouldUseNearbyFilter && storeModel.stores!.isNotEmpty) {
              _sortOpenFirst(storeModel.stores!, thenByDistance: true);
            } else {
              _sortOpenFirst(storeModel.stores!);
            }

            // ⚠️ CRITICAL FIX: Don't overwrite totalSize with filtered count!
            // totalSize should remain the API's total count (300+) for pagination to work
            // The filtered count is just for the current page, not the total available stores
            // Keeping original totalSize allows pagination to load more stores correctly
            if (kDebugMode) {
              debugPrint(
                  '✅ StoreRepository: Loaded ${storeModel.stores!.length} stores from cache for module $currentModuleId (filtered from $originalCount)');
              debugPrint(
                  '   📊 Preserving totalSize: ${storeModel.totalSize} (for pagination) - filtered stores in this page: ${storeModel.stores!.length}');
            }
          }
        }
        break;
    }
    return storeModel;
  }

  /// Fallback method to get stores when the main API fails
  /// Returns empty list to avoid showing stores from wrong module
  Future<StoreModel?> _getFallbackStoreList(int offset) async {
    try {
      debugPrint('🔄 Using fallback method to get stores...');
      final currentModuleId = Get.find<SplashController>().module?.id;
      if (kDebugMode) {
        debugPrint(
            '⚠️ Fallback: API failed, returning empty list (current module: $currentModuleId)');
        debugPrint(
            '   - Returning empty list to avoid showing stores from wrong module');
      }
      // Return empty list instead of hardcoded store from wrong module
      // This prevents showing stores that will be filtered out anyway
      return StoreModel(stores: [], totalSize: 0, offset: offset, limit: '12');
    } catch (e) {
      debugPrint('❌ Fallback method failed: $e');
      return StoreModel(stores: [], totalSize: 0, offset: offset, limit: '12');
    }
  }

  // =====================================

  Future<List<Store>?> _getPopularStoreList(String type,
      {required DataSourceEnum source}) async {
    List<Store>? popularStoreList;
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id?.toString() ?? 'no_module';
    final String cacheId =
        '${AppConstants.popularStoreUri}?type=$type-$moduleId';

    switch (source) {
      case DataSourceEnum.client:
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug(
              '   🌐 SECTION 2 API REPO - Making API call: ${AppConstants.popularStoreUri}?type=$type');
        }
        // Build headers with current module ID
        final Map<String, String> headers = apiClient.updateHeader(
            sharedPreferences.getString(AppConstants.token),
            null, // zoneIds not needed
            null, // areaIds not needed
            null, // language code (default handled by client)
            splashController.module?.id,
            null,
            null,
            setHeader: false);
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug('🔧 Popular stores request headers: $headers');
        }
        final Response response = await apiClient.getData(
            '${AppConstants.popularStoreUri}?type=$type',
            headers: headers);
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug(
              '   📡 SECTION 2 API REPO - Response status: ${response.statusCode}');
        }
        if (response.statusCode == 200) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '   📦 SECTION 2 API REPO - Response body type: ${response.body.runtimeType}');
            if (response.body is Map &&
                (response.body as Map).containsKey('stores')) {
              appLogger.debug(
                  '   📋 SECTION 2 API REPO - Raw stores count from API: ${(response.body['stores'] as List).length}');
            }
          }
          popularStoreList = [];
          if (response.body is Map && response.body['stores'] is List) {
            for (var store in (response.body['stores'] as List)) {
              popularStoreList
                  .add(Store.fromJson(store as Map<String, dynamic>));
            }
          }

          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '   🔍 SECTION 2 API REPO - Before module filter: ${popularStoreList.length} stores');
          }
          // ⚠️ CRITICAL: Client-side filtering by module ID
          final int popularRawCount = popularStoreList.length;
          popularStoreList = _filterStoresByModule(popularStoreList);
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '   ✅ SECTION 2 API REPO - After module filter: ${popularStoreList.length} stores');
          }
          if (kDebugMode) {
            debugPrint(
                '[HomeStores][SOURCE] uri=${AppConstants.popularStoreUri}?type=$type '
                'total=$popularRawCount count=${popularStoreList.length} module=$moduleId '
                'zone=${headers[AppConstants.zoneId] ?? headers['zone-id']} '
                'lat=${headers[AppConstants.latitude]} lng=${headers[AppConstants.longitude]}');
          }

          // Cache the filtered results
          LocalClient.organize(
              DataSourceEnum.client,
              cacheId,
              jsonEncode(popularStoreList.map((s) => s.toJson()).toList()),
              apiClient.getHeader());
        } else {
          if (kDebugMode) {
            appLogger.warning(
                '   ❌ SECTION 2 API REPO - API call failed with status: ${response.statusCode}');
          }
        }
        break;

      case DataSourceEnum.local:
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger
              .debug('   📦 SECTION 2 API REPO - Loading from cache: $cacheId');
        }
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger
                .debug('   ✅ SECTION 2 API REPO - Cache hit, parsing data...');
          }
          popularStoreList = [];
          final decodedCache = jsonDecode(cacheResponseData) as List;
          for (var store in decodedCache) {
            popularStoreList.add(Store.fromJson(store as Map<String, dynamic>));
          }

          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '   🔍 SECTION 2 API REPO - Before module filter: ${popularStoreList.length} stores');
          }
          // ⚠️ CRITICAL: Filter cached stores by module ID too
          popularStoreList = _filterStoresByModule(popularStoreList);
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '   ✅ SECTION 2 API REPO - After module filter: ${popularStoreList.length} stores');
          }
        } else {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger
                .debug('   ⚠️ SECTION 2 API REPO - Cache miss (no data found)');
          }
        }
        break;
    }
    return popularStoreList;
  }

  Future<List<Store>?> _getLatestStoreList(String type,
      {required DataSourceEnum source}) async {
    List<Store>? latestStoreList;
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id?.toString() ?? 'no_module';
    final String cacheId =
        '${AppConstants.latestStoreUri}?type=$type-$moduleId';

    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient
            .getData('${AppConstants.latestStoreUri}?type=$type');
        if (response.statusCode == 200) {
          latestStoreList = [];
          if (response.body is Map && response.body['stores'] is List) {
            for (var store in (response.body['stores'] as List)) {
              latestStoreList
                  .add(Store.fromJson(store as Map<String, dynamic>));
            }
          }

          // ⚠️ CRITICAL: Client-side filtering by module ID
          latestStoreList = _filterStoresByModule(latestStoreList);

          // Cache the filtered results
          LocalClient.organize(
              DataSourceEnum.client,
              cacheId,
              jsonEncode(latestStoreList.map((s) => s.toJson()).toList()),
              apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          latestStoreList = [];
          for (var store in (jsonDecode(cacheResponseData) as List)) {
            latestStoreList.add(Store.fromJson(store as Map<String, dynamic>));
          }

          // ⚠️ CRITICAL: Filter cached stores by module ID too
          latestStoreList = _filterStoresByModule(latestStoreList);
        }
    }

    return latestStoreList;
  }

  Future<List<Store>?> _getTopOfferStoreList(
      {required DataSourceEnum source}) async {
    List<Store>? topOfferStoreList;
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id?.toString() ?? 'no_module';
    final String cacheId = '${AppConstants.topOfferStoreUri}-$moduleId';

    switch (source) {
      case DataSourceEnum.client:
        final Response response =
            await apiClient.getData(AppConstants.topOfferStoreUri);
        if (response.statusCode == 200) {
          topOfferStoreList = [];
          if (response.body is Map && response.body['stores'] is List) {
            for (var store in (response.body['stores'] as List)) {
              topOfferStoreList
                  .add(Store.fromJson(store as Map<String, dynamic>));
            }
          }

          // ⚠️ CRITICAL: Client-side filtering by module ID
          topOfferStoreList = _filterStoresByModule(topOfferStoreList);

          // Cache the filtered results
          LocalClient.organize(
              DataSourceEnum.client,
              cacheId,
              jsonEncode(topOfferStoreList.map((s) => s.toJson()).toList()),
              apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          topOfferStoreList = [];
          final decodedCache = jsonDecode(cacheResponseData) as List;
          for (var store in decodedCache) {
            topOfferStoreList
                .add(Store.fromJson(store as Map<String, dynamic>));
          }

          // ⚠️ CRITICAL: Filter cached stores by module ID too
          topOfferStoreList = _filterStoresByModule(topOfferStoreList);
        }
    }
    return topOfferStoreList;
  }

  Future<List<Store>?> _getFeaturedStoreList(
      {required DataSourceEnum source}) async {
    List<Store>? featuredStoreList;

    final splashController = Get.find<SplashController>();
    final module = splashController.module;
    final configModule = splashController.configModel?.module;

    // If no module is selected, return empty list (don't call API)
    // The backend requires moduleId in headers, causing 500 errors when null
    if (module == null && configModule == null) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ StoreRepository: Skipping featured stores API call - no module selected');
      }
      return [];
    }

    final String cacheId =
        '${AppConstants.storeUri}/all?featured=1&offset=1&limit=50-${module?.id ?? configModule?.id ?? ''}';

    final Map<String, String> header = apiClient.getHeader();

    switch (source) {
      case DataSourceEnum.client:
        try {
          final Response response = await apiClient.getData(
            '${AppConstants.storeUri}/all?featured=1&offset=1&limit=50',
          );
          if (response.statusCode == 200) {
            featuredStoreList = [];
            if (response.body is Map &&
                response.body['stores'] != null &&
                response.body['stores'] is List) {
              for (var store in (response.body['stores'] as List)) {
                featuredStoreList
                    .add(Store.fromJson(store as Map<String, dynamic>));
              }

              // ⚠️ CRITICAL: Client-side filtering by module ID
              featuredStoreList = _filterStoresByModule(featuredStoreList);

              // Cache the filtered results
              LocalClient.organize(
                  DataSourceEnum.client,
                  cacheId,
                  jsonEncode(featuredStoreList.map((s) => s.toJson()).toList()),
                  header);
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '❌ Featured stores API returned ${response.statusCode}');
            }
            // Return empty list instead of null to prevent crashes
            featuredStoreList = [];
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Featured stores API failed: $e');
          }
          // Return empty list instead of null to prevent crashes
          featuredStoreList = [];
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          featuredStoreList = [];
          final decodedCache = jsonDecode(cacheResponseData) as List;
          for (var store in decodedCache) {
            featuredStoreList
                .add(Store.fromJson(store as Map<String, dynamic>));
          }

          // ⚠️ CRITICAL: Filter cached stores by module ID too
          featuredStoreList = _filterStoresByModule(featuredStoreList);
        }
    }
    return featuredStoreList;
  }

  Future<List<Store>?> _getVisitAgainStoreList(
      {required DataSourceEnum source}) async {
    List<Store>? visitAgainStoreList;
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id?.toString() ?? 'no_module';
    final String cacheId = '${AppConstants.visitAgainStoreUri}-$moduleId';

    switch (source) {
      case DataSourceEnum.client:
        final Response response =
            await apiClient.getData(AppConstants.visitAgainStoreUri);
        if (response.statusCode == 200) {
          visitAgainStoreList = [];
          if (response.body is List) {
            for (var store in (response.body as List)) {
              visitAgainStoreList
                  .add(Store.fromJson(store as Map<String, dynamic>));
            }
          }

          // ⚠️ CRITICAL: Client-side filtering by module ID
          visitAgainStoreList = _filterStoresByModule(visitAgainStoreList);

          // Cache the filtered results
          LocalClient.organize(
              DataSourceEnum.client,
              cacheId,
              jsonEncode(visitAgainStoreList.map((s) => s.toJson()).toList()),
              apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          visitAgainStoreList = [];
          final decodedCache = jsonDecode(cacheResponseData) as List;
          for (var store in decodedCache) {
            visitAgainStoreList
                .add(Store.fromJson(store as Map<String, dynamic>));
          }

          // ⚠️ CRITICAL: Filter cached stores by module ID too
          visitAgainStoreList = _filterStoresByModule(visitAgainStoreList);
        }
    }
    return visitAgainStoreList;
  }

  @override
  Future<Store?> getStoreDetails(
      String storeID,
      bool fromCart,
      String slug,
      String languageCode,
      ModuleModel? module,
      int? cacheModuleId,
      int? moduleId,
      CancelToken? cancelToken) async {
    Store? store;
    Map<String, String>? header;

    // Always set headers with current language code to ensure X-localization header is sent
    if (fromCart) {
      final AddressModel? addressModel =
          AddressHelper.getUserAddressFromSharedPref();
      header = apiClient.updateHeader(
        sharedPreferences.getString(AppConstants.token),
        addressModel?.zoneIds,
        addressModel?.areaIds,
        languageCode,
        module == null ? cacheModuleId : moduleId,
        addressModel?.latitude,
        addressModel?.longitude,
        setHeader: false,
      );
    } else if (slug.isNotEmpty) {
      header = apiClient.updateHeader(
        sharedPreferences.getString(AppConstants.token),
        [],
        [],
        languageCode,
        0,
        '',
        '',
        setHeader: false,
      );
    } else {
      // When fromCart is false and slug is empty, still set headers with current language code
      final AddressModel? addressModel =
          AddressHelper.getUserAddressFromSharedPref();
      header = apiClient.updateHeader(
        sharedPreferences.getString(AppConstants.token),
        addressModel?.zoneIds,
        addressModel?.areaIds,
        languageCode,
        module == null ? cacheModuleId : moduleId,
        addressModel?.latitude,
        addressModel?.longitude,
        setHeader: false,
      );
    }

    // Debug: Verify X-localization header is set
    if (kDebugMode) {
      final localizationHeader = header[AppConstants.localizationKey];
      debugPrint(
          '📍 [StoreRepository] getStoreDetails() - Language header check:');
      debugPrint('   🌐 Requested languageCode: $languageCode');
      debugPrint('   🌐 X-localization header in request: $localizationHeader');
      if (localizationHeader == null || localizationHeader.isEmpty) {
        debugPrint('   ⚠️ WARNING: X-localization header is missing or empty!');
      } else {
        debugPrint('   ✅ X-localization header is set correctly');
      }
    }

    final Response response = await apiClient.getData(
        '${AppConstants.storeDetailsUri}${slug.isNotEmpty ? slug : storeID}',
        headers: header,
        cancelToken: cancelToken);
    // ✅ FIX: Handle 304 (Not Modified) responses - use cached data from repository/service
    if (response.statusCode == 200 || response.statusCode == 304) {
      // For 304, response.body might be empty or null - check if body exists before parsing
      if (response.body != null && response.body is Map) {
        store = Store.fromJson(response.body as Map<String, dynamic>);
      }
      // If 304 with no body, return null and let controller handle cache fallback
    }
    return store;
  }

  @override
  Future<ItemModel?> getStoreItemList(
      int? storeID, int offset, int? categoryID, String type,
      {int? moduleId, int? limit, CancelToken? cancelToken}) async {
    ItemModel? storeItemModel;

    // Safely get module ID for cache key
    final int? effectiveModuleId =
        moduleId ?? Get.find<SplashController>().module?.id;

    if (effectiveModuleId == null) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ StoreRepository: Cannot load store items - module not set');
      }
      return null;
    }

    // Use provided limit or default to 200.
    // Special case: limit == 0 means "no limit / all items" (backend-supported for food menus).
    // For all other positive values we clamp within backend-safe bounds (1..50).
    final int requestedLimit = limit ?? 200;
    final int effectiveLimit =
        requestedLimit == 0 ? 0 : requestedLimit.clamp(1, 50);

    // 🔍 REQUEST ID for cross-layer tracing (backend + Flutter)
    final String requestId =
        'items_latest_${DateTime.now().millisecondsSinceEpoch}_store_${storeID}_cat_${categoryID}_off_${offset}_lim_${effectiveLimit}_mod_$effectiveModuleId';

    // Create cache key for this specific request (include limit to avoid cache conflicts).
    // Cache version bumped to v3 to invalidate old entries created before backend
    // merge/total_size fixes on store+category endpoints.
    final String cacheKey =
        'store_items_v3_${storeID}_${categoryID}_${offset}_${effectiveLimit}_${type}_$effectiveModuleId';

    // 🔍 DEBUG: Log cache check
    if (kDebugMode) {
      debugPrint('💾 [CACHE CHECK] Checking cache for store items');
      debugPrint('   🔑 Cache key: $cacheKey');
      debugPrint('   🆔 requestId: $requestId');
    }

    // Check cache first
    final String? cacheResponseData =
        await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
    if (cacheResponseData != null) {
      try {
        storeItemModel = ItemModel.fromJson(
            jsonDecode(cacheResponseData) as Map<String, dynamic>);
        final cachedItemCount = storeItemModel.items?.length ?? 0;
        final cachedTotalSize = storeItemModel.totalSize ?? 0;

        debugPrint(
            '\x1B[32m 🎯 Store Items Cache HIT: storeId=$storeID, categoryId=$categoryID, offset=$offset, type=$type, items=$cachedItemCount, totalSize=$cachedTotalSize \x1B[0m');

        // Cache invalidation logic: Check if cache is stale
        // This handles cases where:
        // 1. Cache has 0 items and this is the first page
        // 2. Cached items count is less than total_size (stale cache from before backend fix)
        // 3. When limit=0 (all items), cached items should match total_size
        bool shouldInvalidateCache = false;
        String? invalidationReason;

        if (cachedItemCount == 0 && offset == 1) {
          shouldInvalidateCache = true;
          invalidationReason = 'Cache has 0 items';
        } else if (offset == 1 &&
            cachedTotalSize > 0 &&
            cachedItemCount < cachedTotalSize) {
          // Cache is incomplete - total_size indicates more items should be available
          // This catches stale cache entries created before backend fix (when only 1 item was cached)
          shouldInvalidateCache = true;
          invalidationReason =
              'Cache incomplete: $cachedItemCount items cached but total_size=$cachedTotalSize';
        } else if (effectiveLimit == 0 && cachedItemCount < cachedTotalSize) {
          // When requesting all items (limit=0), cached items must match total_size
          shouldInvalidateCache = true;
          invalidationReason =
              'Requesting all items (limit=0) but cache incomplete: $cachedItemCount < $cachedTotalSize';
        }

        if (shouldInvalidateCache) {
          if (kDebugMode) {
            debugPrint('⚠️ Store Items Cache invalidated: $invalidationReason');
            debugPrint('   🔄 Clearing cache and fetching from API');
          }
          // Clear the cache and continue to API call
          await LocalClient.organize(
              DataSourceEnum.client, cacheKey, null, null);
          storeItemModel = null; // Force API call
        } else {
          return storeItemModel;
        }
      } catch (e) {
        debugPrint(
            '\x1B[31m ❌ Store Items Cache corrupted, fetching from API: $e \x1B[0m');
        // If cache is corrupted, continue to API call
      }
    } else {
      if (kDebugMode) {
        debugPrint('   ⚠️ Cache MISS - fetching from API');
      }
    }

    // 🔍 DEBUG: Log API request details
    // Use effectiveLimit as final page size; when 0 we explicitly pass 0 to request all items.
    final String limitParam = effectiveLimit.toString();
    final String categoryParam = (categoryID != null && categoryID != 0)
        ? '&category_id=$categoryID'
        : '';
    final apiUrl =
        '${AppConstants.storeItemUri}?store_id=$storeID$categoryParam&offset=$offset&limit=$limitParam&type=$type';
    if (kDebugMode) {
      debugPrint('');
      debugPrint('🌐 ============================================');
      debugPrint('🌐 [API CALL] Fetching store items from API');
      debugPrint('   🆔 Request ID: $requestId');
      debugPrint('   📍 URL: $apiUrl');
      debugPrint('   🏪 Store ID: $storeID');
      debugPrint(
          '   📂 Category ID: ${categoryID != null && categoryID != 0 ? categoryID : 'none'}');
      debugPrint('   📄 Offset: $offset');
      debugPrint('   🏷️ Type: $type');
      debugPrint(
          '   🔢 Limit: $limitParam${effectiveLimit == 0 ? ' (ALL ITEMS)' : ''}');
      debugPrint('   🆔 Module ID (from headers): $effectiveModuleId');
      debugPrint('🌐 ============================================');
      debugPrint('');
    }

    // 🔧 FIX: Check if request was cancelled before making API call
    if (cancelToken != null && cancelToken.isCancelled) {
      if (kDebugMode) {
        debugPrint('   🛑 Request cancelled before API call');
      }
      return null;
    }

    try {
      final startTime = DateTime.now();

      final Response response = await apiClient.getData(apiUrl);

      // 🔧 FIX: Check if request was cancelled after API call
      if (cancelToken != null && cancelToken.isCancelled) {
        if (kDebugMode) {
          debugPrint('   🛑 Request cancelled after API call, ignoring result');
        }
        return null;
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // 🔍 DEBUG: Log API response
      if (kDebugMode) {
        debugPrint('');
        debugPrint('📡 ============================================');
        debugPrint('📡 [API RESPONSE] Store items API response');
        debugPrint('   🆔 Request ID: $requestId');
        debugPrint('   ⏱️ Duration: ${duration}ms');
        debugPrint('   📊 Status Code: ${response.statusCode}');
        debugPrint('   📦 Response body type: ${response.body?.runtimeType}');
        if (response.headers != null && response.headers!.isNotEmpty) {
          final backendTime =
              response.headers!['X-Items-Latest-Backend-Time'] ??
                  response.headers!['x-items-latest-backend-time'];
          final cacheHeader = response.headers!['X-Items-Latest-Cache'] ??
              response.headers!['x-items-latest-cache'];
          final backendRequestId =
              response.headers!['X-Items-Latest-Request-Id'] ??
                  response.headers!['x-items-latest-request-id'];
          debugPrint('   🧩 Backend headers: '
              'backendTime=${backendTime ?? 'n/a'}, '
              'cache=${cacheHeader ?? 'n/a'}, '
              'backendRequestId=${backendRequestId ?? 'n/a'}');
        }

        if (response.statusCode == 200) {
          debugPrint('   ✅ Status: SUCCESS');
          if (response.body is Map) {
            final bodyMap = response.body as Map;
            debugPrint('   📋 Response keys: ${bodyMap.keys.toList()}');
            if (bodyMap.containsKey('items')) {
              final items = bodyMap['items'];
              if (items is List) {
                debugPrint('   📊 Items count: ${items.length}');
              }
            }
            if (bodyMap.containsKey('total_size')) {
              debugPrint('   📊 Total size: ${bodyMap['total_size']}');
            }
          }
        } else {
          debugPrint('   ❌ Status: FAILED');
          debugPrint('   ⚠️ Response body: ${response.body}');
        }
        debugPrint('📡 ============================================');
        debugPrint('');
      }

      if (response.statusCode == 200) {
        storeItemModel =
            ItemModel.fromJson(response.body as Map<String, dynamic>);

        // Cache the response for 10 minutes with proper JSON encoding
        await LocalClient.organize(DataSourceEnum.client, cacheKey,
            jsonEncode(response.body), apiClient.getHeader());
        debugPrint(
            '\x1B[32m 💾 Store Items cached: storeId=$storeID, categoryId=$categoryID, offset=$offset, items=${storeItemModel.items?.length ?? 0} \x1B[0m');
      } else {
        // 🔧 ERROR HANDLING: Non-200 status code
        if (kDebugMode) {
          debugPrint('');
          debugPrint('❌ ============================================');
          debugPrint('❌ [API ERROR] Non-200 status code');
          debugPrint('   🆔 Request ID: $requestId');
          debugPrint('   📊 Status: ${response.statusCode}');
          debugPrint('   📦 Body: ${response.body}');
          debugPrint(
              '   🔧 Returning empty ItemModel to prevent infinite loading');
          debugPrint('❌ ============================================');
          debugPrint('');
        }

        // Return empty model instead of null
        return ItemModel(
          items: [],
          totalSize: 0,
          offset: offset,
          limit: '13',
        );
      }
    } catch (e, stackTrace) {
      // 🔧 ERROR HANDLING: Network or parsing error
      if (kDebugMode) {
        debugPrint('');
        debugPrint('❌ ============================================');
        debugPrint('❌ [API EXCEPTION] Error fetching store items');
        debugPrint('   🆔 Request ID: $requestId');
        debugPrint('   ⚠️ Error: $e');
        debugPrint('   📋 Stack trace: $stackTrace');
        debugPrint(
            '   🔧 Returning empty ItemModel to prevent infinite loading');
        debugPrint('❌ ============================================');
        debugPrint('');
      }

      // Return empty model instead of null
      return ItemModel(
        items: [],
        totalSize: 0,
        offset: offset,
        limit: '13',
      );
    }

    return storeItemModel;
  }

  @override
  Future<StoreSubcategorySamplesModel?> getStoreSubcategoriesWithSamples({
    required int storeId,
    required int categoryId,
    int limit = 20,
    int offset = 1,
    int sampleSize = 3,
    String type = 'all',
    bool includeChildren = true,
  }) async {
    // Clamp parameters to backend-safe ranges.
    final int clampedLimit = limit.clamp(1, 50);
    final int clampedOffset = offset < 1 ? 1 : offset;
    final int clampedSampleSize = sampleSize.clamp(1, 5);
    final String includeChildrenParam = includeChildren ? 'true' : 'false';

    final String uri =
        '/api/v1/stores/$storeId/categories/$categoryId/subcategories-with-samples'
        '?limit=$clampedLimit'
        '&offset=$clampedOffset'
        '&sample_size=$clampedSampleSize'
        '&type=$type'
        '&include_children=$includeChildrenParam';

    final Response response = await apiClient.getData(uri);
    if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
      return StoreSubcategorySamplesModel.fromJson(
          response.body as Map<String, dynamic>);
    }
    if (response.statusCode == 200 && response.body is Map) {
      // Fallback for loosely typed maps.
      return StoreSubcategorySamplesModel.fromJson(
          Map<String, dynamic>.from(response.body as Map));
    }
    return null;
  }

  @override
  Future<ItemModel?> getStoreSearchItemList(String searchText, String? storeID,
      int offset, String type, int? categoryID) async {
    ItemModel? storeSearchItemModel;
    final Response response = await apiClient.getData(
        '${AppConstants.searchUri}items/search?store_id=$storeID&name=$searchText&offset=$offset&limit=10&type=$type&category_id=${categoryID ?? ''}');
    if (response.statusCode == 200) {
      storeSearchItemModel =
          ItemModel.fromJson(response.body as Map<String, dynamic>);
    }
    return storeSearchItemModel;
  }

  // =============================================================

  @override
  Future<Response> get_new_search_filtera(
      {required SearchFilterModel search_filterModel}) async {
    debugPrint('\x1B[32m  44444444444444444444444444444  \x1B[0m');

    debugPrint('\x1B[32m  /${search_filterModel.research_Name}  \x1B[0m');
    debugPrint('\x1B[32m  /${search_filterModel.product_arrangement}  \x1B[0m');
    debugPrint('\x1B[32m  /${search_filterModel.id_category}  \x1B[0m');
    debugPrint('\x1B[32m  /${search_filterModel.id_stores}  \x1B[0m');
    debugPrint('\x1B[32m  /${search_filterModel.min}  \x1B[0m');
    debugPrint('\x1B[32m  /${search_filterModel.max}  \x1B[0m');
    debugPrint('\x1B[32m  /${search_filterModel.discount}  \x1B[0m');

    final data = {
      'name': search_filterModel.research_Name,
      'product_arrangement': search_filterModel.product_arrangement,
      'id_category': search_filterModel.id_category,
      'id_stores': search_filterModel.id_stores,
      'min_price': search_filterModel.min,
      'max_price': search_filterModel.max,
      'discount': search_filterModel.discount,
    };

    const uri = '${AppConstants.searchUri}items/new-search';

    return await apiClient.postData(uri, data);
  }

  // =============================================================

  Future<RecommendedItemModel?> _getStoreRecommendedItemList(int? storeId,
      {CancelToken? cancelToken}) async {
    RecommendedItemModel? recommendedItemModel;
    final Response response = await apiClient.getData(
        '${AppConstants.storeRecommendedItemUri}?store_id=$storeId&offset=1&limit=50',
        cancelToken: cancelToken);
    if (response.statusCode == 200) {
      recommendedItemModel =
          RecommendedItemModel.fromJson(response.body as Map<String, dynamic>);
    }
    return recommendedItemModel;
  }

  @override
  Future<CartSuggestItemModel?> getCartStoreSuggestedItemList(
      int? storeId,
      String languageCode,
      ModuleModel? module,
      int? cacheModuleId,
      int? moduleId) async {
    CartSuggestItemModel? cartSuggestItemModel;
    final AddressModel? addressModel =
        AddressHelper.getUserAddressFromSharedPref();
    final Map<String, String> header = apiClient.updateHeader(
      sharedPreferences.getString(AppConstants.token),
      addressModel?.zoneIds,
      addressModel?.areaIds,
      languageCode,
      module == null ? cacheModuleId : moduleId,
      addressModel?.latitude,
      addressModel?.longitude,
      setHeader: false,
    );
    final Response response = await apiClient.getData(
        '${AppConstants.cartStoreSuggestedItemsUri}?recommended=1&store_id=$storeId&offset=1&limit=50',
        headers: header);
    if (response.statusCode == 200) {
      cartSuggestItemModel =
          CartSuggestItemModel.fromJson(response.body as Map<String, dynamic>);
    }
    return cartSuggestItemModel;
  }

  Future<List<StoreBannerModel>?> _getStoreBannerList(int? storeId,
      {CancelToken? cancelToken}) async {
    List<StoreBannerModel>? storeBanners;
    final Response response = await apiClient.getData(
        '${AppConstants.storeBannersUri}$storeId',
        cancelToken: cancelToken);
    if (response.statusCode == 200) {
      storeBanners = [];
      if (response.body is List) {
        for (var banner in (response.body as List)) {
          storeBanners
              .add(StoreBannerModel.fromJson(banner as Map<String, dynamic>));
        }
      }
    }
    return storeBanners;
  }

  Future<List<Store>?> _getRecommendedStoreList(
      {required DataSourceEnum source}) async {
    List<Store>? recommendedStoreList;
    final String cacheId =
        '${AppConstants.storeUri}/all?featured=1&offset=1&limit=50-${Get.find<SplashController>().module?.id ?? ''}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response =
            await apiClient.getData(AppConstants.recommendedStoreUri);
        if (response.statusCode == 200) {
          recommendedStoreList = [];
          if (response.body is Map && response.body['stores'] is List) {
            for (var store in (response.body['stores'] as List)) {
              recommendedStoreList
                  .add(Store.fromJson(store as Map<String, dynamic>));
            }
          }

          // ⚠️ CRITICAL: Client-side filtering by module ID
          recommendedStoreList = _filterStoresByModule(recommendedStoreList);

          // Cache the filtered results
          LocalClient.organize(
              DataSourceEnum.client,
              cacheId,
              jsonEncode(recommendedStoreList.map((s) => s.toJson()).toList()),
              apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          recommendedStoreList = [];
          final decodedCache = jsonDecode(cacheResponseData) as List;
          for (var store in decodedCache) {
            recommendedStoreList
                .add(Store.fromJson(store as Map<String, dynamic>));
          }

          // ⚠️ CRITICAL: Filter cached stores by module ID too
          recommendedStoreList = _filterStoresByModule(recommendedStoreList);
        }
    }

    return recommendedStoreList;
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
  Future get(String? id) {
    throw UnimplementedError();
  }

  Future<List<CategoryModel>?> _getSubCategoryList({String? parentID}) async {
    List<CategoryModel>? subCategoryList;

    final Response response =
        await apiClient.getData('${AppConstants.subCategoryUri}$parentID');
    if (response.statusCode == 200) {
      subCategoryList = [];

      if (response.body is List) {
        for (var category in (response.body as List)) {
          subCategoryList
              .add(CategoryModel.fromJson(category as Map<String, dynamic>));
        }
      }
    }
    return subCategoryList;
  }

  @override
  Future<SlimMenuResponse?> getSlimMenu(int? storeId,
      {int? moduleId, CancelToken? cancelToken}) async {
    if (storeId == null) {
      if (kDebugMode) {
        debugPrint('⚠️ StoreRepository: getSlimMenu() - Store ID is null');
      }
      return null;
    }

    final int? effectiveModuleId =
        moduleId ?? Get.find<SplashController>().module?.id;

    if (effectiveModuleId == null) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ StoreRepository: Cannot load slim menu - module not set');
      }
      return null;
    }

    // 🎯 TASK 1: Get zoneId and languageCode for v2 cache key
    final AddressModel? addressModel =
        AddressHelper.getUserAddressFromSharedPref();
    final List<int>? zoneIds = addressModel?.zoneIds;
    final String zoneId =
        zoneIds != null && zoneIds.isNotEmpty ? zoneIds.join('_') : 'default';
    final String languageCode =
        sharedPreferences.getString(AppConstants.languageCode) ?? 'en';

    // 🎯 TASK 1: Cache key for slim menu v2 with zone filtering
    // This forces cache miss for old v1 cache keys and ensures zone-specific data
    final String cacheKey = 'slim_menu_v2_${storeId}_${zoneId}_$languageCode';

    // Check cache first
    final String? cacheResponseData =
        await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
    if (cacheResponseData != null) {
      try {
        final cachedModel = SlimMenuResponse.fromJson(
            jsonDecode(cacheResponseData) as Map<String, dynamic>);
        if (kDebugMode) {
          debugPrint(
              '\x1B[32m 🎯 Slim Menu Cache HIT: storeId=$storeId, items=${cachedModel.totalItems}, categories=${cachedModel.totalCategories} \x1B[0m');
        }
        return cachedModel;
      } catch (e) {
        debugPrint(
            '\x1B[31m ❌ Slim Menu Cache corrupted, fetching from API: $e \x1B[0m');
      }
    } else {
      // 🎯 TASK 4: Log cache MISS to verify v2 cache key is working
      if (kDebugMode) {
        debugPrint(
            '\x1B[33m 🎯 Slim Menu Cache MISS -> Fetching from API (v2 cache key: $cacheKey) \x1B[0m');
      }
    }

    // Build API URL - endpoint is /api/v1/stores/details/{storeId}/slim-menu
    final apiUrl = '${AppConstants.storeDetailsUri}$storeId/slim-menu';

    if (kDebugMode) {
      debugPrint('');
      debugPrint('🌐 ============================================');
      debugPrint('🌐 [API CALL] Fetching slim menu from API');
      debugPrint('   📍 URL: $apiUrl');
      debugPrint('   🏪 Store ID: $storeId');
      debugPrint('   🆔 Module ID: $effectiveModuleId');
      debugPrint('🌐 ============================================');
      debugPrint('');
    }

    try {
      final startTime = DateTime.now();
      final Response response =
          await apiClient.getData(apiUrl, cancelToken: cancelToken);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      if (kDebugMode) {
        debugPrint('');
        debugPrint('📡 ============================================');
        debugPrint('📡 [API RESPONSE] Slim menu API response');
        debugPrint('   ⏱️ Duration: ${duration}ms');
        debugPrint('   📊 Status Code: ${response.statusCode}');
        debugPrint('📡 ============================================');
        debugPrint('');
      }

      if (response.statusCode == 200) {
        // 🎯 TASK 2: Smart parsing - use isolate for 560KB payload to prevent spinner freeze
        final responseBody = response.body;
        final responseSize = responseBody is String
            ? responseBody.length
            : (jsonEncode(responseBody).length);

        SlimMenuResponse slimMenuModel;
        // 560KB payload requires isolate parsing to avoid ~200ms main thread block
        if (responseSize > 10 * 1024) {
          // Large response - parse in isolate to prevent frame drops
          if (kDebugMode) {
            debugPrint(
                '⚡ [StoreRepository] Large slim menu response ($responseSize bytes) - parsing in isolate');
          }
          final jsonMap = await JsonIsolateHelper.parseUnifiedPayload(
              responseBody is String ? responseBody : jsonEncode(responseBody));
          slimMenuModel = SlimMenuResponse.fromJson(jsonMap);
        } else {
          // Small response - parse on main thread (faster than isolate overhead)
          slimMenuModel =
              SlimMenuResponse.fromJson(response.body as Map<String, dynamic>);
        }

        if (kDebugMode) {
          debugPrint(
              '✅ Slim Menu loaded: ${slimMenuModel.totalItems} items, ${slimMenuModel.totalCategories} categories');
        }

        // Cache the response
        await LocalClient.organize(DataSourceEnum.client, cacheKey,
            jsonEncode(response.body), apiClient.getHeader());

        return slimMenuModel;
      } else {
        if (kDebugMode) {
          debugPrint(
              '❌ Slim Menu API failed with status: ${response.statusCode}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [API EXCEPTION] Error fetching slim menu');
        debugPrint('   ⚠️ Error: $e');
        debugPrint('   📋 Stack trace: $stackTrace');
      }
      return null;
    }
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
