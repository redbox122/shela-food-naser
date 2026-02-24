// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/features/offers/domain/reposotories/offers_repository_interface.dart';
import 'package:sixam_mart/features/offers/domain/services/offers_service_interface.dart';

import '../../../item/domain/models/item_model.dart';

class OffersService implements Offers_ServiceInterface {
  final OffersRepositoryInterface offersRepositoryinterface;
  OffersService({required this.offersRepositoryinterface});

  @override
  Future<OffersModel> getOffers() async {
    return await offersRepositoryinterface.getOffers();
  }

  @override
  Future<ItemModel?> getOffersItem({
    int? offset,
    int? limit,
    String? id,
    bool forceRefresh = false,
  }) async {
    return await offersRepositoryinterface.getOffersItem(
      offset: offset,
      id: id,
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<ItemModel?> getOffersSearchItemList(String searchText, String? offerId,
      int offset, String type, int categoryId) async {
    return await offersRepositoryinterface.getOffersSearchItemList(
        searchText, offerId, offset, type, categoryId);
  }

  @override
  Future<ItemModel?> getOffersItemWithFilters({
    String? id,
    int? offset,
    int? limit,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  }) async {
    return await offersRepositoryinterface.getOffersItemWithFilters(
      id: id,
      offset: offset,
      limit: limit,
      categoryId: categoryId,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }
}
