import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class ItemRepositoryInterface implements RepositoryInterface {
  // Future<dynamic> getPopularItemList(String type);
  @override
  Future getList(
      {int? offset,
      String? type,
      String? id,
      bool isPopularItem = false,
      bool isReviewedItem = false,
      bool isFeaturedCategoryItems = false,
      bool isRecommendedItems = false,
      bool isCommonConditions = false,
      bool isDiscountedItems = false,
      bool isCategory = false,
      DataSourceEnum? source});
  // Future<dynamic> getReviewedItemList(String type);
  // Future<dynamic> getFeaturedCategoriesItemList();
  // Future<dynamic> getRecommendedItemList(String type);
  // Future<dynamic> getDiscountedItemList();
  // Future<dynamic> getItemDetails(int? itemID);
  Future<BasicMedicineModel?> getBasicMedicine(DataSourceEnum source);
  @override
  Future get(String? id, {bool isConditionWiseItem = false});
  // Future<dynamic> getCommonConditions();
  // Future<dynamic> getConditionsWiseItem(int id);
  
  /// Search items with filters using unified /api/v1/items/search endpoint
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
  });
}
