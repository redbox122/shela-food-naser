import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_operation_exception.dart';
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

  // ───────────────────────────────────────────────────────────────────────────
  // Cart v2 — Market module (3) only.
  //
  // The market uses the lightweight `/api/v2/cart` endpoints, whose payload is a
  // FLAT item shape with no variations/add-ons. To avoid touching the
  // controller/screen/stepper pipeline (all of which read the nested
  // `CartModel.item`), each flat row is WRAPPED back into the nested shape
  // [OnlineCartModel.fromJson] expects. Restaurants/other modules keep v1.
  // ───────────────────────────────────────────────────────────────────────────

  /// True when the active cart is the market module → use the v2 endpoints.
  bool _useV2Cart() => _getModuleId() == AppConstants.marketModuleId;

  /// Localization + module header for v2 calls. The apiClient MERGES this over
  /// its default headers ([_prepareFinalHeaders]), so the Bearer token for a
  /// logged-in user is preserved automatically.
  Map<String, String> _v2Header() => {
        AppConstants.localizationKey:
            AppConstants.languages[0].languageCode ?? 'ar',
        AppConstants.moduleId: '${_getModuleId()}',
      };

  /// Appends `guest_id` to a v2 URL for guests (the cart is keyed on it).
  String _withGuestQuery(String url) {
    if (AuthHelper.isLoggedIn()) return url;
    final String guestId = AuthHelper.getGuestId();
    if (guestId.isEmpty) return url;
    return url.contains('?') ? '$url&guest_id=$guestId' : '$url?guest_id=$guestId';
  }

  /// `guest_id` entry for a v2 request body (empty for logged-in users).
  Map<String, dynamic> _guestBody() {
    if (AuthHelper.isLoggedIn()) return const {};
    final String guestId = AuthHelper.getGuestId();
    return guestId.isEmpty ? const {} : {'guest_id': guestId};
  }

  /// Throws a [CartOperationException] from a v2 `{ "error_code": ... }` body.
  Never _throwV2Error(Response response) {
    final dynamic body = response.body;
    final String? code =
        body is Map ? body['error_code']?.toString() : null;
    debugPrint('❌ Cart v2 error: status=${response.statusCode} code=$code');
    throw CartOperationException(
      statusCode: response.statusCode,
      errorCode: code,
      message: body is Map ? body['message']?.toString() : null,
    );
  }

  /// Wraps a flat v2 cart row into the nested shape the existing pipeline reads.
  Map<String, dynamic> _wrapV2CartItem(Map<String, dynamic> flat) {
    final double finalPrice = double.tryParse('${flat['price']}') ?? 0;
    final double discount = double.tryParse('${flat['discount']}') ?? 0;
    final String discountType = flat['discount_type']?.toString() ?? 'percent';
    // Reconstruct the original (pre-discount) unit price for the struck price.
    // The v2 cart `price` is already the discounted/final unit price.
    double originalPrice = finalPrice;
    if (discount > 0) {
      if (discountType == 'amount') {
        originalPrice = finalPrice + discount;
      } else if (discount < 100) {
        originalPrice = finalPrice / (1 - discount / 100);
      }
    }
    final int moduleId = _getModuleId();
    final String moduleType =
        ModuleHelper.getCacheModule()?.moduleType ?? 'ecommerce';
    return {
      'id': flat['id'], // cart row id
      'item_id': flat['item_id'],
      'module_id': moduleId,
      'quantity': flat['quantity'],
      'price': finalPrice, // discounted unit price (v1 cart.price semantics)
      // Carry the chosen options through so the cart shows them under the name.
      'variation': flat['variation'] ?? <dynamic>[],
      'add_on_ids': flat['add_on_ids'] ?? <dynamic>[],
      'add_on_qtys': flat['add_on_qtys'] ?? <dynamic>[],
      'item_type': 'Item',
      'item': {
        'id': flat['item_id'],
        'store_id': flat['store_id'],
        'module_id': moduleId,
        'module_type': moduleType,
        'name': flat['name'],
        'description': flat['description'],
        'image_full_url': flat['image_full_url'],
        'price': originalPrice,
        'original_price': originalPrice,
        'discount': discount,
        'discount_type': discountType,
        'stock': flat['stock'] ?? 9999,
        'maximum_cart_quantity': flat['maximum_cart_quantity'],
        'is_available': flat['is_available'] ?? true,
        'add_ons': <dynamic>[],
        'food_variations': <dynamic>[],
      },
    };
  }

  /// Parses a v2 cart response (a flat list, optionally wrapped) into the model
  /// list the controller consumes, and caches the cart's store id.
  List<OnlineCartModel> _parseV2CartList(dynamic body) {
    final List raw = body is List
        ? body
        : (body is Map && body['cart_items'] is List)
            ? body['cart_items'] as List
            : (body is Map && body['data'] is List)
                ? body['data'] as List
                : const [];
    final List<OnlineCartModel> list = [];
    int? storeId;
    for (final dynamic e in raw) {
      if (e is Map) {
        final Map<String, dynamic> flat = Map<String, dynamic>.from(e);
        storeId ??= int.tryParse('${flat['store_id']}');
        list.add(OnlineCartModel.fromJson(_wrapV2CartItem(flat)));
      }
    }
    _lastStoreId = list.isEmpty ? null : storeId;
    return list;
  }

  Future<List<OnlineCartModel>?> _getCartDataV2() async {
    final Response response = await apiClient.getData(
      _withGuestQuery(AppConstants.getCartListV2Uri),
      headers: _v2Header(),
    );
    if (response.statusCode != 200) return null;
    return _parseV2CartList(response.body);
  }

  Future<List<OnlineCartModel>?> _addToCartV2(OnlineCart cart) async {
    // Include the customer's chosen options. The V2 body previously carried only
    // item_id + quantity, so selected food variations / add-ons never reached
    // the server (the cart & captain always showed the item with no choices).
    final Map<String, dynamic> full = cart.toJson();
    final Map<String, dynamic> body = {
      'item_id': cart.itemId,
      'quantity': cart.quantity ?? 1,
      'variation': full['variation'] ?? <dynamic>[],
      'add_on_ids': full['add_on_ids'] ?? <dynamic>[],
      'add_on_qtys': full['add_on_qtys'] ?? <dynamic>[],
      ..._guestBody(),
    };
    final Response response = await apiClient.postData(
      AppConstants.addCartV2Uri,
      body,
      headers: _v2Header(),
    );
    if (response.statusCode == 200) return _parseV2CartList(response.body);
    _throwV2Error(response);
  }

  Future<bool> _updateCartQuantityV2(int cartId, int quantity) async {
    final Map<String, dynamic> body = {
      'cart_id': cartId,
      'quantity': quantity,
      ..._guestBody(),
    };
    final Response response = await apiClient.postData(
      AppConstants.updateCartV2Uri,
      body,
      headers: _v2Header(),
    );
    return response.statusCode == 200;
  }

  Future<bool> _removeCartItemV2(int cartId) async {
    final String url =
        _withGuestQuery('${AppConstants.removeItemCartV2Uri}?cart_id=$cartId');
    final Response response =
        await apiClient.deleteData(url, headers: _v2Header());
    // 404 → already gone; treat as success (idempotent).
    return response.statusCode == 200 || response.statusCode == 404;
  }

  Future<bool> _clearCartV2() async {
    final Response response = await apiClient.deleteData(
      _withGuestQuery(AppConstants.clearCartV2Uri),
      headers: _v2Header(),
    );
    return response.statusCode == 200;
  }

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
    if (_useV2Cart()) return _addToCartV2(cart);
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

      // Verbose-only diagnostic dumps. Pre-scan / release builds keep the
      // logs lean so payloads, prices, and store ids never leak.
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint(
            '\x1B[33m🔍 [CART ADD REQUEST BODY]:\n${const JsonEncoder.withIndent('  ').convert(cart.toJson())}\x1B[0m');
        debugPrint('\x1B[32m     ${response.body}     \x1B[0m');
      }

      if (response.body is List) {
        for (var cart in (response.body as List)) {
          onlineCartList
              .add(OnlineCartModel.fromJson(cart as Map<String, dynamic>));
        }
      }
    } else {
      debugPrint('❌ addToCartOnline failed: status=${response.statusCode}');
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('   - requestBody: $requestBody');
        debugPrint('   - responseBody: ${response.body}');
      }
      final dynamic errors = response.body is Map<String, dynamic>
          ? (response.body as Map<String, dynamic>)['errors']
          : null;
      String? errorCode;
      String? errorMessage;
      if (errors is List && errors.isNotEmpty && errors.first is Map) {
        final firstError = errors.first as Map;
        final dynamic codeValue = firstError['code'];
        final dynamic messageValue = firstError['message'];
        errorCode = codeValue?.toString();
        errorMessage = messageValue?.toString();
      }
      throw CartOperationException(
        statusCode: response.statusCode,
        errorCode: errorCode,
        message: errorMessage,
      );
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
    if (_useV2Cart()) return _removeCartItemV2(cartId);
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
    if (_useV2Cart()) return _clearCartV2();
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
    if (_useV2Cart()) return _getCartDataV2();
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
      // Verbose-only raw payload dump. Pre-scan / release builds keep the
      // logs lean — full cart payloads can be hundreds of lines and contain
      // stale prices, so we never print them by default.
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🔄 Raw API response for cart data: ${response.body}');
      }

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

        if (extractedStoreId != null && kDebugMode && AppConstants.enableVerboseLogs) {
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
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          debugPrint(
              '⚠️ Using legacy format (direct List) - store_id not available');
        }
      }

      // Parse cart items
      if (cartItemsList != null) {
        for (var cart in cartItemsList) {
          final cartMap = cart as Map<String, dynamic>;
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            debugPrint(
                "🔄 Processing cart item: ${cartMap['item']?['name']} - qty: ${cartMap['quantity']}");
          }

          onlineCartList.add(OnlineCartModel.fromJson(cartMap));
        }
      }

      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🔄 Total cart items from API: ${onlineCartList.length}');
      }

      // ✅ BACKEND CONTRACT: Store store_id from response
      if (extractedStoreId != null) {
        _lastStoreId = extractedStoreId;
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          debugPrint('✅ Stored store_id in repository: $_lastStoreId');
        }
      } else {
        // If store_id not in response, only warn if cart has items
        if (onlineCartList.isNotEmpty) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            debugPrint(
                '⚠️ store_id not found with non-empty cart - backend contract violation');
          }
          // Fallback: extract from first cart item
          final firstItem = onlineCartList.first.item;
          if (firstItem?.storeId != null) {
            _lastStoreId = firstItem!.storeId;
            if (kDebugMode && AppConstants.enableVerboseLogs) {
              debugPrint(
                  '⚠️ store_id not in response, extracted from first item: $_lastStoreId');
            }
          }
        } else {
          // API explicitly returned empty cart and no store_id -> clear stale store context.
          _lastStoreId = null;
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            debugPrint(
                'ℹ️ Empty cart response with null store_id - cleared cached store_id in repository');
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
    if (_useV2Cart()) return _updateCartQuantityV2(cartId, quantity);
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
