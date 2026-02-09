// ignore_for_file: file_names, non_constant_identifier_names, avoid_print, use_build_context_synchronously, depend_on_referenced_packages, annotate_overrides, unused_local_variable, empty_catches, override_on_non_overriding_member

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

  OffersRepository({required this.apiClient});

  // -----------------------------

  String fixImageUrl(String? url,
      {String baseDomain =
          'https://dev.shelafood.com/storage/offers-banners/'}) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmedUrl = url.trim();
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return trimmedUrl;
    }
    final cleanedBase = baseDomain.endsWith('/')
        ? baseDomain.substring(0, baseDomain.length - 1)
        : baseDomain;
    final cleanedUrl =
        trimmedUrl.startsWith('/') ? trimmedUrl.substring(1) : trimmedUrl;
    return '$cleanedBase/$cleanedUrl';
  }

  @override
  Future<OffersModel> getOffers() async {
    try {
      OffersModel offersModel =
          OffersModel(success: false, data: [], message: '');

      final Response response = await apiClient.getData(AppConstants.offersUri);

      // 🔧 FIX: Handle 304 Not Modified - load from Hive cache for CURRENT module only
      if (response.statusCode == 304) {
        if (kDebugMode) {
          print(
              '✅ Offers_Repository: 304 Not Modified received - loading from Hive cache');
        }

        OffersModel? cachedOffers;
        final cacheService = HiveHomeCacheService();

        try {
          // Use current module ID only (no cross-module fallback)
          int? moduleId;
          if (Get.isRegistered<SplashController>()) {
            final splashController = Get.find<SplashController>();
            moduleId = splashController.module?.id;
          }

          if (moduleId != null) {
            cachedOffers = await cacheService.loadOffers(moduleId);
            if (cachedOffers != null && cachedOffers.data.isNotEmpty) {
              if (kDebugMode) {
                print(
                    '✅ Offers_Repository: Loaded ${cachedOffers.data.length} offers from Hive cache (moduleId: $moduleId)');
              }
            } else {
              if (kDebugMode) {
                print(
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
            print('❌ Offers_Repository: Error loading from cache on 304: $e');
          }
        }

        // TEMP: LOOP PREVENTION DISABLED - force fresh fetch if cache is missing
        if (kDebugMode) {
          print(
              '⚠️ Offers_Repository: 304 received but cache missing - forcing fresh fetch (loop prevention disabled)');
        }

        try {
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

              if (Get.isRegistered<SplashController>()) {
                final moduleId = Get.find<SplashController>().module?.id;
                if (moduleId != null) {
                  await HiveHomeCacheService()
                      .saveOffers(moduleId, freshOffers);
                }
              }

              return freshOffers;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
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
              print(
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

          if (Get.isRegistered<SplashController>()) {
            final moduleId = Get.find<SplashController>().module?.id;
            if (moduleId != null) {
              await HiveHomeCacheService().saveOffers(moduleId, offersModel);
            }
          }

          return offersModel;
        } catch (e) {
          print('❌ Error parsing offers JSON: $e');
          // Return empty offers model instead of throwing
          return OffersModel(
              success: false, data: [], message: 'Failed to parse offers data');
        }
      } else {
        print('❌ Offers API failed with status code: ${response.statusCode}');
        // Return empty offers model instead of throwing
        return OffersModel(
            success: false, data: [], message: 'Failed to load offers');
      }
    } catch (e) {
      print('❌ Error in getOffers: $e');
      // Return empty offers model instead of throwing
      return OffersModel(success: false, data: [], message: 'Network error');
    }
  }

  @override
  Future<ItemModel?> getOffersItem(
      {int? offset, int? limit, String? id}) async {
    ItemModel? offersItem;
    final Response response = await apiClient.getData(
      '${AppConstants.offersItemUri}$id/newitems?offset=$offset&limit=$limit',
    );
    if (response.statusCode == 200) {
      // Debug: Print the raw API response to see what we're receiving
      if (kDebugMode) {
        print(
            '🔍 Offers API Endpoint: ${AppConstants.offersItemUri}$id/newitems?offset=$offset&limit=$limit');
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
            print(
                '❌ Offers_Repository: Cannot convert response body to JSON string: $e');
          }
          return null;
        }
      }

      // Parse slim offers items in isolate (handles new API structure: products_count, products)
      offersItem = await JsonIsolateHelper.parseSlimOffersItemModel(jsonString);

      if (kDebugMode) {
        print(
            '✅ Offers_Repository: Parsed ${offersItem?.items?.length ?? 0} slim items in isolate (total: ${offersItem?.totalSize ?? 0})');
      }
    }
    return offersItem;
  }

  @override
  Future<ItemModel?> getOffersSearchItemList(String searchText, String? offerId,
      int offset, String type, int categoryId) async {
    ItemModel? offersSearchItem;
    String url =
        '${AppConstants.offersItemUri}$offerId/search?query=$searchText&offset=$offset&limit=20&filter=$type';
    if (categoryId != 0) {
      url += '&category_ids=$categoryId';
    }

    final Response response = await apiClient.getData(url);
    if (response.statusCode == 200) {
      // Check if response body is valid JSON (Map) or HTML (String)
      final body = response.body;
      if (body is Map<String, dynamic>) {
        try {
          offersSearchItem = ItemModel.fromJson(body);
        } catch (e) {
          print('❌ Error parsing offers search response: $e');
          return null;
        }
      } else if (response.body is String) {
        // Handle HTML response (server error page)
        print(
            '❌ API returned HTML instead of JSON for search. This indicates a server error.');
        print(
            'Response body preview: ${response.body.toString().safeSubstring(100)}');
        return null;
      } else {
        print(
            '❌ Unexpected search response body type: ${response.body.runtimeType}');
        return null;
      }
    } else {
      print(
          '❌ Search API call failed with status code: ${response.statusCode}');
      return null;
    }
    return offersSearchItem;
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
          print('❌ Error parsing offers item response: $e');
          return null;
        }
      } else if (response.body is String) {
        // Handle HTML response (server error page)
        print(
            '❌ API returned HTML instead of JSON. This indicates a server error.');
        print(
            'Response body preview: ${response.body.toString().safeSubstring(100)}');
        return null;
      } else {
        print('❌ Unexpected response body type: ${response.body.runtimeType}');
        return null;
      }
    } else {
      print('❌ API call failed with status code: ${response.statusCode}');
      return null;
    }
    return offersItem;
  }
//
}
