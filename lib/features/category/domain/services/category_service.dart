import 'package:get/get.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/category/domain/reposotories/category_repository_interface.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';

class CategoryService implements CategoryServiceInterface {
  final CategoryRepositoryInterface categoryRepositoryInterface;
  CategoryService({required this.categoryRepositoryInterface});

  @override
  Future<List<CategoryModel>?> getCategoryList(bool allCategory,
      {DataSourceEnum? source}) async {
    final result = await categoryRepositoryInterface.getList(
        allCategory: allCategory, categoryList: true, source: source);
    return result is List<CategoryModel>? ? result : null;
  }

  @override
  Future<List<CategoryModel>?> getSubCategoryList(String? parentID) async {
    final result = await categoryRepositoryInterface.getList(
        id: parentID, subCategoryList: true);
    return result is List<CategoryModel>? ? result : null;
  }

  @override
  Future<ItemModel?> getCategoryItemList(
      String? categoryID, int offset, String type,
      {bool? includeChildren, CancelToken? cancelToken}) async {
    final result = await categoryRepositoryInterface.getList(
        id: categoryID,
        offset: offset,
        type: type,
        categoryItemList: true,
        includeChildren: includeChildren,
        cancelToken: cancelToken);
    return result is ItemModel? ? result : null;
  }

  @override
  Future<void> clearCategoryItemCache(int categoryId) async {
    await categoryRepositoryInterface.clearCategoryItemCache(categoryId);
  }

  @override
  Future<StoreModel?> getCategoryStoreList(
      String? categoryID, int offset, String type) async {
    final result = await categoryRepositoryInterface.getList(
        id: categoryID, offset: offset, type: type, categoryStoreList: true);
    return result is StoreModel? ? result : null;
  }

  @override
  Future<Response> getSearchData(
      String? query, String? categoryID, bool isStore, String type) async {
    final result = await categoryRepositoryInterface.getSearchData(
        query, categoryID, isStore, type);
    return result is Response ? result : const Response();
  }

  @override
  Future<bool> saveUserInterests(List<int?> interests) async {
    final result = await categoryRepositoryInterface.saveUserInterests(interests);
    return result is bool ? result : false;
  }
}
