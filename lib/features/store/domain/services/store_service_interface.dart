import 'package:dio/dio.dart' hide Response;
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/store/domain/models/cart_suggested_item_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/recommended_product_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/store/domain/models/subcategory_samples_model.dart';
import 'package:sixam_mart/features/store/domain/models/slim_menu_model.dart';

abstract class StoreServiceInterface {
  Future<StoreModel?> getStoreList(
      int offset, String filterBy, String storeType,
      {required DataSourceEnum source,
      bool? recentlyAdded,
      bool? highestRated,
      bool? fastestDelivery,
      double? minPrice,
      double? maxPrice,
      String? sortBy,
      int? limit});
  Future<List<Store>?> getPopularStoreList(String type,
      {required DataSourceEnum source});
  Future<List<Store>?> getLatestStoreList(String type,
      {required DataSourceEnum source});
  Future<List<Store>?> getTopOfferStoreList({required DataSourceEnum source});
  Future<List<Store>?> getFeaturedStoreList({required DataSourceEnum source});
  Future<List<Store>?> getVisitAgainStoreList({required DataSourceEnum source});
  Future<Store?> getStoreDetails(
      String storeID,
      bool fromCart,
      String slug,
      String languageCode,
      ModuleModel? module,
      int? cacheModuleId,
      int? moduleId,
      CancelToken? cancelToken);
  Future<ItemModel?> getStoreItemList(
      int? storeID, int offset, int? categoryID, String type, {int? moduleId, int? limit, CancelToken? cancelToken});
  Future<SlimMenuResponse?> getSlimMenu(int? storeId, {int? moduleId, CancelToken? cancelToken});
  Future<ItemModel?> getStoreSearchItemList(String searchText, String? storeID,
      int offset, String type, int? categoryID);
  Future<RecommendedItemModel?> getStoreRecommendedItemList(int? storeId, {CancelToken? cancelToken});
  Future<CartSuggestItemModel?> getCartStoreSuggestedItemList(
      int? storeId,
      String languageCode,
      ModuleModel? module,
      int? cacheModuleId,
      int? moduleId);
  Future<List<StoreBannerModel>?> getStoreBannerList(int? storeId, {CancelToken? cancelToken});
  Future<List<Store>?> getRecommendedStoreList(
      {required DataSourceEnum source});
  List<Modules> moduleList();
  String filterRestaurantLinkUrl(String slug, Store store);

  Future<Response> get_new_search_filtera(
      {required SearchFilterModel search_filterModel});

  Future<List<CategoryModel>?> getSubCategoryList({String? parentID});
  Future<StoreSubcategorySamplesModel?> getStoreSubcategoriesWithSamples({
    required int storeId,
    required int categoryId,
    int limit,
    int offset,
    int sampleSize,
    String type,
    bool includeChildren,
  });
}
