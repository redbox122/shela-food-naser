import 'package:dio/dio.dart' hide Response;
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';
import 'package:sixam_mart/features/store/domain/models/subcategory_samples_model.dart';
import 'package:sixam_mart/features/store/domain/models/slim_menu_model.dart';

abstract class StoreRepositoryInterface extends RepositoryInterface {
  @override
  Future getList({
    int? offset,
    bool isStoreList = false,
    String? filterBy,
    bool isPopularStoreList = false,
    String? type,
    bool isLatestStoreList = false,
    bool isFeaturedStoreList = false,
    bool isVisitAgainStoreList = false,
    bool isStoreRecommendedItemList = false,
    int? storeId,
    bool isStoreBannerList = false,
    bool isRecommendedStoreList = false,
    bool isTopOfferStoreList = false,
    DataSourceEnum? source,
    bool subCategoryList = false,
    String? id,
    bool? recentlyAdded,
    bool? highestRated,
    bool? fastestDelivery,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    CancelToken? cancelToken,
    int? limit,
  });
  Future<dynamic> getStoreDetails(
      String storeID,
      bool fromCart,
      String slug,
      String languageCode,
      ModuleModel? module,
      int? cacheModuleId,
      int? moduleId,
      CancelToken? cancelToken);
  Future<dynamic> getStoreItemList(
      int? storeID, int offset, int? categoryID, String type, {int? moduleId, int? limit, CancelToken? cancelToken});
  Future<dynamic> getStoreSearchItemList(String searchText, String? storeID,
      int offset, String type, int? categoryID);
  Future<dynamic> getCartStoreSuggestedItemList(
      int? storeId,
      String languageCode,
      ModuleModel? module,
      int? cacheModuleId,
      int? moduleId);

  Future<Response> get_new_search_filtera(
      {required SearchFilterModel search_filterModel});

  Future<StoreSubcategorySamplesModel?> getStoreSubcategoriesWithSamples({
    required int storeId,
    required int categoryId,
    int limit,
    int offset,
    int sampleSize,
    String type,
    bool includeChildren,
  });

  /// Get slim menu for a store - returns all categories and items in a single bulk response
  /// This replaces multiple getStoreItemList calls to reduce server load
  Future<SlimMenuResponse?> getSlimMenu(int? storeId, {int? moduleId, CancelToken? cancelToken});
}
