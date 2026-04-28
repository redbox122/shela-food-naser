import 'package:dio/dio.dart' hide Response;
import 'package:get/get.dart';
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
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/store/domain/repositories/store_repository_interface.dart';
import 'package:sixam_mart/features/store/domain/services/store_service_interface.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/store/domain/models/subcategory_samples_model.dart';
import 'package:sixam_mart/features/store/domain/models/slim_menu_model.dart';

class StoreService implements StoreServiceInterface {
  final StoreRepositoryInterface storeRepositoryInterface;
  StoreService({required this.storeRepositoryInterface});

  @override
  Future<StoreModel?> getStoreList(
      int offset, String filterBy, String storeType,
      {required DataSourceEnum source,
      bool? recentlyAdded,
      bool? highestRated,
      bool? fastestDelivery,
      double? minPrice,
      double? maxPrice,
      String? sortBy,
      int? limit}) async {
    final result = await storeRepositoryInterface.getList(
        offset: offset,
        isStoreList: true,
        filterBy: filterBy,
        type: storeType,
        source: source,
        recentlyAdded: recentlyAdded,
        highestRated: highestRated,
        fastestDelivery: fastestDelivery,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        limit: limit);
    return result is StoreModel? ? result : null;
  }

  @override
  Future<List<Store>?> getPopularStoreList(String type,
      {required DataSourceEnum source}) async {
    final result = await storeRepositoryInterface.getList(
        isPopularStoreList: true, type: type, source: source);
    return result is List<Store>? ? result : null;
  }

  @override
  Future<List<Store>?> getLatestStoreList(String type,
      {required DataSourceEnum source}) async {
    final result = await storeRepositoryInterface.getList(
        isLatestStoreList: true, type: type, source: source);
    return result is List<Store>? ? result : null;
  }

  @override
  Future<List<Store>?> getTopOfferStoreList(
      {required DataSourceEnum source}) async {
    final result = await storeRepositoryInterface.getList(
        isTopOfferStoreList: true, source: source);
    return result is List<Store>? ? result : null;
  }

  @override
  Future<List<Store>?> getFeaturedStoreList(
      {required DataSourceEnum source}) async {
    final result = await storeRepositoryInterface.getList(
        isFeaturedStoreList: true, source: source);
    return result is List<Store>? ? result : null;
  }

  @override
  Future<List<Store>?> getVisitAgainStoreList(
      {required DataSourceEnum source}) async {
    final result = await storeRepositoryInterface.getList(
        isVisitAgainStoreList: true, source: source);
    return result is List<Store>? ? result : null;
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
    final result = await storeRepositoryInterface.getStoreDetails(
        storeID, fromCart, slug, languageCode, module, cacheModuleId, moduleId, cancelToken);
    return result is Store? ? result : null;
  }

  @override
  Future<ItemModel?> getStoreItemList(
      int? storeID, int offset, int? categoryID, String type, {int? moduleId, int? limit, CancelToken? cancelToken}) async {
    final result = await storeRepositoryInterface.getStoreItemList(
        storeID, offset, categoryID, type, moduleId: moduleId, limit: limit, cancelToken: cancelToken);
    return result is ItemModel? ? result : null;
  }

  @override
  Future<SlimMenuResponse?> getSlimMenu(int? storeId, {int? moduleId, CancelToken? cancelToken}) async {
    return await storeRepositoryInterface.getSlimMenu(storeId, moduleId: moduleId, cancelToken: cancelToken);
  }

  @override
  Future<ItemModel?> getStoreSearchItemList(String searchText, String? storeID,
      int offset, String type, int? categoryID) async {
    final result = await storeRepositoryInterface.getStoreSearchItemList(
        searchText, storeID, offset, type, categoryID);
    return result is ItemModel? ? result : null;
  }

  @override
  Future<RecommendedItemModel?> getStoreRecommendedItemList(
      int? storeId, {CancelToken? cancelToken}) async {
    final result = await storeRepositoryInterface.getList(
        isStoreRecommendedItemList: true, storeId: storeId, cancelToken: cancelToken);
    return result is RecommendedItemModel? ? result : null;
  }

  @override
  Future<CartSuggestItemModel?> getCartStoreSuggestedItemList(
      int? storeId,
      String languageCode,
      ModuleModel? module,
      int? cacheModuleId,
      int? moduleId) async {
    final result = await storeRepositoryInterface.getCartStoreSuggestedItemList(
        storeId, languageCode, module, cacheModuleId, moduleId);
    return result is CartSuggestItemModel? ? result : null;
  }

  @override
  Future<List<StoreBannerModel>?> getStoreBannerList(int? storeId, {CancelToken? cancelToken}) async {
    final result = await storeRepositoryInterface.getList(
        isStoreBannerList: true, storeId: storeId, cancelToken: cancelToken);
    return result is List<StoreBannerModel>? ? result : null;
  }

  @override
  Future<List<Store>?> getRecommendedStoreList(
      {required DataSourceEnum source}) async {
    final result = await storeRepositoryInterface.getList(
        isRecommendedStoreList: true, source: source);
    return result is List<Store>? ? result : null;
  }

  @override
  List<Modules> moduleList() {
    final List<Modules> moduleList = [];
    for (final ZoneData zone
        in AddressHelper.getUserAddressFromSharedPref()!.zoneData ?? []) {
      for (final Modules module in zone.modules ?? []) {
        moduleList.add(module);
      }
    }
    return moduleList;
  }

  @override
  String filterRestaurantLinkUrl(String slug, Store store) {
    final List<String> routes = Get.currentRoute.split('?');
    String replace = '';

    if (AppConstants.useReactWebsite) {
      if (slug.isNotEmpty) {
        replace =
            '${routes[0]}/$slug?module_id=${store.moduleId}&module_type=${Get.find<SplashController>().module!.moduleType}&store_zone_id=${store.zoneId}&distance=${store.distance}';
      } else {
        replace =
            '${routes[0]}/${store.id}?module_id=${store.moduleId}&module_type=${Get.find<SplashController>().module!.moduleType}&store_zone_id=${store.zoneId}&distance=${store.distance}';
      }
    } else {
      if (slug.isNotEmpty) {
        replace = '${routes[0]}?slug=$slug';
      } else {
        replace = '${routes[0]}?slug=${store.id}';
      }
    }
    return replace;
  }

  @override
  Future<Response> get_new_search_filtera(
      {required SearchFilterModel search_filterModel}) async {
    return await storeRepositoryInterface.get_new_search_filtera(
        search_filterModel: search_filterModel);
  }

  @override
  Future<List<CategoryModel>?> getSubCategoryList({String? parentID}) async {
    final result = await storeRepositoryInterface.getList(
        id: parentID, subCategoryList: true);
    return result is List<CategoryModel>? ? result : null;
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
    return await storeRepositoryInterface.getStoreSubcategoriesWithSamples(
      storeId: storeId,
      categoryId: categoryId,
      limit: limit,
      offset: offset,
      sampleSize: sampleSize,
      type: type,
      includeChildren: includeChildren,
    );
  }
}
