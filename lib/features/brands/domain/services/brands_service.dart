import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/brands/domain/repositories/brands_repository_interface.dart';
import 'package:sixam_mart/features/brands/domain/services/brands_service_interface.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class BrandsService implements BrandsServiceInterface {
  final BrandsRepositoryInterface brandsRepositoryInterface;
  BrandsService({required this.brandsRepositoryInterface});

  @override
  Future<List<BrandModel>?> getBrandList(DataSourceEnum source) async {
    return await brandsRepositoryInterface.getBrandList(source: source);
  }

  @override
  Future<ItemModel?> getBrandItemList({
    required int brandId,
    int? offset,
    int? limit,
  }) async {
    return await brandsRepositoryInterface.getBrandItemList(
      brandId: brandId,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<ItemModel?> getBrandSearchItemList({
    required String searchText,
    required int brandId,
    int? offset,
    String? type,
    int? categoryId,
  }) async {
    return await brandsRepositoryInterface.getBrandSearchItemList(
      searchText: searchText,
      brandId: brandId,
      offset: offset,
      type: type,
      categoryId: categoryId,
    );
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
    return await brandsRepositoryInterface.getBrandItemWithFilters(
      brandId: brandId,
      offset: offset,
      limit: limit,
      categoryId: categoryId,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }
}
