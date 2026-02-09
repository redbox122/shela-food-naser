import 'package:get/get_connect.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class CartRepositoryInterface<OnlineCart> extends RepositoryInterface<OnlineCart> {
  Future<void> addSharedPrefCartList(List<CartModel> cartProductList);
  Future<Response<dynamic>> mergeCart(String guestId);
  // ✅ BACKEND CONTRACT: Get store_id from last cart/list response
  int? getStoreId();
  @override
  Future<dynamic> update(Map<String, dynamic> body, int? id, {double price, int quantity, bool isUpdateQty = false});
  @override
  Future<bool> delete(int? id, {bool isRemoveAll = false});
}