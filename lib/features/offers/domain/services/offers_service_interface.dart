// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';

import '../../../item/domain/models/item_model.dart';

abstract class Offers_ServiceInterface {
  Future<OffersModel> getOffers();
  Future<ItemModel?> getOffersItem({
    int? offset,
    int? limit,
    String? id,
    bool forceRefresh,
  });
  Future<ItemModel?> getOffersSearchItemList(String searchText, String? offerId,
      int offset, String type, int categoryId);
  Future<ItemModel?> getOffersItemWithFilters({
    String? id,
    int? offset,
    int? limit,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  });
}
