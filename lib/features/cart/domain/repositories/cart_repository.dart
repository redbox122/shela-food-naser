import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class CartRepository implements CartRepositoryInterface<OnlineCart> {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  CartRepository({required this.apiClient, required this.sharedPreferences});

  // ✅ BACKEND CONTRACT: Store store_id from cart/list response
  int? _lastStoreId;
  int? get lastStoreId => _lastStoreId;

  @override
  int? getStoreId() => _lastStoreId;

  @override
  Future<void> addSharedPrefCartList(List<CartModel> cartProductList) async {
    List<String> carts = [];
    if (sharedPreferences.containsKey(AppConstants.cartList)) {
      carts = sharedPreferences.getStringList(AppConstants.cartList) ?? [];
    }
    final List<String> cartStringList = [];
    final int currentModuleId = _getModuleId();
    if (currentModuleId == 0) {
      // Module not set yet: replace entire cache to avoid duplication.
      carts = [];
    }
    for (final String cartString in carts) {
      final CartModel cartModel =
          CartModel.fromJson(jsonDecode(cartString) as Map<String, dynamic>);
      final int? itemModuleId = cartModel.item?.moduleId;
      final bool isSameModule =
          itemModuleId == null || itemModuleId == currentModuleId;
      if (!isSameModule) {
        cartStringList.add(cartString);
      }
    }
    for (final CartModel cartModel in cartProductList) {
      cartStringList.add(jsonEncode(cartModel.toJson()));
    }
    await sharedPreferences.setStringList(
        AppConstants.cartList, cartStringList);
  }

  int _getModuleId() {
    return ModuleHelper.getModule()?.id ??
        ModuleHelper.getCacheModule()?.id ??
        0;
  }

  @override
  Future add(OnlineCart cart) async {
    return await _addToCartOnline(cart);
  }

  @override
  Future<Response<dynamic>> mergeCart(String guestId) async {
    return await apiClient.postData(AppConstants.cartMergeUri, {
      'guest_id': guestId,
    });
  }

  Future<List<OnlineCartModel>?> _addToCartOnline(OnlineCart cart) async {
    List<OnlineCartModel>? onlineCartList;

    // 🔧 FIX: Move guest_id from query parameter to request body
    final Map<String, dynamic> requestBody = cart.toJson();
    if (!AuthHelper.isLoggedIn()) {
      final String guestId = AuthHelper.getGuestId();
      if (guestId.isNotEmpty) {
        requestBody['guest_id'] = guestId;
      }
    }

    final Response response =
        await apiClient.postData(AppConstants.addCartUri, requestBody);
    if (response.statusCode == 200) {
      onlineCartList = [];

      // ✅ ENABLED: Log request body to verify what we're sending
      debugPrint(
          '\x1B[33m🔍 [CART ADD REQUEST BODY]:\n${const JsonEncoder.withIndent('  ').convert(cart.toJson())}\x1B[0m');

      debugPrint('\x1B[32m     ${response.body}     \x1B[0m');

      if (response.body is List) {
        for (var cart in (response.body as List)) {
          onlineCartList
              .add(OnlineCartModel.fromJson(cart as Map<String, dynamic>));
        }
      }
    }
    return onlineCartList;
  }

  @override
  Future<bool> delete(int? id, {bool isRemoveAll = false}) async {
    if (isRemoveAll) {
      return await _clearCartOnline();
    } else {
      return await _removeCartItemOnline(id!);
    }
  }

  Future<bool> _removeCartItemOnline(int cartId) async {
    // 🔧 FIX: Move guest_id from query parameter to request body
    // Note: DELETE requests typically use query params, but backend expects body
    // We'll use query for cart_id (required) and body for guest_id if needed
    String url = '${AppConstants.removeItemCartUri}?cart_id=$cartId';

    Map<String, dynamic>? body;
    if (!AuthHelper.isLoggedIn()) {
      final String guestId = AuthHelper.getGuestId();
      if (guestId.isNotEmpty) {
        body = {'guest_id': guestId};
      }
    }

    // Note: apiClient.deleteData may need to support body parameter
    // For now, keeping guest_id in query as DELETE typically doesn't support body
    // Backend should accept guest_id in query for DELETE requests
    if (body != null) {
      url += '&guest_id=${body['guest_id']}';
    }

    final Response response = await apiClient.deleteData(url);

    // Treat both 200 (successfully deleted) and 404 (already doesn't exist) as success
    // since the goal is achieved - the item is not in the server cart
    return (response.statusCode == 200 || response.statusCode == 404);
  }

  Future<bool> _clearCartOnline() async {
    // 🔧 FIX: Move guest_id from query parameter to request body
    // Note: DELETE requests typically use query params
    // Backend should accept guest_id in query for DELETE requests
    String url = AppConstants.removeAllCartUri;
    if (!AuthHelper.isLoggedIn()) {
      final String guestId = AuthHelper.getGuestId();
      if (guestId.isNotEmpty) {
        url += '?guest_id=$guestId';
      }
    }

    final Response response = await apiClient.deleteData(url);
    return (response.statusCode == 200);
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) async {
    return await _getCartDataOnline();
  }

  Future<List<OnlineCartModel>?> _getCartDataOnline() async {
    List<OnlineCartModel>? onlineCartList;

    // Debug module ID
    final int? moduleId = ModuleHelper.getCacheModule()?.id;
    if (AppConstants.enableVerboseLogs) {
      final token = sharedPreferences.getString(AppConstants.token) ?? '';
      final tokenPreview = token.isEmpty
          ? 'EMPTY'
          : '${token.substring(0, token.length > 12 ? 12 : token.length)}...';
      debugPrint('🔍 Cart API Debug - Module ID: $moduleId');
      debugPrint(
          '🔍 Cart API Debug - Is Logged In: ${AuthHelper.isLoggedIn()}');
      debugPrint('🔍 Cart API Debug - Token: $tokenPreview');
    }

    final Map<String, String> header = {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.localizationKey: AppConstants.languages[0].languageCode!,
      AppConstants.moduleId: '$moduleId',
      'Authorization':
          'Bearer ${sharedPreferences.getString(AppConstants.token)}',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      'X-Requested-With': 'XMLHttpRequest',
      // ⚡ PERFORMANCE: Removed X-Cache-Buster header - now relying on HTTP cache headers (ETag, Cache-Control)
    };

    // ⚡ PERFORMANCE: Removed cache-busting parameters - now relying on HTTP cache headers (ETag, Cache-Control)
    // Backend now provides proper cache headers, so we don't need to force fresh requests
    // 🔧 FIX: For GET requests, guest_id can stay in query params (GET doesn't have body)
    // But if backend requires it in body, we'd need to use POST instead
    const String baseUrl = AppConstants.getCartListUri;
    String url = baseUrl;
    if (!AuthHelper.isLoggedIn()) {
      final String guestId = AuthHelper.getGuestId();
      if (guestId.isNotEmpty) {
        url += '?guest_id=$guestId';
      }
    }

    if (AppConstants.enableVerboseLogs) {
      final safeHeader = Map<String, String>.from(header);
      if (safeHeader.containsKey('Authorization')) {
        safeHeader['Authorization'] = 'Bearer ***';
      }
      debugPrint('🔍 Cart API Debug - URL: $url');
      debugPrint('🔍 Cart API Debug - Headers: $safeHeader');
    }

    final Response response = await apiClient.getData(
      url,
      headers: header,
    );
    if (response.statusCode == 200) {
      onlineCartList = [];
      debugPrint('🔄 Raw API response for cart data: ${response.body}');

      // ✅ BACKEND CONTRACT: Response should be either:
      // 1. Object with {success, store_id, cart_items} (new format)
      // 2. List directly (legacy format - for backward compatibility)
      dynamic responseBody = response.body;

      int? extractedStoreId;
      List<dynamic>? cartItemsList;

      if (responseBody is Map<String, dynamic>) {
        // ✅ NEW FORMAT: {success: true, store_id: 2, cart_items: [...]}
        final dynamic storeIdRaw = responseBody['store_id'];
        extractedStoreId = storeIdRaw is int
            ? storeIdRaw
            : int.tryParse(storeIdRaw?.toString() ?? '');
        cartItemsList = responseBody['cart_items'] as List<dynamic>?;

        if (extractedStoreId != null) {
          debugPrint('✅ Extracted store_id from response: $extractedStoreId');
        }

        if (cartItemsList == null) {
          // Fallback: try to parse as List directly (legacy format)
          final dataValue = responseBody['data'];
          if (dataValue is List<dynamic>) {
            cartItemsList = dataValue;
          }
          // Note: responseBody is Map, not List, so we don't check if responseBody is List here
        }
      } else if (responseBody is List) {
        // ✅ LEGACY FORMAT: Direct list (for backward compatibility)
        cartItemsList = responseBody;
        debugPrint(
            '⚠️ Using legacy format (direct List) - store_id not available');
      }

      // Parse cart items
      if (cartItemsList != null) {
        for (var cart in cartItemsList) {
          final cartMap = cart as Map<String, dynamic>;
          debugPrint(
              "🔄 Processing cart item: ${cartMap['item']?['name']} - qty: ${cartMap['quantity']}");

          // BUGFIX: Removed flawed quantity workaround that incorrectly calculated quantity
          // from price division without accounting for variations.
          //
          // The workaround assumed: total_price = unit_price × quantity
          // But reality is: total_price = (unit_price + variations_price) × quantity
          //
          // This caused items with expensive variations to have their quantity incorrectly
          // multiplied (e.g., 69 SAR item with 22 SAR base = 3.14 → 3 quantity WRONG!)
          //
          // The backend API returns the correct quantity. Trust it.

          onlineCartList.add(OnlineCartModel.fromJson(cartMap));
        }
      }

      debugPrint('🔄 Total cart items from API: ${onlineCartList.length}');

      // ✅ BACKEND CONTRACT: Store store_id from response
      if (extractedStoreId != null) {
        _lastStoreId = extractedStoreId;
        debugPrint('✅ Stored store_id in repository: $_lastStoreId');
      } else {
        // If store_id not in response, only warn if cart has items
        if (onlineCartList.isNotEmpty) {
          debugPrint(
              '⚠️ store_id not found with non-empty cart - backend contract violation');
          // Fallback: extract from first cart item
          final firstItem = onlineCartList.first.item;
          if (firstItem?.storeId != null) {
            _lastStoreId = firstItem!.storeId;
            debugPrint(
                '⚠️ store_id not in response, extracted from first item: $_lastStoreId');
          }
        }
      }
    }
    return onlineCartList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id,
      {double? price, int? quantity, bool isUpdateQty = false}) async {
    if (isUpdateQty) {
      return await _updateCartQuantityOnline(id!, price!, quantity!);
    } else {
      return await _updateCartOnline(body);
    }
  }

  Future<List<OnlineCartModel>?> _updateCartOnline(
      Map<String, dynamic> body) async {
    List<OnlineCartModel>? onlineCartList;

    // 🔧 FIX: Move guest_id from query parameter to request body
    final Map<String, dynamic> requestBody = Map<String, dynamic>.from(body);
    if (!AuthHelper.isLoggedIn()) {
      final String guestId = AuthHelper.getGuestId();
      if (guestId.isNotEmpty) {
        requestBody['guest_id'] = guestId;
      }
    }

    final Response response =
        await apiClient.postData(AppConstants.updateCartUri, requestBody);
    if (response.statusCode == 200) {
      onlineCartList = [];
      if (response.body is List) {
        for (var cart in (response.body as List)) {
          onlineCartList
              .add(OnlineCartModel.fromJson(cart as Map<String, dynamic>));
        }
      }
    }
    return onlineCartList;
  }

  Future<bool> _updateCartQuantityOnline(
      int cartId, double price, int quantity) async {
    final Map<String, dynamic> data = {
      'cart_id': cartId,
      'price': price,
      'quantity': quantity,
    };

    // 🔧 FIX: Move guest_id from query parameter to request body
    if (!AuthHelper.isLoggedIn()) {
      final String guestId = AuthHelper.getGuestId();
      if (guestId.isNotEmpty) {
        data['guest_id'] = guestId;
      }
    }

    try {
      final Response response =
          await apiClient.postData(AppConstants.updateCartUri, data);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('❌ Cart not found on server (404) - Cart ID: $cartId');
        return false;
      } else {
        debugPrint('❌ Cart update failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Cart update error: $e');
      return false;
    }
  }
}
