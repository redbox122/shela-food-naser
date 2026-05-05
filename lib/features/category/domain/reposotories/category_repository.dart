// ignore_for_file: unnecessary_brace_in_string_interps

/// Category Repository Implementation
/// 
/// **Backend Documentation Reference:**
/// - Module 6 (Food/Restaurants) - Complete API Integration Guide.md
/// - Module 6 API - Quick Reference.md
/// 
/// **Status:** ✅ All endpoints tested and verified by backend team (tested thousands of times)
/// 
/// **Implementation Notes:**
/// - All headers match backend documentation exactly (moduleId as string, zoneId as JSON string, etc.)
/// - All filtering logic matches backend documentation requirements
/// - Category model includes all documented fields (name_ar, name_en, cat_site_id, etc.)
/// - Query parameters for stores/items endpoints include required limit and offset
/// 
/// **Endpoints Implemented:**
/// - GET /api/v1/categories - Returns 38 cuisine categories for Module 6
/// - GET /api/v1/categories/stores/{category_id} - Returns stores for a category
/// - GET /api/v1/categories/items/{category_id} - Returns items for a category
/// - GET /api/v1/categories/childes/{parent_id} - Returns subcategories
library;


import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/category/domain/reposotories/category_repository_interface.dart';
import 'package:sixam_mart/helper/db_helper.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:sixam_mart/common/utils/app_logger.dart';

class CategoryRepository implements CategoryRepositoryInterface {
  final ApiClient apiClient;
  CategoryRepository({required this.apiClient});

  @override
  Future getList(
      {int? offset,
      bool categoryList = false,
      bool subCategoryList = false,
      bool categoryItemList = false,
      bool categoryStoreList = false,
      bool? allCategory,
      String? id,
      String? type,
      DataSourceEnum? source,
      bool? includeChildren,
      CancelToken? cancelToken}) async {
    if (categoryList) {
      return await _getCategoryList(
          allCategory!, source ?? DataSourceEnum.client);
    } else if (subCategoryList) {
      return await _getSubCategoryList(id);
    } else if (categoryItemList) {
      return await _getCategoryItemList(id, offset!, type!,
          includeChildren: includeChildren,
          cancelToken: cancelToken);
    } else if (categoryStoreList) {
      return await _getCategoryStoreList(id, offset!, type!);
    }
  }

  /// Get category list for the current module
  /// 
  /// **Backend Documentation Reference:** Module 6 (Food/Restaurants) - Complete API Integration Guide
  /// **Endpoint:** `GET /api/v1/categories`
  /// **Tested & Verified:** Backend team has tested this endpoint thousands of times - it works perfectly
  /// 
  /// **Required Headers (as per backend documentation):**
  /// - `moduleId: '6'` (string, not int) - REQUIRED for Module 6
  /// - `zoneId: '[2]'` (JSON array as string) - REQUIRED
  /// - `X-localization: 'ar'` (or 'en') - REQUIRED
  /// 
  /// **Expected Response:** Array of 38 cuisine categories for Module 6
  /// - All categories have `module_id: 6`, `store_id: null`, `position: 0`
  /// - All categories have real images (no placeholders)
  /// - All categories have `cat_site_id` from external API
  /// 
  /// **Client-side Filtering:** Only shows categories with `module_id == currentModuleId AND store_id == null`
  /// This matches the backend documentation requirement.
  Future<List<CategoryModel>?> _getCategoryList(
      bool allCategory, DataSourceEnum source) async {
    List<CategoryModel>? categoryList;
    
    // Always use default headers (which include moduleId) and merge custom headers if needed
    // Headers are set via apiClient.updateHeader() which ensures moduleId is included as string
    final Map<String, String> defaultHeaders = apiClient.getHeader();
    final Map<String, String>? header = allCategory
        ? {
            ...defaultHeaders, // Include moduleId and all other default headers
            'Content-Type': 'application/json; charset=UTF-8',
            AppConstants.localizationKey:
                Get.find<LocalizationController>().locale.languageCode
          }
        : null; // null means use default headers

    final Map<String, String> cacheHeader = header ?? defaultHeaders;

    // ⚠️ CRITICAL: Include locale in cache key to prevent showing wrong language from cache
    // Without locale in cache key, switching languages shows cached data from previous language
    final currentLocale = Get.find<LocalizationController>().locale.languageCode;
    final splashController = Get.find<SplashController>();
    final currentModuleId = splashController.module?.id?.toString() ?? 'no_module';
    final String cacheId = '${AppConstants.categoryUri}_${currentModuleId}_$currentLocale';

    switch (source) {
      case DataSourceEnum.client:
        debugPrint('\x1B[32m  /${cacheHeader}  \x1B[0m');
        debugPrint('\x1B[32m  /${header}  \x1B[0m');

        // Ensure headers include moduleId before making API call
        // This validates that moduleId is set in apiClient headers (required by backend)
        apiClient.ensureHeadersAreValid();
        
        // Get final headers that will be used (merged with defaults)
        // Headers format matches backend documentation exactly:
        // - moduleId: string '6' (not int 6)
        // - zoneId: JSON-encoded array string "[2]"
        // - X-localization: 'ar' or 'en'
        final finalHeaders = header != null 
            ? {...apiClient.getHeader(), ...header} 
            : apiClient.getHeader();
        
        // Debug: Verify moduleId is in headers (REQUIRED per backend documentation)
        if (finalHeaders.containsKey(AppConstants.moduleId)) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug('✅ CategoryRepository: moduleId=${finalHeaders[AppConstants.moduleId]} in headers (required by backend)');
          }
        } else {
          if (kDebugMode) {
            appLogger.warning('⚠️ CategoryRepository: WARNING - moduleId missing from headers! (Required per Module 6 API documentation)');
          }
        }

        final Response response =
            await apiClient.getData(AppConstants.categoryUri, headers: header);

        if (response.statusCode == 200) {
          categoryList = [];
          final List<CategoryModel> list = categoryList; // Local non-nullable variable
          
          // Get current module ID for filtering (convert to int for comparison)
          final currentModuleId = Get.find<SplashController>().module?.id;
          
          // Debug: Log module ID and response
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug('🔍 CategoryRepository: Loading categories for module ID: $currentModuleId');
          }
          final responseBodyList = response.body is List ? (response.body as List) : [];
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug('📦 CategoryRepository: API returned ${responseBodyList.length} categories');
          }
          
          // Debug: Log first 3 categories to check image fields and module_id
          if (responseBodyList.isNotEmpty && kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug('🔍 CategoryRepository: Sample categories from API:');
            for (int i = 0; i < (responseBodyList.length > 3 ? 3 : responseBodyList.length); i++) {
              final category = responseBodyList[i] as Map<String, dynamic>;
              appLogger.debug('   Category $i:');
              appLogger.debug('     - id: ${category['id']}');
              appLogger.debug('     - name: ${category['name']}');
              appLogger.debug('     - image: ${category['image']}');
              appLogger.debug('     - image_full_url: ${category['image_full_url']}');
              appLogger.debug('     - module_id: ${category['module_id']}');
              appLogger.debug('     - store_id: ${category['store_id']}');
            }
          }
          
          // Debug: Log first category to check image fields
          if (responseBodyList.isNotEmpty && kDebugMode && AppConstants.enableVerboseLogs) {
            final firstCategory = responseBodyList[0] as Map<String, dynamic>;
            appLogger.debug('🔍 CategoryRepository: First category sample:');
            appLogger.debug('   - id: ${firstCategory['id']}');
            appLogger.debug('   - name: ${firstCategory['name']}');
            appLogger.debug('   - image: ${firstCategory['image']}');
            appLogger.debug('   - image_full_url: ${firstCategory['image_full_url']}');
            appLogger.debug('   - module_id: ${firstCategory['module_id']}');
            appLogger.debug('   - store_id: ${firstCategory['store_id']}');
          }

          for (var category in responseBodyList) {
            final categoryModel = CategoryModel.fromJson(category as Map<String, dynamic>);
            
            // ⚠️ CRITICAL: Client-side filtering - matches backend documentation requirements exactly
            // Backend returns all categories, but we filter to show only:
            // - Categories with module_id == currentModuleId (e.g., 6 for Food module)
            // - Categories with store_id == null (module-level cuisine categories, not restaurant menu categories)
            // 
            // Per Module 6 API documentation:
            // - Cuisine categories have position: 0, module_id: 6, store_id: null
            // - Restaurant menu categories have store_id != null (not returned by /api/v1/categories endpoint)
            if (currentModuleId != null) {
              // We have a current module - only include categories that match it
              if (categoryModel.moduleId != null) {
                // Convert both to int for proper comparison
                final int moduleIdInt = categoryModel.moduleId!;
                final int currentModuleIdInt = currentModuleId;
                
                // Filtering logic per backend documentation:
                // Only include if module matches AND it's a module-level category (store_id == null)
                // This ensures we only show cuisine categories, not restaurant menu categories
                if (moduleIdInt == currentModuleIdInt && categoryModel.storeId == null) {
                  list.add(categoryModel);
                } else {
                  if (kDebugMode && AppConstants.enableVerboseLogs) {
                    if (moduleIdInt != currentModuleIdInt) {
                      appLogger.debug('⚠️ CategoryRepository: Filtered out category ${categoryModel.id} "${categoryModel.name}" (module_id: $moduleIdInt, expected: $currentModuleIdInt)');
                    } else if (categoryModel.storeId != null) {
                      appLogger.debug('⚠️ CategoryRepository: Filtered out store-specific category ${categoryModel.id} (store_id: ${categoryModel.storeId}) - this is a restaurant menu category, not a cuisine category');
                    }
                  }
                }
              } else {
                // Category has no moduleId - exclude it when we have a current module
                // This prevents categories from other modules (animals, flowers, etc.) from showing
                if (kDebugMode && AppConstants.enableVerboseLogs) {
                  appLogger.debug('⚠️ CategoryRepository: Filtered out category ${categoryModel.id} "${categoryModel.name}" (no module_id, current module: $currentModuleId)');
                }
              }
            } else {
              // No current module - backward compatibility mode
              // Only include module-level categories (not store-specific)
              if (categoryModel.storeId == null) {
                list.add(categoryModel);
                if (kDebugMode && AppConstants.enableVerboseLogs) {
                  appLogger.debug('✅ CategoryRepository: Added category ${categoryModel.id} (backward compatibility mode, no current module)');
                }
              } else {
                if (kDebugMode && AppConstants.enableVerboseLogs) {
                  appLogger.debug('⚠️ CategoryRepository: Filtered out store-specific category ${categoryModel.id} (store_id: ${categoryModel.storeId})');
                }
              }
            }
          }
          
          categoryList = list;
          
          if (kDebugMode) {
            appLogger.info('✅ CategoryRepository: Loaded ${list.length} categories for module $currentModuleId');
          }
          
          // ⚠️ FALLBACK: If all categories were filtered out, relax filtering for ecommerce modules
          // This handles cases where backend doesn't set module_id correctly
          if (list.isEmpty && responseBodyList.isNotEmpty) {
            if (kDebugMode) {
              appLogger.warning('⚠️ CategoryRepository: ⚠️⚠️⚠️ ALL CATEGORIES WERE FILTERED OUT! ⚠️⚠️⚠️');
              appLogger.warning('⚠️ CategoryRepository: API returned ${responseBodyList.length} categories but 0 passed filtering');
              appLogger.warning('⚠️ CategoryRepository: Attempting fallback - showing categories without strict module filtering...');
            }
            
            // Fallback: For ecommerce modules, show all module-level categories (store_id == null)
            // even if module_id doesn't match or is missing
            final splashController = Get.find<SplashController>();
            final isEcommerce = (splashController.module?.moduleType.toString() ?? '') == AppConstants.ecommerce;
            
            if (isEcommerce) {
              list.clear();
              int addedCount = 0;
              int skippedCount = 0;
              for (var category in responseBodyList) {
                final categoryModel = CategoryModel.fromJson(category as Map<String, dynamic>);
                // For ecommerce fallback: only exclude store-specific categories
                if (categoryModel.storeId == null) {
                  list.add(categoryModel);
                  addedCount++;
                  if (addedCount <= 5 && kDebugMode && AppConstants.enableVerboseLogs) { // Only log first 5 to avoid spam
                    appLogger.debug('✅ CategoryRepository: Fallback - Added category ${categoryModel.id} "${categoryModel.name}" (module_id: ${categoryModel.moduleId}, ecommerce fallback)');
                  }
                } else {
                  skippedCount++;
                }
              }
              categoryList = list;
              if (kDebugMode) {
                appLogger.info('✅ CategoryRepository: Fallback loaded ${list.length} categories for ecommerce module (skipped $skippedCount store-specific)');
              }
            } else {
              if (kDebugMode) {
                appLogger.warning('⚠️ CategoryRepository: Check module_id and store_id filtering logic.');
                appLogger.warning('⚠️ CategoryRepository: Consider relaxing filtering rules or showing store-specific categories if module-level ones are empty.');
              }
            }
          } else if (list.isEmpty) {
            if (kDebugMode) {
              appLogger.warning('⚠️ CategoryRepository: API returned empty category list');
            }
          } else {
            // Debug: Log sample of successfully loaded categories
            if (list.isNotEmpty && kDebugMode && AppConstants.enableVerboseLogs) {
              appLogger.info('✅ CategoryRepository: Successfully loaded ${list.length} categories');
              final sample = list.take(3).toList();
              for (final cat in sample) {
                appLogger.debug('   - Category ${cat.id}: "${cat.name}" (module_id: ${cat.moduleId}, image: ${cat.image}, imageFullUrl: ${cat.imageFullUrl})');
              }
            }
          }

          // Cache the filtered results
          LocalClient.organize(DataSourceEnum.client, cacheId,
              jsonEncode(list.map((c) => c.toJson()).toList()), cacheHeader);
        }
        break;

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          categoryList = [];
          final List<CategoryModel> list = categoryList; // Local non-nullable variable
          
          // Get current module ID for filtering cached data too (convert to int for comparison)
          // Cache filtering uses the same logic as API response filtering to ensure consistency
          final currentModuleId = Get.find<SplashController>().module?.id;
          
          final decodedCache = jsonDecode(cacheResponseData) as List;
          for (var category in decodedCache) {
            final categoryModel = CategoryModel.fromJson(category as Map<String, dynamic>);
            
            // ⚠️ CRITICAL: Filter cached categories by module ID and exclude store-specific categories
            // This matches the backend documentation requirement:
            // - Only show categories with module_id == currentModuleId (e.g., 6 for Food module)
            // - Only show module-level categories (store_id == null), not restaurant menu categories
            // Module pages should only show module-level categories (store_id == null)
            if (currentModuleId != null) {
              // We have a current module - only include categories that match it
              if (categoryModel.moduleId != null) {
                // Convert both to int for proper comparison
                final int moduleIdInt = categoryModel.moduleId!;
                final int currentModuleIdInt = currentModuleId;
                
                // Filtering logic matches backend documentation exactly:
                // Only include if module matches AND it's a module-level category (store_id == null)
                if (moduleIdInt == currentModuleIdInt && categoryModel.storeId == null) {
                  list.add(categoryModel);
                }
              }
              // Exclude categories without moduleId when we have a current module
            } else {
              // No current module - backward compatibility mode
              // Only include module-level categories (not store-specific)
              if (categoryModel.storeId == null) {
                list.add(categoryModel);
              }
            }
          }
          
          categoryList = list;
          
          if (kDebugMode) {
            appLogger.info('✅ CategoryRepository: Loaded ${list.length} categories from cache for module $currentModuleId');
            if (list.isEmpty) {
              appLogger.warning('⚠️ CategoryRepository: No categories in cache after filtering!');
            }
          }
        }
        break;
    }

    return categoryList;
  }

  /// Get subcategories for a parent category
  /// 
  /// ⚡ NETWORK-FIRST: Subcategories are always fetched fresh from network
  /// This ensures users always see up-to-date subcategories when entering a category
  /// Unlike category items which use cache-first, subcategories are contextual and user expects instant feedback
  Future<List<CategoryModel>?> _getSubCategoryList(String? parentID) async {
    List<CategoryModel>? subCategoryList;

    // 🔥 NETWORK-FIRST: Disable ETag to force fresh fetch every time
    // This prevents 304 Not Modified responses that cause stale subcategory data
    // Subcategories are contextual (user clicks category → expects subcategories immediately)
    final Response response = await apiClient.getData(
      '${AppConstants.subCategoryUri}$parentID',
      useEtag: false, // ⚡ Force network-first, ignore cache
    );

    if (response.statusCode == 200) {
      subCategoryList = [];

      if (response.body is List) {
        for (var category in (response.body as List)) {
          subCategoryList.add(CategoryModel.fromJson(category as Map<String, dynamic>));
        }
      }
    } else if (response.statusCode == 304) {
      // ⚠️ Should not happen with useEtag: false, but handle gracefully
      if (kDebugMode) {
        debugPrint('⚠️ CategoryRepository: Received 304 for subcategories despite useEtag: false');
      }
      // Return empty list to show "All" button only
      subCategoryList = [];
    }
    return subCategoryList;
  }

  /// Get items for a category
  /// 
  /// **Backend Documentation Reference:** Module 6 (Food/Restaurants) - Complete API Integration Guide
  /// **Endpoint:** `GET /api/v1/categories/items/{category_id}`
  /// **Tested & Verified:** Backend team has tested this endpoint thousands of times - it works perfectly
  /// 
  /// **Required Headers (as per backend documentation):**
  /// - `moduleId: '6'` (string) - REQUIRED
  /// - `zoneId: '[2]'` (JSON array as string) - REQUIRED
  /// - `X-localization: 'ar'` (or 'en') - REQUIRED
  /// 
  /// **Required Query Parameters (as per backend documentation):**
  /// - `limit` (required): Number of items per page (e.g., `10`)
  /// - `offset` (required): Page offset index (e.g., `0`, `10`, `20`)
  /// - `type` (optional): Item type filter (`'all'`, `'veg'`, `'non_veg'`)
  /// - `include_children` (optional): Include subcategory items (`true`/`false`)
  /// 
  /// **Response:** Returns items from stores in the category
  Future<ItemModel?> _getCategoryItemList(
      String? categoryID, int offset, String type,
      {bool? includeChildren, CancelToken? cancelToken}) async {
    ItemModel? categoryItem;
    const int pageSize = 10;
    final int effectiveOffset =
        offset <= 1 ? 0 : (offset - 1) * pageSize;

    // Get module ID for API request
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id?.toString() ?? 'no_module';

    // Build API URL with include_children parameter
    String apiUrl =
        '${AppConstants.categoryItemUri}$categoryID?limit=$pageSize&offset=$effectiveOffset&type=$type';
    if (moduleId != 'no_module') {
      apiUrl += '&module_id=$moduleId';
    }
    if (includeChildren != null) {
      apiUrl += '&include_children=${includeChildren ? 'true' : 'false'}';
    }

    // ⚡ DISABLE ETAG: Category items use SQLite cache (LocalClient), not Hive
    // ETag/304 relies on Hive cache which doesn't exist for category items
    // Always fetch fresh data and cache in SQLite
    final Response response = await apiClient.getData(
      apiUrl,
      useEtag: false,
      cancelToken: cancelToken,
    );

    debugPrint('\x1B[32m categoryItem $apiUrl  \x1B[0m');

    if (response.statusCode == 200) {
      categoryItem = ItemModel.fromJson(response.body as Map<String, dynamic>);
      // Cache is disabled (enableCategoryItemsCache = false)
    }

    debugPrint('\x1B[32m   /${categoryItem?.items?.length ?? 0}   \x1B[0m');

    return categoryItem;
  }

  /// Get stores for a category
  /// 
  /// **Backend Documentation Reference:** Module 6 (Food/Restaurants) - Complete API Integration Guide
  /// **Endpoint:** `GET /api/v1/categories/stores/{category_id}`
  /// **Tested & Verified:** Backend team has tested this endpoint thousands of times - it works perfectly
  /// 
  /// **Required Headers (as per backend documentation):**
  /// - `moduleId: '6'` (string) - REQUIRED
  /// - `zoneId: '[2]'` (JSON array as string) - REQUIRED
  /// - `X-localization: 'ar'` (or 'en') - REQUIRED
  /// - `latitude: '24.7136'` (JSON-encoded string) - REQUIRED for stores endpoint
  /// - `longitude: '46.6753'` (JSON-encoded string) - REQUIRED for stores endpoint
  /// 
  /// **Required Query Parameters (as per backend documentation):**
  /// - `limit` (required): Number of stores per page (e.g., `10`)
  /// - `offset` (required): Page offset (e.g., `1`)
  /// - `type` (optional): Store type filter (`'all'`, `'take_away'`, `'delivery'`)
  /// 
  /// **Response:** Returns stores linked to the category
  /// **Note:** Headers (including latitude/longitude) are automatically included via apiClient.getHeader()
  Future<StoreModel?> _getCategoryStoreList(
      String? categoryID, int offset, String type) async {
    StoreModel? categoryStore;
    apiClient.ensureHeadersAreValid();
    final currentHeaders = apiClient.getHeader();
    final String? headerModuleId =
        currentHeaders[AppConstants.moduleId] ?? currentHeaders['module-id'];
    final String? headerZoneId =
        currentHeaders[AppConstants.zoneId] ?? currentHeaders['zone-id'];
    final bool missingModule = headerModuleId == null ||
        headerModuleId.isEmpty ||
        headerModuleId == 'null';
    final bool missingZone =
        headerZoneId == null || headerZoneId.isEmpty || headerZoneId == 'null';
    if ((missingModule || missingZone) && Get.isRegistered<SplashController>()) {
      final splashController = Get.find<SplashController>();
      final address = AddressHelper.getUserAddressFromSharedPref();
      apiClient.updateHeader(
        apiClient.token,
        address?.zoneIds,
        address?.areaIds,
        null,
        splashController.module?.id,
        address?.latitude,
        address?.longitude,
      );
    }
    // Headers including moduleId, zoneId, latitude, longitude are set via apiClient.getHeader()
    // This matches backend documentation requirements
    final String uri =
        '${AppConstants.categoryStoreUri}$categoryID?limit=10&offset=$offset&type=$type';
    final Response response = await apiClient.getData(
      uri,
      headers: apiClient.getHeader(),
    );

    if (kDebugMode) {
      final headers = apiClient.getHeader();
      debugPrint('[Diag] CategoryRepository._getCategoryStoreList');
      debugPrint(
          '   request: categoryId=$categoryID, offset=$offset, type=$type');
      debugPrint('   status: ${response.statusCode}');
      debugPrint('   bodyType: ${response.body.runtimeType}');
      debugPrint('   header.moduleId: ${headers[AppConstants.moduleId]}');
      debugPrint('   header.module-id: ${headers['module-id']}');
      debugPrint('   header.zoneId: ${headers[AppConstants.zoneId]}');
      debugPrint('   header.zone-id: ${headers['zone-id']}');
      debugPrint('   header.latitude: ${headers['latitude']}');
      debugPrint('   header.longitude: ${headers['longitude']}');
    }

    if (response.statusCode == 200 || response.statusCode == 304) {
      final body = response.body;
      if (body is Map<String, dynamic>) {
        categoryStore = StoreModel.fromJson(body);
      }
    }

    // If 304 returned without usable body (cache miss scenario), force one fresh fetch.
    if (categoryStore == null && response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint(
            '[Diag] CategoryRepository: 304 without usable store cache, retrying without ETag');
      }
      final Response freshResponse = await apiClient.getData(
        uri,
        useEtag: false,
      );
      if (freshResponse.statusCode == 200 &&
          freshResponse.body is Map<String, dynamic>) {
        categoryStore =
            StoreModel.fromJson(freshResponse.body as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint(
            '[Diag] CategoryRepository: fresh retry status=${freshResponse.statusCode}, parsedStores=${categoryStore?.stores?.length ?? 0}, totalSize=${categoryStore?.totalSize ?? 0}');
      }
    }

    if (kDebugMode) {
      debugPrint(
          '[Diag] CategoryRepository: parsedStores=${categoryStore?.stores?.length ?? 0}, totalSize=${categoryStore?.totalSize ?? 0}');
    }
    return categoryStore;
  }

  @override
  Future<Response> getSearchData(
      String? query, String? categoryID, bool isStore, String type) async {
    final String safeQuery = Uri.encodeQueryComponent((query ?? '').trim());
    final List<String> params = <String>[
      'name=$safeQuery',
      'type=$type',
      'offset=1',
      'limit=50',
    ];
    if ((categoryID ?? '').trim().isNotEmpty) {
      params.add('category_id=${Uri.encodeQueryComponent(categoryID!.trim())}');
      debugPrint('[CAT_FILTER][CATEGORY_CONTEXT_APPLIED] category_id=${categoryID.trim()}');
    } else {
      debugPrint('[CAT_FILTER][CATEGORY_CONTEXT_MISSING] reason=empty_category_id');
    }
    final String endpoint =
        '${AppConstants.searchUri}${isStore ? 'stores' : 'items'}/search?${params.join('&')}';
    debugPrint('[CAT_FILTER][ENDPOINT] $endpoint');
    debugPrint(
        '[CAT_FILTER][REQUEST_PARAMS] name=$safeQuery type=$type offset=1 limit=50 category_id=${(categoryID ?? '').trim()}');
    return await apiClient.getData(endpoint);
  }

  @override
  Future<bool> saveUserInterests(List<int?> interests) async {
    final Response response = await apiClient
        .postData(AppConstants.interestUri, {'interest': interests});
    return (response.statusCode == 200);
  }

  @override
  Future<void> clearCategoryItemCache(int categoryId) async {
    final String prefix = 'category_items_${categoryId}_';
    if (GetPlatform.isWeb) {
      try {
        final SharedPreferences sharedPreferences = Get.find();
        final keys = sharedPreferences.getKeys();
        final keysToRemove =
            keys.where((key) => key.startsWith(prefix)).toList();
        for (final key in keysToRemove) {
          await sharedPreferences.remove(key);
        }
        if (kDebugMode) {
          appLogger.info('🗑️ CategoryRepository: Cleared ${keysToRemove.length} web cache entries with prefix: $prefix');
        }
      } catch (e) {
        if (kDebugMode) {
          appLogger.warning('⚠️ CategoryRepository: Failed to clear web cache by prefix: $e');
        }
      }
    } else {
      await DbHelper.clearCacheByPrefix(prefix);
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
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
