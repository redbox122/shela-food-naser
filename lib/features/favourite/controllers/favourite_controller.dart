import 'package:flutter/material.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/favourite/domain/services/favourite_service_interface.dart';

class FavouriteController extends GetxController implements GetxService {
  final FavouriteServiceInterface favouriteServiceInterface;
  FavouriteController({required this.favouriteServiceInterface});

  List<Item?>? _wishItemList;
  List<Item?>? get wishItemList => _wishItemList;

  List<Store?>? _wishStoreList;
  List<Store?>? get wishStoreList => _wishStoreList;

  List<int?> _wishItemIdList = [];
  List<int?> get wishItemIdList => _wishItemIdList;

  List<int?> _wishStoreIdList = [];
  List<int?> get wishStoreIdList => _wishStoreIdList;

  bool _isRemoving = false;
  bool get isRemoving => _isRemoving;
  bool _hasError = false;
  bool get hasError => _hasError;

  void addToFavouriteList(Item? product, int? storeID, bool isStore, {bool getXSnackBar = false}) async {
    _isRemoving = true;
    update();
    if (isStore) {
      _wishStoreList ??= [];
      _wishStoreIdList.add(storeID);
      _wishStoreList!.add(Store());
    } else {
      _wishItemList ??= [];
      _wishItemList!.add(product);
      _wishItemIdList.add(product!.id);
    }
    final ResponseModel responseModel = await favouriteServiceInterface.addFavouriteList(isStore ? storeID : product!.id, isStore);
    if (responseModel.isSuccess) {
      showCustomSnackBar(responseModel.message, isError: false, getXSnackBar: getXSnackBar);
    } else {
      if (isStore) {
        for (final storeId in _wishStoreIdList) {
          if (storeId == storeID) {
            _wishStoreIdList.removeAt(_wishStoreIdList.indexOf(storeId));
          }
        }
      } else {
        for (final productId in _wishItemIdList) {
          if (productId == product!.id) {
            _wishItemIdList.removeAt(_wishItemIdList.indexOf(productId));
          }
        }
      }
      showCustomSnackBar(responseModel.message, getXSnackBar: getXSnackBar);
    }
    _isRemoving = false;
    update();
  }

  void removeFromFavouriteList(int? id, bool isStore, {bool getXSnackBar = false}) async {
    _isRemoving = true;
    update();

    int idIndex = -1;
    int? storeId, itemId;
    Store? store;
    Item? item;
    if (isStore) {
      idIndex = _wishStoreIdList.indexOf(id);
      if (idIndex != -1) {
        storeId = id;
        _wishStoreIdList.removeAt(idIndex);
        store = _wishStoreList![idIndex];
        _wishStoreList!.removeAt(idIndex);
      }
    } else {
      idIndex = _wishItemIdList.indexOf(id);
      if (idIndex != -1) {
        itemId = id;
        _wishItemIdList.removeAt(idIndex);
        item = _wishItemList![idIndex];
        _wishItemList!.removeAt(idIndex);
      }
    }
    final ResponseModel responseModel = await favouriteServiceInterface.removeFavouriteList(id, isStore);
    if (responseModel.isSuccess) {
      showCustomSnackBar(responseModel.message, isError: false, getXSnackBar: getXSnackBar);
    } else {
      showCustomSnackBar(responseModel.message, getXSnackBar: getXSnackBar);
      if (isStore) {
        _wishStoreIdList.add(storeId);
        _wishStoreList!.add(store);
      } else {
        _wishItemIdList.add(itemId);
        _wishItemList!.add(item);
      }
    }
    _isRemoving = false;
    update();
  }

  Future<void> getFavouriteList() async {
    _wishItemList = null;
    _wishStoreList = null;
    _hasError = false;
    try {
      final Response response = await favouriteServiceInterface.getFavouriteList();
      if (response.statusCode == 304) {
        // 304 has no body; keep UI responsive by resolving to empty lists
        _wishItemList = _wishItemList ?? <Item>[];
        _wishStoreList = _wishStoreList ?? <Store>[];
        update();
        return;
      }
      if (response.statusCode == 200) {
        _hasError = false;
        update();
        _wishItemList = [];
        _wishStoreList = [];
        _wishStoreIdList = [];
        _wishItemIdList = [];

        if ((response.body as Map<String, dynamic>)['item'] != null) {
          final List<dynamic> itemList =
              (response.body as Map<String, dynamic>)['item'] as List;
          for (final dynamic item in itemList) {
            final itemMap = item as Map<String, dynamic>;
            final moduleType = itemMap['module_type'] as String?;
            if (moduleType == null ||
                !(Get.find<SplashController>().getModuleConfig(moduleType).newVariation ?? false) ||
                itemMap['variations'] == null ||
                ((itemMap['variations'] as List?)?.isEmpty ?? true) ||
                ((itemMap['food_variations'] as List?)?.isNotEmpty ?? false)) {
              final Item i = Item.fromJson(itemMap);
              if (Get.find<SplashController>().module == null) {
                _wishItemList!.addAll(favouriteServiceInterface.wishItemList(i));
                _wishItemIdList.addAll(favouriteServiceInterface.wishItemIdList(i));
              } else {
                _wishItemList!.add(i);
                _wishItemIdList.add(i.id);
              }
            }
          }
        }

        final List<dynamic> storeList =
            (response.body as Map<String, dynamic>)['store'] as List;
        for (final dynamic store in storeList) {
          final storeMap = store as Map<String, dynamic>;
          if (Get.find<SplashController>().module == null) {
            _wishStoreList!.addAll(favouriteServiceInterface.wishStoreList(storeMap));
            _wishStoreIdList.addAll(favouriteServiceInterface.wishStoreIdList(storeMap));
          } else {
            Store? s;
            try {
              s = Store.fromJson(storeMap);
            } catch (e) {
              debugPrint('exception create in store list create : $e');
            }
            if (s != null && Get.find<SplashController>().module!.id == s.moduleId) {
              _wishStoreList!.add(s);
              _wishStoreIdList.add(s.id);
            }
          }
        }
      } else {
        _hasError = true;
        _wishItemList = <Item?>[];
        _wishStoreList = <Store?>[];
      }
    } catch (_) {
      _hasError = true;
      _wishItemList = <Item?>[];
      _wishStoreList = <Store?>[];
    }
    update();
  }

  void removeFavourite() {
    _wishItemIdList = [];
    _wishStoreIdList = [];
  }
}
