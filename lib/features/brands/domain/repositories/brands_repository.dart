import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/brands/domain/repositories/brands_repository_interface.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class BrandsRepository implements BrandsRepositoryInterface {
  final ApiClient apiClient;
  BrandsRepository({required this.apiClient});
  static bool _brandsEndpointAvailable = true;

  @override
  Future<List<BrandModel>?> getBrandList(
      {required DataSourceEnum source}) async {
    List<BrandModel>? brandList;
    
    if (!_brandsEndpointAvailable) {
      if (kDebugMode) {
        appLogger.debug(
            '🏷️ BrandsRepository: Brands endpoint unavailable (404), skipping request');
      }
      return brandList ?? <BrandModel>[];
    }

    // ⚠️ CRITICAL: Handle null module case (when on multi-module selection screen)
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id ?? 3; // Default to module 3 if no module selected
    final String cacheId = '${AppConstants.brandListUri}-$moduleId';

    switch (source) {
      case DataSourceEnum.client:
        // 🔍 DEBUG: Log request details to diagnose empty response
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug('🏷️ BrandsRepository: Making API call to ${AppConstants.brandListUri}');
          appLogger.debug('🏷️ BrandsRepository: Current moduleId = $moduleId');
          appLogger.debug('🏷️ BrandsRepository: Headers being sent:');
          final headers = apiClient.getHeader();
          headers.forEach((key, value) {
            appLogger.debug('   - $key: $value');
          });
        }
        
        final Response response = await apiClient.getData(AppConstants.brandListUri);
        
        // 🔍 DEBUG: Log response details
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug('🏷️ BrandsRepository: API Response:');
          appLogger.debug('   - Status Code: ${response.statusCode}');
          appLogger.debug('   - Response Type: ${response.body.runtimeType}');
          if (response.body is List) {
            appLogger.debug('   - Array Length: ${response.body.length}');
          }
          appLogger.debug('   - Raw Response: ${response.body}');
        }
        
        if (response.statusCode == 404) {
          _brandsEndpointAvailable = false;
          if (kDebugMode) {
            appLogger.warning(
                '🏷️ BrandsRepository: Endpoint not found (404). Disabling brands requests.');
          }
          return <BrandModel>[];
        }
        if (response.statusCode == 200) {
          brandList = [];
          if (response.body is List) {
            for (var brand in (response.body as List)) {
              brandList.add(BrandModel.fromJson(brand as Map<String, dynamic>));
            }
          }
          
          // 🔍 DEBUG: Log parsed results
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug('🏷️ BrandsRepository: Parsed ${brandList.length} brands');
            if (brandList.isNotEmpty) {
              appLogger.debug('🏷️ BrandsRepository: Sample brands:');
              for (int i = 0; i < (brandList.length > 3 ? 3 : brandList.length); i++) {
                final brand = brandList[i];
                appLogger.debug('   - Brand ${brand.id}: "${brand.name}" (image: ${brand.imageFullUrl})');
              }
            } else {
              appLogger.warning('⚠️ BrandsRepository: Backend returned EMPTY array!');
              appLogger.warning('⚠️ Possible causes:');
              appLogger.warning('   1. No brands configured for moduleId=$moduleId in backend database');
              appLogger.warning('   2. Backend filtering brands incorrectly');
              appLogger.warning('   3. Backend requires different header format');
              appLogger.warning('   4. Zone or other filter preventing brands from being returned');
            }
          }
          
          LocalClient.organize(source, cacheId, jsonEncode(response.body),
              apiClient.getHeader());
        }
        break;

      case DataSourceEnum.local:
        final String? cacheResponseData =
            await LocalClient.organize(source, cacheId, null, null);
        if (cacheResponseData != null) {
          brandList = [];
          final decoded = jsonDecode(cacheResponseData) as List;
          for (var brand in decoded) {
            brandList.add(BrandModel.fromJson(brand as Map<String, dynamic>));
          }
          if (kDebugMode) {
            appLogger.debug('🏷️ BrandsRepository: Loaded ${brandList.length} brands from cache');
          }
        }
        break;
    }

    return brandList;
  }

  @override
  Future<ItemModel?> getBrandItemList(
      {required int brandId, int? offset, int? limit}) async {
    ItemModel? brandItemModel;
    final int effectiveOffset = offset ?? 1;
    final int effectiveLimit = limit ?? 12;

    // Create cache key for this specific request
    final String cacheKey =
        'brand_items_${brandId}_${effectiveOffset}_${effectiveLimit}_${Get.find<SplashController>().module!.id!}';

    // Check cache first
    final String? cacheResponseData =
        await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
    if (cacheResponseData != null) {
      try {
        brandItemModel = ItemModel.fromJson(jsonDecode(cacheResponseData) as Map<String, dynamic>);
        
        // Verify cache has original_price data (backend added this field recently)
        final bool hasOriginalPrice = brandItemModel.items?.isNotEmpty == true && 
                                brandItemModel.items!.first.originalPrice != null;
        
        if (hasOriginalPrice) {
          if (kDebugMode) {
            appLogger.debug('🎯 Brand Items Cache HIT: brandId=$brandId, offset=$offset');
          }
          return brandItemModel;
        } else {
          if (kDebugMode) {
            appLogger.debug('🔄 Cache missing original_price field, refetching from API');
          }
          // Continue to API call to get fresh data with original_price
        }
      } catch (e) {
        if (kDebugMode) {
          appLogger.warning('❌ Brand Items Cache corrupted, fetching from API: $e');
        }
        // If cache is corrupted, continue to API call
      }
    }

    // If not cached or corrupted, fetch from API
    // 🔧 FIX: brand_id must be path parameter, not query parameter
    // Route: GET /api/v1/brand/items/{brand_id} (not /api/v1/brand/items?brand_id=...)
    final Response response = await apiClient.getData(
        '${AppConstants.brandItemUri}/$brandId?offset=$effectiveOffset&limit=$effectiveLimit');
    if (response.statusCode == 200) {
      brandItemModel = ItemModel.fromJson(response.body as Map<String, dynamic>);

      // Cache the response for 10 minutes
      await LocalClient.organize(DataSourceEnum.client, cacheKey,
          jsonEncode(response.body), apiClient.getHeader());
      if (kDebugMode) {
        appLogger.debug(
            '💾 Brand Items cached: brandId=$brandId, offset=$offset, items=${brandItemModel.items?.length ?? 0}');
      }
    }
    return brandItemModel;
  }

  @override
  Future<ItemModel?> getBrandSearchItemList({
    required String searchText,
    required int brandId,
    int? offset,
    String? type,
    int? categoryId,
  }) async {
    ItemModel? brandSearchItemModel;

    // Create cache key for search request
    final String cacheKey =
        'brand_search_${brandId}_${searchText}_${offset ?? 1}_${categoryId ?? 0}_${Get.find<SplashController>().module!.id!}';

    // Check cache first
    final String? cacheResponseData =
        await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
    if (cacheResponseData != null) {
      try {
        brandSearchItemModel =
            ItemModel.fromJson(jsonDecode(cacheResponseData) as Map<String, dynamic>);
        
        // Verify cache has original_price data (backend added this field recently)
        final bool hasOriginalPrice = brandSearchItemModel.items?.isNotEmpty == true && 
                                brandSearchItemModel.items!.first.originalPrice != null;
        
        if (hasOriginalPrice) {
          if (kDebugMode) {
            appLogger.debug(
                '🎯 Brand Search Cache HIT: brandId=$brandId, searchText=$searchText');
          }
          return brandSearchItemModel;
        } else {
          if (kDebugMode) {
            appLogger.debug('🔄 Search cache missing original_price field, refetching from API');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          appLogger.warning('❌ Brand Search Cache corrupted, fetching from API: $e');
        }
      }
    }

    // Build query parameters (brand_id is path parameter, not query)
    String queryParams =
        'search=$searchText&offset=${offset ?? 1}&limit=12';
    if (type != null && type.isNotEmpty) {
      queryParams += '&type=$type';
    }
    if (categoryId != null && categoryId > 0) {
      queryParams += '&category_id=$categoryId';
    }

    // 🔧 FIX: brand_id must be path parameter, not query parameter
    // Route: GET /api/v1/brand/items/search/{brand_id} (not /api/v1/brand/items/search?brand_id=...)
    final Response response = await apiClient
        .getData('${AppConstants.brandSearchItemUri}/$brandId?$queryParams');
    if (response.statusCode == 200) {
      brandSearchItemModel = ItemModel.fromJson(response.body as Map<String, dynamic>);

      // Cache the response for 5 minutes (shorter than regular items)
      await LocalClient.organize(DataSourceEnum.client, cacheKey,
          jsonEncode(response.body), apiClient.getHeader());
      if (kDebugMode) {
        appLogger.debug(
            '💾 Brand Search cached: brandId=$brandId, searchText=$searchText, items=${brandSearchItemModel.items?.length ?? 0}');
      }
    }
    return brandSearchItemModel;
  }

  @override
  Future<ItemModel?> getBrandItemWithFilters({
    required int brandId,
    int? offset,
    int? limit,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  }) async {
    ItemModel? brandFilterItemModel;

    // Create cache key for filter request
    final String cacheKey =
        'brand_filter_${brandId}_${offset ?? 1}_${categoryId ?? 'all'}_${sortBy ?? 'default'}_${sortOrder ?? 'asc'}_${Get.find<SplashController>().module!.id!}';

    // Check cache first
    final String? cacheResponseData =
        await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
    if (cacheResponseData != null) {
      try {
        brandFilterItemModel =
            ItemModel.fromJson(jsonDecode(cacheResponseData) as Map<String, dynamic>);
        
        // Verify cache has original_price data (backend added this field recently)
        final bool hasOriginalPrice = brandFilterItemModel.items?.isNotEmpty == true && 
                                brandFilterItemModel.items!.first.originalPrice != null;
        
        if (hasOriginalPrice) {
          if (kDebugMode) {
            appLogger.debug(
                '🎯 Brand Filter Cache HIT: brandId=$brandId, categoryId=$categoryId');
          }
          return brandFilterItemModel;
        } else {
          if (kDebugMode) {
            appLogger.debug('🔄 Filter cache missing original_price field, refetching from API');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          appLogger.warning('❌ Brand Filter Cache corrupted, fetching from API: $e');
        }
      }
    }

    // Build query parameters (brand_id is path parameter, not query)
    String queryParams =
        'offset=${offset ?? 1}&limit=${limit ?? 12}';
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      queryParams += '&category_id=$categoryId';
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams += '&sort_by=$sortBy';
    }
    if (sortOrder != null && sortOrder.isNotEmpty) {
      queryParams += '&sort_order=$sortOrder';
    }

    // 🔧 FIX: brand_id must be path parameter, not query parameter
    // Route: GET /api/v1/brand/items/filter/{brand_id} (not /api/v1/brand/items/filter?brand_id=...)
    final Response response = await apiClient
        .getData('${AppConstants.brandFilterItemUri}/$brandId?$queryParams');
    if (response.statusCode == 200) {
      brandFilterItemModel = ItemModel.fromJson(response.body as Map<String, dynamic>);

      // Cache the response for 10 minutes
      await LocalClient.organize(DataSourceEnum.client, cacheKey,
          jsonEncode(response.body), apiClient.getHeader());
      if (kDebugMode) {
        appLogger.debug(
            '💾 Brand Filter cached: brandId=$brandId, categoryId=$categoryId, items=${brandFilterItemModel.items?.length ?? 0}');
      }
    }
    return brandFilterItemModel;
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

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    // Note: implement getList
    throw UnimplementedError();
  }
}
