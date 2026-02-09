import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';
import 'package:sixam_mart/features/item/domain/models/common_condition_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/domain/repositories/item_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ItemRepository implements ItemRepositoryInterface {
  final ApiClient apiClient;
  ItemRepository({required this.apiClient});

  @override
  Future<BasicMedicineModel?> getBasicMedicine(DataSourceEnum source) async {
    BasicMedicineModel? basicMedicineModel;
    final String cacheId =
        '${AppConstants.basicMedicineUri}?offset=1&limit=50-${Get.find<SplashController>().module!.id!}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient
            .getData('${AppConstants.basicMedicineUri}?offset=1&limit=50');
        if (response.statusCode == 200) {
          basicMedicineModel = BasicMedicineModel.fromJson(
              response.body as Map<String, dynamic>);
          LocalClient.organize(DataSourceEnum.client, cacheId,
              jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          basicMedicineModel = BasicMedicineModel.fromJson(
              jsonDecode(cacheResponseData) as Map<String, dynamic>);
        }
    }
    return basicMedicineModel;
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
  Future get(String? id, {bool isConditionWiseItem = false}) async {
    if (isConditionWiseItem) {
      return await _getConditionsWiseItems(int.parse(id!));
    } else {
      return await _getItemDetails(int.parse(id!));
    }
  }

  Future<Item?> _getItemDetails(int? itemID) async {
    Item? item;

    // Ensure headers are valid before making API call
    // This ensures X-localization header is set correctly for locale-aware food variations
    apiClient.ensureHeadersAreValid();

    // Debug: Verify X-localization header is set
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      final headers = apiClient.getHeader();
      final localizationHeader = headers[AppConstants.localizationKey];
      debugPrint(
          '📍 [ItemRepository] _getItemDetails() - Language header check:');
      debugPrint('   🌐 X-localization header: $localizationHeader');
      if (localizationHeader == null || localizationHeader.isEmpty) {
        debugPrint('   ⚠️ WARNING: X-localization header is missing or empty!');
      } else {
        debugPrint('   ✅ X-localization header is set correctly');
      }
    }

    // Item details fetch here is a best-effort enrichment before navigation.
    // Keep it silent to avoid noisy "Not Found" logs when backend doesn't return details for some list items.
    final Response response = await apiClient.getData(
      '${AppConstants.itemDetailsUri}$itemID',
      handleError: false,
    );
    if (response.statusCode == 200) {
      try {
        item = Item.fromJson(response.body as Map<String, dynamic>);
        // ✅ Verify item was parsed correctly, especially foodVariations
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          debugPrint('✅ [ItemRepository] Item parsed successfully:');
          debugPrint('   - Item ID: ${item.id}');
          debugPrint(
              '   - foodVariations count: ${item.foodVariations?.length ?? 0}');
          debugPrint(
              '   - choiceOptions count: ${item.choiceOptions?.length ?? 0}');
          debugPrint('   - variations count: ${item.variations?.length ?? 0}');
        }
      } catch (e, stackTrace) {
        // ✅ CRITICAL: If Item.fromJson fails, log but don't crash
        // This can happen if preset parsing fails, but we still want the item with variations
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          debugPrint('❌ [ItemRepository] Error parsing Item.fromJson: $e');
          debugPrint('   - Stack trace: $stackTrace');
          debugPrint(
              '   - Response body keys: ${(response.body as Map).keys.toList()}');
        }
        // Try to parse again with error handling - variations should still work
        // The preset parsing error shouldn't break the entire item
        item = null;
      }
    }
    return item;
  }

  Future<List<Item>?> _getConditionsWiseItems(int id) async {
    List<Item>? conditionWiseProduct;
    final Response response = await apiClient
        .getData('${AppConstants.conditionWiseItemUri}$id?limit=15&offset=1');
    if (response.statusCode == 200) {
      conditionWiseProduct = [];
      conditionWiseProduct.addAll(
          ItemModel.fromJson(response.body as Map<String, dynamic>).items!);
    }
    return conditionWiseProduct;
  }

  @override
  Future getList({
    int? offset,
    String? type,
    String? id,
    bool isPopularItem = false,
    bool isReviewedItem = false,
    bool isFeaturedCategoryItems = false,
    bool isRecommendedItems = false,
    bool isCommonConditions = false,
    bool isDiscountedItems = false,
    DataSourceEnum? source,
    bool isCategory = false,
  }) async {
    if (isPopularItem) {
      return await _getPopularItemList(type!,
          source: source ?? DataSourceEnum.client);
    } else if (isReviewedItem) {
      return await _getReviewedItemList(type!,
          source: source ?? DataSourceEnum.client);
    } else if (isFeaturedCategoryItems) {
      return await _getFeaturedCategoriesItemList(
          source: source ?? DataSourceEnum.client);
    } else if (isRecommendedItems) {
      return await _getRecommendedItemList(type!,
          source: source ?? DataSourceEnum.client);
    } else if (isCommonConditions) {
      return await _getCommonConditions();
    } else if (isDiscountedItems) {
      return await _getDiscountedItemList(type!,
          source: source ?? DataSourceEnum.client);
    } else if (isCategory) {
      return await _getCategoryItemList(id, offset!, type!);
    }
  }

  Future<List<Item>?> _getPopularItemList(String type,
      {required DataSourceEnum source}) async {
    List<Item>? popularItemList;
    final String cacheId =
        '${AppConstants.popularItemUri}?type=$type-${Get.find<SplashController>().module!.id!}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient
            .getData('${AppConstants.popularItemUri}?type=$type');
        if (response.statusCode == 200) {
          popularItemList = [];
          popularItemList.addAll(
              ItemModel.fromJson(response.body as Map<String, dynamic>).items!);
          LocalClient.organize(DataSourceEnum.client, cacheId,
              jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          popularItemList = [];
          popularItemList.addAll(ItemModel.fromJson(
                  jsonDecode(cacheResponseData) as Map<String, dynamic>)
              .items!);
        }
    }

    return popularItemList;
  }

  Future<ItemModel?> _getReviewedItemList(String type,
      {required DataSourceEnum source}) async {
    ItemModel? itemModel;
    final String cacheId =
        '${AppConstants.reviewedItemUri}?type=$type${Get.find<SplashController>().module!.id!}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient
            .getData('${AppConstants.reviewedItemUri}?type=$type');
        if (response.statusCode == 200) {
          itemModel = ItemModel.fromJson(response.body as Map<String, dynamic>);
          LocalClient.organize(DataSourceEnum.client, cacheId,
              jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          itemModel = ItemModel.fromJson(
              jsonDecode(cacheResponseData) as Map<String, dynamic>);
        }
    }

    return itemModel;
  }

  Future<ItemModel?> _getFeaturedCategoriesItemList(
      {required DataSourceEnum source}) async {
    ItemModel? featuredCategoriesItem;
    final String cacheId =
        '${AppConstants.featuredCategoriesItemsUri}?limit=30&offset=1${Get.find<SplashController>().module!.id!}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient.getData(
            '${AppConstants.featuredCategoriesItemsUri}?limit=30&offset=1');
        if (response.statusCode == 200) {
          featuredCategoriesItem =
              ItemModel.fromJson(response.body as Map<String, dynamic>);
          LocalClient.organize(DataSourceEnum.client, cacheId,
              jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          featuredCategoriesItem = ItemModel.fromJson(
              jsonDecode(cacheResponseData) as Map<String, dynamic>);
        }
    }

    return featuredCategoriesItem;
  }

  Future<List<Item>?> _getRecommendedItemList(String type,
      {required DataSourceEnum source}) async {
    List<Item>? recommendedItemList;
    final String cacheId =
        '${AppConstants.recommendedItemsUri}$type&limit=30${Get.find<SplashController>().module!.id!}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient
            .getData('${AppConstants.recommendedItemsUri}$type&limit=30');
        if (response.statusCode == 200) {
          recommendedItemList = [];
          recommendedItemList.addAll(
              ItemModel.fromJson(response.body as Map<String, dynamic>).items!);
          LocalClient.organize(DataSourceEnum.client, cacheId,
              jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          recommendedItemList = [];
          recommendedItemList.addAll(ItemModel.fromJson(
                  jsonDecode(cacheResponseData) as Map<String, dynamic>)
              .items!);
        }
    }

    return recommendedItemList;
  }

  Future<List<CommonConditionModel>?> _getCommonConditions() async {
    List<CommonConditionModel>? commonConditions;
    final Response response =
        await apiClient.getData(AppConstants.commonConditionUri);
    if (response.statusCode == 200) {
      commonConditions = [];
      for (var condition in (response.body as List)) {
        commonConditions.add(
            CommonConditionModel.fromJson(condition as Map<String, dynamic>));
      }
    }
    return commonConditions;
  }

  Future<List<Item>?> _getDiscountedItemList(String type,
      {required DataSourceEnum source}) async {
    List<Item>? discountedItemList;
    final String cacheId =
        '${AppConstants.discountedItemsUri}?type=$type&offset=1&limit=50${Get.find<SplashController>().module!.id!}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient.getData(
            '${AppConstants.discountedItemsUri}?type=$type&offset=1&limit=50');
        if (response.statusCode == 200) {
          discountedItemList = [];
          discountedItemList.addAll(
              ItemModel.fromJson(response.body as Map<String, dynamic>).items!);
          LocalClient.organize(DataSourceEnum.client, cacheId,
              jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(
            DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          discountedItemList = [];
          discountedItemList.addAll(ItemModel.fromJson(
                  jsonDecode(cacheResponseData) as Map<String, dynamic>)
              .items!);
        }
    }

    return discountedItemList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  Future<ItemModel?> _getCategoryItemList(
      String? categoryID, int offset, String type) async {
    ItemModel? categoryItem;
    final Response response = await apiClient.getData(
        '${AppConstants.categoryItemUri}$categoryID?limit=10&offset=$offset&type=$type');
    if (response.statusCode == 200) {
      categoryItem = ItemModel.fromJson(response.body as Map<String, dynamic>);
    }
    return categoryItem;
  }

  /// Search items with filters using unified /api/v1/items/search endpoint
  /// This replaces local filtering and multiple endpoints
  @override
  Future<ItemModel?> searchItems({
    String? name,
    String? categoryId,
    String? storeId,
    String? brandId,
    String? minPrice,
    String? maxPrice,
    bool? hasDiscount,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    final Map<String, dynamic> queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (name != null && name.isNotEmpty) {
      queryParams['name'] = name;
    }
    if (categoryId != null && categoryId.isNotEmpty && categoryId != '0') {
      queryParams['category_id'] = categoryId;
    }
    if (storeId != null && storeId.isNotEmpty) {
      queryParams['store_id'] = storeId;
    }
    if (brandId != null && brandId.isNotEmpty) {
      queryParams['brand_id'] = brandId;
    }
    if (minPrice != null && minPrice.isNotEmpty && minPrice != '0') {
      queryParams['min_price'] = minPrice;
    }
    if (maxPrice != null && maxPrice.isNotEmpty && maxPrice != '0') {
      queryParams['max_price'] = maxPrice;
    }
    if (hasDiscount == true) {
      queryParams['has_discount'] = '1';
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sort_by'] = sortBy;
    }
    if (sortOrder != null && sortOrder.isNotEmpty) {
      queryParams['sort_order'] = sortOrder;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final String queryString = queryParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    final Response response =
        await apiClient.getData('${AppConstants.itemSearchUri}?$queryString');

    if (response.statusCode == 200) {
      return ItemModel.fromJson(response.body as Map<String, dynamic>);
    }
    return null;
  }
}
