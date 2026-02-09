import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/favourite/domain/repositories/favourite_repository_interface.dart';
import 'package:sixam_mart/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:sixam_mart/helper/address_helper.dart';

class FavouriteService implements FavouriteServiceInterface {
  final FavouriteRepositoryInterface favouriteRepositoryInterface;
  FavouriteService({required this.favouriteRepositoryInterface});

  @override
  Future<Response> getFavouriteList() async {
    final result = await favouriteRepositoryInterface.getList();
    return result is Response ? result : const Response();
  }

  @override
  Future<ResponseModel> addFavouriteList(int? id, bool isStore) async {
    final result = await favouriteRepositoryInterface.add(null, isStore: isStore, id: id);
    return result is ResponseModel ? result : ResponseModel(false, 'Error');
  }

  @override
  Future<ResponseModel> removeFavouriteList(int? id, bool isStore) async {
    final result = await favouriteRepositoryInterface.delete(id, isStore: isStore);
    return result is ResponseModel ? result : ResponseModel(false, 'Error');
  }

  @override
  List<Item?> wishItemList(Item item) {
    final List<Item?> wishItemList = [];
    for (final zone in AddressHelper.getUserAddressFromSharedPref()!.zoneData!) {
      for (final module in zone.modules!) {
        if(module.id == item.moduleId){
          if(module.pivot!.zoneId == item.zoneId){
            wishItemList.add(item);
          }
        }
      }
    }
    return wishItemList;
  }

  @override
  List<int?> wishItemIdList (Item item) {
    final List<int?> wishItemIdList = [];
    for (final zone in AddressHelper.getUserAddressFromSharedPref()!.zoneData!) {
      for (final module in zone.modules!) {
        if(module.id == item.moduleId){
          if(module.pivot!.zoneId == item.zoneId){
            wishItemIdList.add(item.id);
          }
        }
      }
    }
    return wishItemIdList;
  }

  @override
  List<Store?> wishStoreList(dynamic store) {
    final List<Store?> wishStoreList = [];
    for (final zone in AddressHelper.getUserAddressFromSharedPref()!.zoneData!) {
      for (final module in zone.modules!) {
        final storeModel = Store.fromJson(store as Map<String, dynamic>);
        if(module.id == storeModel.moduleId){
          if(module.pivot!.zoneId == storeModel.zoneId){
            wishStoreList.add(storeModel);
          }
        }
      }
    }
    return wishStoreList;
  }

  @override
  List<int?> wishStoreIdList(dynamic store) {
    final List<int?> wishStoreIdList = [];
    for (final zone in AddressHelper.getUserAddressFromSharedPref()!.zoneData!) {
      for (final module in zone.modules!) {
        final storeModel = Store.fromJson(store as Map<String, dynamic>);
        if(module.id == storeModel.moduleId){
          if(module.pivot!.zoneId == storeModel.zoneId){
            wishStoreIdList.add(storeModel.id);
          }
        }
      }
    }
    return wishStoreIdList;
  }

}