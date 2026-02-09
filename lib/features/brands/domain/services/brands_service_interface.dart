import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

abstract class BrandsServiceInterface {
  Future<List<BrandModel>?> getBrandList(DataSourceEnum source);
  Future<ItemModel?> getBrandItemList({
    required int brandId,
    int? offset,
    int? limit,
  });
  Future<ItemModel?> getBrandSearchItemList({
    required String searchText,
    required int brandId,
    int? offset,
    String? type,
    int? categoryId,
  });
  Future<ItemModel?> getBrandItemWithFilters({
    required int brandId,
    int? offset,
    int? limit,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  });
}
