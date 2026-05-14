
import 'dart:convert';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/features/offers/domain/reposotories/offers_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:flutter/foundation.dart';

import '../../../item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/json_isolate_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';

class OffersRepository implements OffersRepositoryInterface {
  final ApiClient apiClient;
  final Map<int, DateTime> _lastETagClearAt = <int, DateTime>{};
  static const Duration _etagClearCooldown = Duration(seconds: 30);

  OffersRepository({required this.apiClient});

  // -----------------------------

  String fixImageUrl(String? url, {String? baseDomain}) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmedUrl = url.trim();
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return trimmedUrl;
    }
    final String resolvedBase = baseDomain ??
        '${AppConstants.baseUrl}/storage/offers-banners/';
    final cleanedBase = resolvedBase.endsWith('/')
        ? resolvedBase.substring(0, resolvedBase.length - 1)
        : resolvedBase;
    final cleanedUrl =
        trimmedUrl.startsWith('/') ? trimmedUrl.substring(1) : trimmedUrl;
    return '$cleanedBase/$cleanedUrl';
  }

  @override
  Future<OffersModel> getOffers() async {
    try {
      OffersModel offersModel =
          OffersModel(success: false, data: [], message: '');
      int? currentModuleId;
      if (Get.isRegistered<SplashController>()) {
        currentModuleId = Get.find<SplashController>().module?.id;
      }

      final Response response = await apiClient.getData(AppConstants.offersUri);

      // 🔧 FIX: Handle 304 Not Modified - load from Hive cache for CURRENT module only
      if (response.statusCode == 304) {
        if (kDebugMode) {
          debugPrint(
              '✅ Offers_Repository: 304 Not Modified received - loading from Hive cache');
        }

        OffersModel? cachedOffers;
        final cacheService = HiveHomeCacheService();

        try {
          // Use current module ID only (no cross-module fallback)
          final moduleId = currentModuleId;

          if (moduleId != null) {
            cachedOffers = await cacheService.loadOffers(moduleId);
            if (cachedOffers != null && cachedOffers.data.isNotEmpty) {
              if (kDebugMode) {
                debugPrint(
                    '✅ Offers_Repository: Loaded ${cachedOffers.data.length} offers from Hive cache (moduleId: $moduleId)');
              }
            } else {
              if (kDebugMode) {
                debugPrint(
                    '⚠️ Offers_Repository: No cached offers found for moduleId: $moduleId');
              }
            }
          }

          // If we found cached offers, fix image URLs and return
          if (cachedOffers != null && cachedOffers.data.isNotEmpty) {
            // Fix image URLs for cached data
            for (int i = 0; i < cachedOffers.data.length; i++) {
              final old = cachedOffers.data[i];
              cachedOffers.data[i] = Datum(
                id: old.id,
                reference: old.reference,
                name: old.name,
                startDate: old.startDate,
                endDate: old.endDate,
                discountMax: old.discountMax,
                banner: fixImageUrl(old.banner),
                createdAt: old.createdAt,
                updatedAt: old.updatedAt,
                itemsCount: old.itemsCount,
                active: old.active,
                status: old.status,
              );
            }

            return cachedOffers;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Offers_Repository: Error loading from cache on 304: $e');
          }
        }

        // Cache is missing while server returns 304.
        // Clear endpoint ETag once and retry without ETag to repair cache.
        if (kDebugMode) {
          debugPrint(
              '⚠️ Offers_Repository: 304 received but cache missing - clearing ETag and forcing fresh fetch');
        }

        try {
          if (currentModuleId != null) {
            final now = DateTime.now();
            final lastClearAt = _lastETagClearAt[currentModuleId];
            if (lastClearAt != null &&
                now.difference(lastClearAt) < _etagClearCooldown) {
              final remainingSeconds =
                  (_etagClearCooldown - now.difference(lastClearAt)).inSeconds;
              if (kDebugMode) {
                debugPrint(
                    '⏸️ Offers_Repository: ETag clear on cooldown for module $currentModuleId (${remainingSeconds}s remaining)');
              }
              return OffersModel(
                success: true,
                data: <Datum>[],
                message: 'ETag clear cooldown active',
              );
            }
          }

          await cacheService.clearETagForUri(AppConstants.offersUri);
          if (currentModuleId != null) {
            _lastETagClearAt[currentModuleId] = DateTime.now();
          }
          final Response retryResponse =
              await apiClient.getData(AppConstants.offersUri, useEtag: false);
          if (retryResponse.statusCode == 200 ||
              retryResponse.statusCode == 201) {
            final body = retryResponse.body;
            if (body is Map<String, dynamic>) {
              OffersModel freshOffers = OffersModel.fromJson(body);
              for (int i = 0; i < freshOffers.data.length; i++) {
                final old = freshOffers.data[i];
                freshOffers.data[i] = Datum(
                  id: old.id,
                  reference: old.reference,
                  name: old.name,
                  startDate: old.startDate,
                  endDate: old.endDate,
                  discountMax: old.discountMax,
                  banner: fixImageUrl(old.banner),
                  createdAt: old.createdAt,
                  updatedAt: old.updatedAt,
                  itemsCount: old.itemsCount,
                  active: old.active,
                  status: old.status,
                );
              }

              if (currentModuleId != null) {
                await HiveHomeCacheService()
                    .saveOffers(currentModuleId, freshOffers);
              }

              return freshOffers;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ Offers_Repository: Fresh fetch failed after 304 cache miss: $e');
          }
        }

        return OffersModel(
            success: false,
            data: [],
            message:
                '304 Not Modified - cache unavailable and fresh fetch failed');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final body = response.body;
          if (body is! Map<String, dynamic>) {
            if (kDebugMode) {
              debugPrint(
                  '❌ Offers_Repository.getOffers: Response body is not Map<String, dynamic>');
            }
            return OffersModel(
                success: false, data: [], message: 'Invalid response format');
          }
          offersModel = OffersModel.fromJson(body);

          // ✅ تحديث رابط الصورة لكل عرض
          for (int i = 0; i < offersModel.data.length; i++) {
            final old = offersModel.data[i];
            offersModel.data[i] = Datum(
              id: old.id,
              reference: old.reference,
              name: old.name,
              startDate: old.startDate,
              endDate: old.endDate,
              discountMax: old.discountMax,
              banner: fixImageUrl(old.banner),
              createdAt: old.createdAt,
              updatedAt: old.updatedAt,
              itemsCount: old.itemsCount,
              active: old.active,
              status: old.status,
            );
          }

          if (currentModuleId != null) {
            await HiveHomeCacheService()
                .saveOffers(currentModuleId, offersModel);
          }

          return offersModel;
        } catch (e) {
          debugPrint('❌ Error parsing offers JSON: $e');
          // Return empty offers model instead of throwing
          return OffersModel(
              success: false, data: [], message: 'Failed to parse offers data');
        }
      } else {
        debugPrint('❌ Offers API failed with status code: ${response.statusCode}');
        // Return empty offers model instead of throwing
        return OffersModel(
            success: false, data: [], message: 'Failed to load offers');
      }
    } catch (e) {
      debugPrint('❌ Error in getOffers: $e');
      // Return empty offers model instead of throwing
      return OffersModel(success: false, data: [], message: 'Network error');
    }
  }

  @override
  Future<ItemModel?> getOffersItem({
    int? offset,
    int? limit,
    String? id,
    bool forceRefresh = false,
  }) async {
    ItemModel? offersItem;
    final uri =
        '${AppConstants.offersItemUri}$id/newitems?offset=$offset&limit=$limit';

    Future<ItemModel?> parseOffersItems(Response response) async {
      // Debug: Print the raw API response to see what we're receiving
      if (kDebugMode) {
        debugPrint('🔍 Offers API Endpoint: $uri');
      }

      // ⚡ TASK 2: Parse JSON in isolate to prevent main-thread jank
      // ⚡ NEW API: Use slim parser for offers items (6 fields only: id, name, image_full_url, price, discount, avg_rating)
      // Convert response.body to JSON string if it's already a Map
      String jsonString;
      final body = response.body;
      if (body is Map<String, dynamic>) {
        jsonString = jsonEncode(body);
      } else if (body is String) {
        jsonString = body;
      } else {
        // Fallback: try to convert to string
        try {
          jsonString = body.toString();
          // If it's not valid JSON, try jsonEncode
          if (!jsonString.trim().startsWith('{') &&
              !jsonString.trim().startsWith('[')) {
            jsonString = jsonEncode(body);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ Offers_Repository: Cannot convert response body to JSON string: $e');
          }
          return null;
        }
      }

      // Parse slim offers items in isolate (handles new API structure: products_count, products)
      final parsed =
          await JsonIsolateHelper.parseSlimOffersItemModel(jsonString);

      if (kDebugMode) {
        debugPrint(
            '✅ Offers_Repository: Parsed ${parsed?.items?.length ?? 0} slim items in isolate (total: ${parsed?.totalSize ?? 0})');
      }
      return parsed;
    }

    final Response response = await apiClient.getData(
      uri,
      useEtag: !forceRefresh,
    );
    if (response.statusCode == 200) {
      offersItem = await parseOffersItems(response);
    } else if (response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Offers_Repository: 304 Not Modified for offers items (id=$id, offset=$offset). Retrying without ETag.');
      }
      final Response freshResponse =
          await apiClient.getData(uri, useEtag: false);
      if (freshResponse.statusCode == 200) {
        offersItem = await parseOffersItems(freshResponse);
      } else if (kDebugMode) {
        debugPrint(
            '❌ Offers_Repository: Fresh retry after 304 failed (status=${freshResponse.statusCode})');
      }
    }
    return offersItem;
  }

  @override
  Future<ItemModel?> getOffersSearchItemList(String searchText, String? offerId,
      int offset, String type, int categoryId) async {
    final String encodedQuery = Uri.encodeQueryComponent(searchText.trim());
    String url =
        '${AppConstants.offersItemUri}$offerId/search?query=$encodedQuery&offset=$offset&limit=20';
    if (type.isNotEmpty && type != 'all') {
      url += '&filter=$type';
    }
    if (categoryId != 0) {
      url += '&category_ids=$categoryId';
    }

    ItemModel? parseSearchResponse(Response response) {
      final body = response.body;
      if (body is Map<String, dynamic>) {
        try {
          return ItemModel.fromJson(body);
        } catch (e) {
          debugPrint('? Error parsing offers search response: $e');
          return null;
        }
      } else if (body is String) {
        debugPrint(
            '? API returned HTML instead of JSON for search. This indicates a server error.');
        debugPrint('Response body preview: ${body.safeSubstring(100)}');
        return null;
      } else {
        debugPrint('? Unexpected search response body type: ${body.runtimeType}');
        return null;
      }
    }

    final Response response = await apiClient.getData(url);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return parseSearchResponse(response);
    } else if (response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint(
            '?? Offers_Repository: 304 Not Modified for offers search. Trying cache body then retry without ETag.');
      }

      final ItemModel? cached = parseSearchResponse(response);
      if (cached != null) {
        return cached;
      }

      final Response freshResponse =
          await apiClient.getData(url, useEtag: false);
      if (freshResponse.statusCode == 200 || freshResponse.statusCode == 201) {
        return parseSearchResponse(freshResponse);
      }

      debugPrint(
          '? Offers search retry without ETag failed with status: ${freshResponse.statusCode}');
      return null;
    } else {
      debugPrint(
          '? Search API call failed with status code: ${response.statusCode}');
      return null;
    }
  }

  @override
  Future<ItemModel?> getOffersItemWithFilters({
    String? id,
    int? offset,
    int? limit,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  }) async {
    ItemModel? offersItem;
    String url =
        '${AppConstants.offersItemUri}$id/search?offset=$offset&limit=${limit ?? 20}';

    // Add search parameters for filtering
    if (categoryId != null && categoryId != '0') {
      url += '&category_ids=$categoryId';
    }
    if (sortBy != null) {
      url += '&sort_by=$sortBy';
    }
    if (sortOrder != null) {
      url += '&sort_order=$sortOrder';
    }

    final Response response = await apiClient.getData(url);
    if (response.statusCode == 200) {
      // Check if response body is valid JSON (Map) or HTML (String)
      final body = response.body;
      if (body is Map<String, dynamic>) {
        try {
          offersItem = ItemModel.fromJson(body);
        } catch (e) {
          debugPrint('❌ Error parsing offers item response: $e');
          return null;
        }
      } else if (response.body is String) {
        // Handle HTML response (server error page)
        debugPrint(
            '❌ API returned HTML instead of JSON. This indicates a server error.');
        debugPrint(
            'Response body preview: ${response.body.toString().safeSubstring(100)}');
        return null;
      } else {
        debugPrint('❌ Unexpected response body type: ${response.body.runtimeType}');
        return null;
      }
    } else {
      debugPrint('❌ API call failed with status code: ${response.statusCode}');
      return null;
    }
    return offersItem;
  }
//
}
