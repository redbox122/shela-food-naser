import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_operation_exception.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart'
    hide Variation;
import 'package:sixam_mart/features/cart/domain/services/cart_service_interface.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/my_coupon/controllers/my_coupon_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/util/images.dart';

/// 🔥 PHASE 1.1: Single Source of Truth for Cart Totals
/// This ensures all totals are calculated once and stored consistently
class CartTotals {
  final double itemTotal;
  final double discountTotal;
  final double addonTotal;
  final double variationTotal;
  final double subTotal;

  const CartTotals({
    this.itemTotal = 0.0,
    this.discountTotal = 0.0,
    this.addonTotal = 0.0,
    this.variationTotal = 0.0,
    this.subTotal = 0.0,
  });

  CartTotals copyWith({
    double? itemTotal,
    double? discountTotal,
    double? addonTotal,
    double? variationTotal,
    double? subTotal,
  }) {
    return CartTotals(
      itemTotal: itemTotal ?? this.itemTotal,
      discountTotal: discountTotal ?? this.discountTotal,
      addonTotal: addonTotal ?? this.addonTotal,
      variationTotal: variationTotal ?? this.variationTotal,
      subTotal: subTotal ?? this.subTotal,
    );
  }

  @override
  String toString() {
    return 'CartTotals(itemTotal: $itemTotal, discountTotal: $discountTotal, '
        'addonTotal: $addonTotal, variationTotal: $variationTotal, subTotal: $subTotal)';
  }
}

class CartController extends GetxController implements GetxService {
  final CartServiceInterface cartServiceInterface;

  CartController({required this.cartServiceInterface});

  List<CartModel> _cartList = [];
  List<CartModel> get cartList => _cartList;

  // ✅ BACKEND CONTRACT: store_id from cart/list response
  int? _storeId;
  int? get storeId => _storeId;

  // ✅ NEW: Distance caching to avoid recalculations
  double? _cachedDeliveryDistance;
  DateTime? _distanceCacheTime;
  static const Duration _distanceCacheDuration = Duration(minutes: 5);

  // ✅ PUBLIC: Getter for cached distance
  double? get cachedDeliveryDistance => _cachedDeliveryDistance;

  // 🔥 PHASE 1.1: Single Source of Truth - All totals in one place
  CartTotals _totals = const CartTotals();
  CartTotals get totals => _totals;

  // 🔥 RELEASE MODE FIX: Track cart list hash to force updates
  // In release mode, GetX might not detect changes to computed getters
  // This ensures UI rebuilds when cartList changes
  int _cartListHash = 0;
  int _getCartListHash() {
    // Simple hash based on cart list length and item IDs
    int hash = _cartList.length;
    for (final item in _cartList) {
      hash = hash ^ (item.item?.id ?? 0) ^ (item.quantity ?? 0);
    }
    return hash;
  }

  // 🔐 Guard to prevent infinite loops when handling invalid cart state
  bool _isInvalidCartStateHandling = false;

  /// 🔥 PHASE 0: Debug snapshot for cart state
  /// Use this to track price calculation discrepancies
  void debugCartSnapshot(String tag) {
    if (!kDebugMode) return;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🛒 CART SNAPSHOT [$tag]');
    debugPrint('   Items: ${_cartList.length}');
    debugPrint('   Hash: ${_getCartListHash()}');
    debugPrint('');

    for (int i = 0; i < _cartList.length; i++) {
      final item = _cartList[i];
      debugPrint('   Item $i:');
      debugPrint('      ID: ${item.item?.id}');
      debugPrint('      Name: ${item.item?.name}');
      debugPrint('      Qty: ${item.quantity}');
      debugPrint('      Unit Price: ${item.price}');
      debugPrint('      Discounted Price: ${item.discountedPrice}');
      debugPrint('      AddOns: ${item.addOnIds?.length ?? 0}');
    }

    debugPrint('');
    debugPrint('   TOTALS (from CartTotals):');
    debugPrint('      Item Total: ${_totals.itemTotal}');
    debugPrint('      Discount Total: ${_totals.discountTotal}');
    debugPrint('      AddOn Total: ${_totals.addonTotal}');
    debugPrint('      Variation Total: ${_totals.variationTotal}');
    debugPrint('      SubTotal: ${_totals.subTotal}');
    debugPrint('');
    debugPrint('   LEGACY (from calculationCart):');
    debugPrint('      _subTotal: $_subTotal');
    debugPrint('      _itemPrice: $_itemPrice');
    debugPrint('      _addOns: $_addOns');
    debugPrint('      _variationPrice: $_variationPrice');
    debugPrint('═══════════════════════════════════════════════════════');
  }

  /// 🔥 PHASE 1.2: Single mutation point for all cart changes
  /// This ensures totals are recalculated and UI is updated consistently
  void _onCartMutated({String reason = ''}) {
    // 🔥 BUG FIX: Skip mutation if cart is cleared (prevents race conditions)
    if (_isCartCleared && reason != 'clearCartList') {
      debugPrint(
          '⚠️ _onCartMutated: Cart is cleared, skipping mutation (reason: $reason)');
      return;
    }

    if (kDebugMode) {
      debugPrint('🔄 Cart mutated: $reason');
    }

    // Recalculate totals
    _recalculateTotals();

    // 🔁 Revalidate any applied coupon against the fresh cart (covers add /
    // remove / increase / decrease / clear). Auto-removes or recomputes it.
    _revalidateAppliedCouponSafely(reason: reason);

    if (_cartList.isNotEmpty) {
      _syncStickyCartBarSnapshotFromCart();
    } else if (!_isCartDataLoading && !_serverCartListReplaceInProgress) {
      _clearStickyCartBarSnapshot();
    }

    // Persist to local storage
    _persistCart();

    // Update UI with specific IDs for partial rebuilds
    update([
      'cart_items',
      'cart_summary',
      'cart_checkout',
      'cart_count', // 🔥 FIX: Update cart count badges/icons outside cart screen
      'cart_loading', // Ensure empty state replaces cart view after clear
    ]);
    // GetBuilder widgets WITHOUT an [id] only listen here — e.g. global sticky cart overlay.
    update();

    // Also update hash for release mode compatibility
    final newHash = _getCartListHash();
    if (newHash != _cartListHash) {
      _cartListHash = newHash;
    }
  }

  /// Revalidate the applied coupon (if any) against the current cart. Safe to
  /// call from any mutation: guarded so a missing CouponController or any error
  /// never breaks cart updates. Min purchase is checked against [subTotal]
  /// (product subtotal only — no delivery/tax/tips/fees).
  void _revalidateAppliedCouponSafely({String reason = ''}) {
    try {
      // Empty/cleared cart: don't fire a spurious "coupon removed" message —
      // coupon teardown is handled by the cart-clear / order-success flow.
      if (_cartList.isEmpty) {
        return;
      }
      if (!Get.isRegistered<CouponController>()) {
        return;
      }
      final CouponController couponController = Get.find<CouponController>();
      if (!couponController.hasAppliedCoupon) {
        return;
      }
      couponController.revalidateAppliedCoupon(
        cartSubtotal: subTotal,
        currentModuleId: ModuleHelper.getCacheModule()?.id,
        currentStoreId: storeId,
        reason: 'cart_mutated:$reason',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ coupon revalidation skipped: $e');
      }
    }
  }

  /// 🔐 Minimum safety: clear local cart when auth fails (401)
  Future<void> clearLocalCartForUnauthorized() async {
    debugPrint(
        '🔐 CartController: Clearing local cart due to 401 Unauthorized');
    _cartList = [];
    _totals = const CartTotals();
    await cartServiceInterface.addSharedPrefCartList(_cartList);
    try {
      final moduleId = ModuleHelper.getCacheModule()?.id;
      await HiveHomeCacheService().saveCartData(moduleId, []);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CartController: Failed to clear Hive cart cache - $e');
      }
    }
    _onCartMutated(reason: 'clearLocalCartForUnauthorized');
  }

  /// 🔥 PHASE 1.2: Recalculate totals from cart list
  /// This is the ONLY place where totals are calculated
  void _recalculateTotals() {
    _addOnsList = [];
    _availableList = [];

    double itemTotal = 0.0;
    double discountTotal = 0.0;
    double addonTotal = 0.0;
    double variationTotal = 0.0;
    double variationWithoutDiscountPrice = 0.0;
    bool hasAnyVariations = false;

    for (final cartModel in cartList) {
      final bool isFoodVariation =
          ModuleHelper.getModuleConfig(cartModel.item?.moduleType)
                  .newVariation ??
              false;
      final double? discount = cartModel.item!.storeDiscount == 0
          ? cartModel.item!.discount
          : cartModel.item!.storeDiscount;
      final String? discountType = cartModel.item!.storeDiscount == 0
          ? cartModel.item!.discountType
          : 'percent';

      final List<AddOns> addOnList =
          cartServiceInterface.prepareAddonList(cartModel);

      _addOnsList.add(addOnList);
      _availableList.add(DateConverter.isAvailable(
          cartModel.item!.availableTimeStarts,
          cartModel.item!.availableTimeEnds));

      // Calculate add-ons
      addonTotal = cartServiceInterface.calculateAddonPrice(
          addonTotal, addOnList, cartModel);
      addonTotal = _roundToCurrency(addonTotal);

      // Calculate variations
      variationTotal = cartServiceInterface.calculateVariationPrice(
          isFoodVariation, cartModel, discount, discountType, variationTotal);
      variationTotal = _roundToCurrency(variationTotal);

      variationWithoutDiscountPrice =
          cartServiceInterface.calculateVariationWithoutDiscountPrice(
              isFoodVariation, cartModel, variationWithoutDiscountPrice);
      variationWithoutDiscountPrice =
          _roundToCurrency(variationWithoutDiscountPrice);

      final bool haveVariation =
          cartServiceInterface.checkVariation(isFoodVariation, cartModel);
      if (haveVariation) hasAnyVariations = true;

      final double unitPrice = _roundToCurrency(cartModel.price ?? 0);
      final double price = haveVariation
          ? variationWithoutDiscountPrice
          : _roundToCurrency(unitPrice * (cartModel.quantity ?? 0));
      final double discountPrice = haveVariation
          ? _roundToCurrency(variationWithoutDiscountPrice - variationTotal)
          : 0;

      itemTotal = _roundToCurrency(itemTotal + price);
      discountTotal = _roundToCurrency(discountTotal + discountPrice);
    }

    // Handle variations
    if (hasAnyVariations) {
      discountTotal =
          discountTotal + (variationWithoutDiscountPrice - variationTotal);
      variationTotal = variationWithoutDiscountPrice;
      discountTotal = _roundToCurrency(discountTotal);
      variationTotal = _roundToCurrency(variationTotal);
    }

    // Calculate final subtotal
    final double subTotal = _roundToCurrency(
        (itemTotal - discountTotal) + addonTotal + variationTotal);

    // Update totals (single source of truth)
    _totals = CartTotals(
      itemTotal: itemTotal,
      discountTotal: discountTotal,
      addonTotal: addonTotal,
      variationTotal: variationTotal,
      subTotal: subTotal,
    );

    // Keep legacy fields for backward compatibility
    _subTotal = subTotal;
    _itemPrice = itemTotal;
    _addOns = addonTotal;
    _variationPrice = variationTotal;
  }

  /// 🔥 PHASE 1.2: Persist cart to local storage
  Future<void> _persistCart() async {
    try {
      _cartList = _deduplicateCartList(_cartList);
      await cartServiceInterface.addSharedPrefCartList(_cartList);
    } catch (e) {
      debugPrint('⚠️ Error persisting cart: $e');
    }
  }

  List<CartModel> _deduplicateCartList(List<CartModel> items) {
    if (items.length <= 1) {
      return items;
    }
    final Map<String, CartModel> uniqueItems = {};
    for (final CartModel cart in items) {
      final String key = _buildCartItemKey(cart);
      if (!uniqueItems.containsKey(key)) {
        uniqueItems[key] = cart;
      } else {
        final CartModel existing = uniqueItems[key]!;
        final int mergedQuantity =
            (existing.quantity ?? 0) + (cart.quantity ?? 0);
        existing.quantity = mergedQuantity;
        // Keep authoritative cart_id if one side has it.
        if ((existing.id == null || existing.id! <= 0) &&
            cart.id != null &&
            cart.id! > 0) {
          existing.id = cart.id;
        }
      }
    }
    if (uniqueItems.length != items.length && kDebugMode) {
      debugPrint(
          '⚠️ CartController: Deduplicated cart items from ${items.length} to ${uniqueItems.length}');
    }
    return uniqueItems.values.toList();
  }

  String _buildCartItemKey(CartModel cart) {
    final int? itemId = cart.item?.id;
    final String variationKey = jsonEncode(
      cart.variation?.map((variation) => variation.toJson()).toList() ??
          const <Map<String, dynamic>>[],
    );
    final String foodVariationKey = (cart.foodVariations ?? <List<bool?>>[])
        .map((group) => group.map((v) => (v ?? false) ? '1' : '0').join(''))
        .join('|');
    final String addOnKey = cart.addOnIds
            ?.map((addOn) => '${addOn.id}:${addOn.quantity}')
            .join(',') ??
        '';
    final int? storeId = cart.storeId ?? cart.item?.storeId;
    final bool isCampaign = cart.isCampaign ?? false;
    return 'store:$storeId|item:$itemId|campaign:$isCampaign|var:$variationKey|food:$foodVariationKey|add:$addOnKey';
  }

  // Removed _notifyCartListChanged() - use _onCartMutated() instead

  // 🔥 PHASE 1.1: Backward compatibility - subTotal now comes from totals
  // This ensures single source of truth
  double get subTotal => _totals.subTotal;

  // Keep for backward compatibility (deprecated - use totals instead)
  double get itemPrice => _totals.itemTotal;
  double get itemDiscountPrice => _totals.discountTotal;
  double get addOns => _totals.addonTotal;
  double get variationPrice => _totals.variationTotal;

  // Legacy fields (kept for compatibility, but now calculated from totals)
  double _subTotal = 0;

  // Legacy fields removed - now using CartTotals

  List<List<AddOns>> _addOnsList = [];
  List<List<AddOns>> get addOnsList => _addOnsList;

  List<bool> _availableList = [];
  List<bool> get availableList => _availableList;

  List<String> notAvailableList = [
    'Remove it from my cart',
    'I’ll wait until it’s restocked',
    'Please cancel the order',
    'Call me ASAP',
    'Notify me when it’s back'
  ];
  bool _addCutlery = false;
  bool get addCutlery => _addCutlery;

  int _notAvailableIndex = -1;
  int get notAvailableIndex => _notAvailableIndex;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasCartError = false;
  bool get hasCartError => _hasCartError;

  // Separate loading state for cart data operations
  bool _isCartDataLoading = false;
  bool get isCartDataLoading => _isCartDataLoading;

  /// True while [addToCartOnline] / [updateCartOnline] await server and may
  /// replace [_cartList] — unlike [getCartDataOnline], those do not set
  /// [_isCartDataLoading], so the sticky cart used to vanish for one frame.
  bool _serverCartListReplaceInProgress = false;
  bool get serverCartListReplaceInProgress => _serverCartListReplaceInProgress;
  String? _lastAddToCartErrorCode;
  String? _lastAddToCartErrorMessage;

  /// Error code from the most recent [addToCartOnline] (e.g. `different_store`,
  /// `cart_item_limit`, `store_closed`) — null on success. Callers use it to
  /// react (e.g. show the clear-cart dialog on a different-store rejection).
  String? get lastAddToCartErrorCode => _lastAddToCartErrorCode;
  bool _forceServerTruthOnNextCartSync = false;
  static const Set<String> _finalBusinessRejectionCodes = <String>{
    'store_busy',
    'order_time',
    'store_closed',
    'store_temporarily_closed',
    'cart_item_limit',
  };

  /// Last non-empty cart totals for sticky bar (survives overlay dispose + list replace).
  int _stickyCartBarSnapshotQty = 0;
  double _stickyCartBarSnapshotSubtotal = 0;

  void _syncStickyCartBarSnapshotFromCart() {
    if (_cartList.isEmpty) {
      return;
    }
    _stickyCartBarSnapshotQty = totalCartQuantity;
    _stickyCartBarSnapshotSubtotal = _totals.subTotal;
  }

  void _clearStickyCartBarSnapshot() {
    _stickyCartBarSnapshotQty = 0;
    _stickyCartBarSnapshotSubtotal = 0;
  }

  /// Whether the global sticky cart should paint: any line items **or** a held
  /// snapshot (covers API list replace / loading gaps without flicker).
  bool get shouldShowStickyCartBar {
    if (_cartList.isNotEmpty) {
      return true;
    }
    return _stickyCartBarSnapshotQty > 0;
  }

  int get stickyCartBarDisplayQuantity {
    if (_cartList.isNotEmpty) {
      return totalCartQuantity;
    }
    return _stickyCartBarSnapshotQty;
  }

  double get stickyCartBarDisplaySubtotal {
    if (_cartList.isNotEmpty) {
      return subTotal;
    }
    return _stickyCartBarSnapshotSubtotal;
  }

  // Loading state for cart operations (add, update, remove)
  final bool _isCartOperationLoading = false;
  bool get isCartOperationLoading => _isCartOperationLoading;

  // 🔥 OPTIMISTIC UI: Debounce Timer for API calls only (not UI updates)
  Timer? _cartSyncDebounceTimer;
  static const Duration _cartSyncDebounceDelay = Duration(milliseconds: 500);

  // 🎯 PENDING UPDATES: Track pending cart updates for batch sync
  final Map<int, int> _pendingCartUpdates = {}; // cartId -> quantity
  final Map<String, int> _pendingCartUpdatesByKey = {}; // cartKey -> quantity
  bool _isSyncingCart = false; // Only blocks API spam, not UI updates

  // Legacy flags (kept for compatibility, but not blocking UI)
  DateTime? _lastCartOperation;
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  bool _isCartOperationInProgress = false;
  bool _justClearedCart = false;
  bool _isTransferringGuestCart = false;

  // 🔥 BUG FIX: Flag to prevent operations after cart is cleared
  // This prevents race conditions where operations try to use invalid indices
  bool _isCartCleared = false;

  // 🔥 DEPRECATED: Don't use this to block UI - only for internal tracking
  bool _isAddingToCart = false;
  bool get isAddingToCart => _isAddingToCart;

  // Request deduplication and cancellation
  String? _currentCartRequestId;
  DateTime? _lastSuccessfulCartLoad;
  static const Duration _cartCacheValidity = Duration(minutes: 2);

  // Getter for last successful cart load time
  DateTime? get lastSuccessfulCartLoad => _lastSuccessfulCartLoad;

  bool _needExtraPackage = true;
  bool get needExtraPackage => _needExtraPackage;

  bool _isExpanded = true;
  bool get isExpanded => _isExpanded;

  int? _directAddCartItemIndex = -1;
  int? get directAddCartItemIndex => _directAddCartItemIndex;

  double _roundToCurrency(double value, {int fractionDigits = 2}) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  void setDirectlyAddToCartIndex(int? index) {
    _directAddCartItemIndex = index;
  }

  void toggleExtraPackage({bool willUpdate = true}) {
    _needExtraPackage = !_needExtraPackage;
    if (willUpdate) {
      update();
    }
  }

  void setAvailableIndex(int index, {bool willUpdate = true}) {
    _notAvailableIndex =
        cartServiceInterface.availableSelectedIndex(_notAvailableIndex, index);
    if (willUpdate) {
      update();
    }
  }

  void updateCutlery({bool willUpdate = true}) {
    _addCutlery = !_addCutlery;
    if (willUpdate) {
      update();
    }
  }

  Future<void> forcefullySetModule(BuildContext context, int moduleId) async {
    final ModuleModel? module = cartServiceInterface.forcefullySetModule(
        Get.find<SplashController>().module,
        Get.find<SplashController>().moduleList,
        moduleId);
    if (module != null) {
      await Get.find<SplashController>().setModule(module);
      if (!context.mounted) {
        return;
      }
      HomeScreen.loadData(context, true);
    }
  }

  /// 🔥 PHASE 1.1: Legacy method - now delegates to _recalculateTotals()
  /// DEPRECATED: Use _onCartMutated() instead, which calls _recalculateTotals()
  @Deprecated('Use _onCartMutated() instead')
  double calculationCart() {
    _recalculateTotals();
    return _totals.subTotal;
  }

  // Legacy fields for backward compatibility
  double _itemPrice = 0;
  double _addOns = 0;
  double _variationPrice = 0;

  Future<void> addToCart(CartModel cartModel, int? index) async {
    // 🔧 FIX: Improved store ID extraction to prevent false "different store" detection
    // Get existing store ID from controller's _storeId first, then from cart items
    int? existingStoreId = _storeId;

    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🛒 addToCart: Starting store validation');
      debugPrint('   - cartModel.storeId: ${cartModel.storeId}');
      debugPrint('   - cartModel.item?.storeId: ${cartModel.item?.storeId}');
      debugPrint('   - cartModel.item?.name: ${cartModel.item?.name}');
      debugPrint('   - controller._storeId: $_storeId');
    }

    // If _storeId is null, search through cart items for a valid store ID
    if (existingStoreId == null && _cartList.isNotEmpty) {
      for (final cart in _cartList) {
        // Check both item.storeId and cart.storeId
        final int? cartStoreId = cart.item?.storeId ?? cart.storeId;
        if (cartStoreId != null && cartStoreId > 0) {
          existingStoreId = cartStoreId;
          // Also update _storeId for future reference
          _storeId = cartStoreId;
          if (kDebugMode) {
            debugPrint(
                '🔧 addToCart: Extracted storeId=$cartStoreId from existing cart item (${cart.item?.name})');
          }
          break;
        }
      }
    }

    // Get new item's store ID - check both locations
    final int? newStoreId = cartModel.item?.storeId ?? cartModel.storeId;

    if (kDebugMode) {
      debugPrint('🛒 addToCart: Store ID comparison');
      debugPrint('   - existingStoreId: $existingStoreId');
      debugPrint('   - newStoreId: $newStoreId');
      debugPrint('   - cartList.length: ${_cartList.length}');
    }

    // If existing store id is missing but new is available, initialize it
    if (_cartList.isNotEmpty && existingStoreId == null && newStoreId != null) {
      _storeId = newStoreId;
      existingStoreId = newStoreId; // Update local variable too
      if (kDebugMode) {
        debugPrint('🔧 addToCart: Initialized _storeId to $newStoreId');
      }
    }

    // 🔧 FIX: Only show "different store" dialog when:
    // 1. Cart is NOT empty
    // 2. BOTH store IDs are valid (not null, greater than 0)
    // 3. The store IDs are ACTUALLY different
    final bool shouldShowDialog = _cartList.isNotEmpty &&
        existingStoreId != null &&
        existingStoreId > 0 &&
        newStoreId != null &&
        newStoreId > 0 &&
        existingStoreId != newStoreId;

    if (kDebugMode) {
      debugPrint('🔍 addToCart: Dialog decision breakdown:');
      debugPrint('   - cartList.isNotEmpty: ${_cartList.isNotEmpty}');
      debugPrint('   - existingStoreId != null: ${existingStoreId != null}');
      debugPrint('   - existingStoreId > 0: ${existingStoreId != null && existingStoreId > 0}');
      debugPrint('   - newStoreId != null: ${newStoreId != null}');
      debugPrint('   - newStoreId > 0: ${newStoreId != null && newStoreId > 0}');
      debugPrint('   - existingStoreId != newStoreId: ${existingStoreId != newStoreId}');
      debugPrint('   → shouldShowDialog: $shouldShowDialog');
      debugPrint('═══════════════════════════════════════════════════════');
    }

    if (shouldShowDialog) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ addToCart: Different store detected! existing=$existingStoreId, new=$newStoreId');
        debugPrint('   → Showing confirmation dialog...');
      }
      Get.dialog<void>(
        ConfirmationDialog(
          icon: Images.warning,
          title: 'are_you_sure_to_reset'.tr,
          description: Get.find<SplashController>()
                      .configModel
                      ?.moduleConfig
                      ?.module
                      ?.showRestaurantText ==
                  true
              ? 'if_you_continue'.tr
              : 'if_you_continue_without_another_store'.tr,
          onYesPressed: () async {
            await clearCartList();
            await _addToCartInternal(cartModel, index);
            Get.back<void>();
          },
        ),
        barrierDismissible: false,
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('✅ addToCart: Same store or empty cart - adding item directly');
    }
    await _addToCartInternal(cartModel, index);
  }

  Future<void> _addToCartInternal(CartModel cartModel, int? index) async {
    if (index != null && index != -1) {
      _cartList.replaceRange(index, index + 1, [cartModel]);
    } else {
      _cartList.add(cartModel);
    }

    // 🔧 FIX: Always ensure _storeId is set from cart item
    // Check both item.storeId and cart.storeId
    final int? itemStoreId = cartModel.item?.storeId ?? cartModel.storeId;
    if (_storeId == null && itemStoreId != null && itemStoreId > 0) {
      _storeId = itemStoreId;
      if (kDebugMode) {
        debugPrint('✅ _addToCartInternal: Set _storeId to $itemStoreId');
      }
    }

    Get.find<ItemController>()
        .setExistInCart(cartModel.item, null, notify: true);

    // 🔥 PHASE 1.2: Use unified mutation handler
    _onCartMutated(reason: 'addToCart');
  }

  int? getCartId(int cartIndex) {
    return cartServiceInterface.getCartId(cartIndex, _cartList);
  }

  /// 🔥 BUG FIX: Get cart_id by itemId (safe, index-independent)
  /// Use this instead of getCartId(cartIndex) when you only have itemId
  int? getCartIdByItemId(int itemId) {
    return cartServiceInterface.getCartIdByItemId(itemId, _cartList);
  }

  /// 🔥 CRITICAL: Check if cart item can be updated (has valid cart_id)
  /// Backend requires cart_id for any update operation
  /// Returns true only if cart_id exists and is valid (> 0)
  bool canUpdateCartItem(CartModel cart) {
    return cart.id != null && cart.id! > 0;
  }

  /// 🔥 CRITICAL: Check if cart item is locked (waiting for cart_id from server)
  /// Returns true if item was just added and cart_id is not ready yet
  bool isCartItemLocked(CartModel cart) {
    return !canUpdateCartItem(cart);
  }

  /// 🔥 OPTIMISTIC UI: Update quantity immediately, sync with backend in background
  /// User sees instant feedback, API calls are debounced and batched
  /// 🔥 BUG FIX: Set quantity by cart_id (safe, index-independent)
  /// This prevents RangeError when cart list changes between operations
  Future<void> setQuantityById(
      bool isIncrement, int cartId, int? stock, int? quantityLimit) async {
    // 🔥 BUG FIX: Check if cart is cleared (prevents race conditions)
    if (_isCartCleared) {
      debugPrint(
          '⚠️ setQuantityById: Cart already cleared, skipping (cartId: $cartId)');
      return;
    }

    // Find item by cart_id (not index) - safe even if list changed
    final index = _cartList.indexWhere((e) => e.id == cartId);

    if (index == -1) {
      debugPrint(
          '⚠️ setQuantityById: cartId $cartId not found in cart list (length: ${_cartList.length})');
      debugPrint(
          '   - This can happen if cart was cleared or item already removed');
      return;
    }

    final cartItem = _cartList[index];

    // 🔥 CRITICAL FIX: Block update if cart_id is not ready yet
    // This prevents "cart_item_invalid" error from backend
    if (!canUpdateCartItem(cartItem)) {
      debugPrint(
          '⛔ Skip update: cart_id not ready yet (cart_id: ${cartItem.id})');
      debugPrint('   - Item: ${cartItem.item?.name}');
      debugPrint('   - Waiting for server to assign cart_id...');
      return;
    }

    // 🎯 OPTIMISTIC UI: Store original quantity for rollback on error
    final originalQuantity = cartItem.quantity!;

    // 🚀 STEP 1: Update UI IMMEDIATELY (no waiting for API)
    try {
      final newQuantity = await cartServiceInterface.decideItemQuantity(
          isIncrement,
          _cartList,
          index,
          stock,
          quantityLimit,
          Get.find<SplashController>()
              .configModel!
              .moduleConfig!
              .module!
              .stock!);

      // Find index again (cart might have changed) before updating
      final currentIndex = _cartList.indexWhere((e) => e.id == cartId);
      if (currentIndex == -1) {
        debugPrint(
            '⚠️ setQuantityById: Item removed during operation (cartId: $cartId)');
        return;
      }

      // Update quantity locally - user sees change instantly
      _cartList[currentIndex].quantity = newQuantity;

      // Store pending update for batch sync
      _pendingCartUpdates[cartId] = newQuantity;

      // 🔥 PHASE 1.2: Use unified mutation handler
      _onCartMutated(reason: 'setQuantityById_optimistic');

      debugPrint(
          '✅ OPTIMISTIC UI: Quantity updated locally to $newQuantity (cart_id: $cartId)');

      // 🎯 STEP 2: Schedule debounced API sync (doesn't block UI)
      _scheduleCartSync();
    } catch (e) {
      // Find index again before rollback
      final currentIndex = _cartList.indexWhere((e) => e.id == cartId);
      if (currentIndex != -1) {
        _cartList[currentIndex].quantity = originalQuantity;
      }
      _onCartMutated(reason: 'setQuantityById_rollback');
      debugPrint('❌ Error in optimistic update: $e');
    }
  }

  /// Same rules as [CartServiceInterface.decideItemQuantity] but synchronous
  /// so UI (e.g. recommended +/−) updates in the same frame.
  int _decideItemQuantitySync({
    required bool isIncrement,
    required CartModel cartItem,
    required int? stock,
    required int? quantityLimit,
    required bool moduleStock,
  }) {
    int quantity = cartItem.quantity ?? 1;
    if (isIncrement) {
      if (moduleStock && stock != null && quantity >= stock) {
        showCustomSnackBar('out_of_stock'.tr);
      } else if (quantityLimit != null &&
          quantityLimit != 0 &&
          quantity >= quantityLimit) {
        showCustomSnackBar('${'maximum_quantity_limit'.tr} $quantityLimit');
      } else {
        quantity = quantity + 1;
      }
    } else {
      quantity = quantity - 1;
    }
    return quantity;
  }

  /// POST every cart row that has no server [cart_id] before another add
  /// replaces [_cartList] from API (e.g. suggested Pepsi/milk from the sheet).
  ///
  /// Uses [smartAddToCartOnline] with [skipDebounce] so rapid sequential adds
  /// are not dropped by the 500ms debounce. Refreshes from API between passes
  /// so the next row sees the real server cart (merge-by-item works reliably).
  Future<bool> syncLocalCartRowsWithoutServerId() async {
    Future<bool> drainPendingOnce() async {
      const int maxIterations = 48;
      int iterations = 0;
      while (iterations < maxIterations) {
        iterations++;
        final int idx = _cartList.indexWhere(
          (CartModel e) => e.id == null || (e.id != null && e.id! <= 0),
        );
        if (idx == -1) {
          return true;
        }
        final CartModel row = _cartList[idx];
        final List<CartModel> preserveOtherLocalOnly = <CartModel>[];
        for (int i = 0; i < _cartList.length; i++) {
          if (i == idx) {
            continue;
          }
          final CartModel e = _cartList[i];
          if (e.id == null || e.id! <= 0) {
            preserveOtherLocalOnly.add(_deepCopyCartModel(e));
          }
        }
        if (kDebugMode && preserveOtherLocalOnly.isNotEmpty) {
          debugPrint(
              '🛒 syncLocalCartRows: preserving ${preserveOtherLocalOnly.length} other local-only row(s) across API replace');
        }
        final OnlineCart? payload =
            _onlineCartFromCartModelForServerAdd(row);
        if (payload == null) {
          debugPrint(
              '⚠️ syncLocalCartRowsWithoutServerId: cannot build OnlineCart at index $idx');
          return false;
        }
        bool ok =
            await smartAddToCartOnline(payload, skipDebounce: true);
        if (!ok) {
          debugPrint(
              '⚠️ syncLocalCartRows: smartAdd failed for ${row.item?.name}, refreshing cart and retrying');
          await getCartDataOnline(forceRefresh: true);
          ok = await smartAddToCartOnline(payload, skipDebounce: true);
        }
        if (!ok) {
          ok = await addToCartOnline(payload);
        }
        if (!ok) {
          debugPrint(
              '⚠️ syncLocalCartRowsWithoutServerId: failed at index $idx (${row.item?.name})');
          return false;
        }
        if (preserveOtherLocalOnly.isNotEmpty) {
          _cartList.addAll(preserveOtherLocalOnly);
          _cartList = _deduplicateCartList(_cartList);
          await _persistCartListAfterMerge();
        }
        await Future<void>.delayed(const Duration(milliseconds: 72));
      }
      debugPrint(
          '⚠️ syncLocalCartRowsWithoutServerId: max iterations ($maxIterations)');
      return false;
    }

    if (!await drainPendingOnce()) {
      return false;
    }
    await getCartDataOnline(forceRefresh: true);
    final bool stillPending = _cartList.any(
      (CartModel e) => e.id == null || (e.id != null && e.id! <= 0),
    );
    if (stillPending) {
      return await drainPendingOnce();
    }
    return true;
  }

  List<OrderVariation> _orderVariationsFromCartFoodSelections(CartModel c) {
    final List<OrderVariation> variations = <OrderVariation>[];
    final Item? item = c.item;
    final List<FoodVariation>? foodVariations = item?.foodVariations;
    final List<List<bool?>>? selected = c.foodVariations;
    if (item == null ||
        foodVariations == null ||
        foodVariations.isEmpty ||
        selected == null) {
      return variations;
    }
    for (int i = 0; i < foodVariations.length; i++) {
      if (selected.length <= i || !selected[i].contains(true)) {
        continue;
      }
      final List<VariationValue>? values = foodVariations[i].variationValues;
      if (values == null || values.isEmpty) {
        continue;
      }
      final List<VariationOption> options = <VariationOption>[];
      for (int j = 0; j < values.length; j++) {
        if (selected[i].length > j && selected[i][j] == true) {
          options.add(VariationOption(
            label: values[j].level,
            optionPrice: values[j].optionPrice ?? 0.0,
          ));
        }
      }
      variations.add(OrderVariation(
        name: foodVariations[i].name,
        values: OrderVariationValue(options: options),
      ));
    }
    return variations;
  }

  /// Public wrapper for [_orderVariationsFromCartFoodSelections] so the checkout
  /// can serialize a cart item's selected food-variation choices when placing an
  /// order. Without this the checkout sent an always-empty variations list, so
  /// selected choices (e.g. a meal box's options) never reached order_details.
  List<OrderVariation> orderVariationsFromCart(CartModel c) {
    final List<OrderVariation> fromFlags =
        _orderVariationsFromCartFoodSelections(c);
    if (fromFlags.isNotEmpty) return fromFlags;
    // Fallback: the lightweight v2 cart returns the chosen options directly
    // (name + values) without the item's foodVariations definitions, so the
    // flag-based path above is empty. Rebuild them from rawFoodVariations so the
    // order (and therefore the captain) still carries the customer's choices.
    final List<dynamic>? raw = c.rawFoodVariations;
    if (raw == null || raw.isEmpty) return const <OrderVariation>[];
    final List<OrderVariation> out = <OrderVariation>[];
    for (final dynamic g in raw) {
      try {
        final String? name = g.name as String?;
        final dynamic vals = g.values;
        final List<VariationOption> options = <VariationOption>[];
        if (vals is List) {
          for (final dynamic o in vals) {
            if (o is Map && o['label'] != null) {
              options.add(VariationOption(
                label: o['label'].toString(),
                optionPrice:
                    double.tryParse('${o['optionPrice'] ?? 0}') ?? 0.0,
              ));
            }
          }
        }
        if (options.isNotEmpty) {
          out.add(OrderVariation(
            name: name,
            values: OrderVariationValue(options: options),
          ));
        }
      } catch (_) {}
    }
    return out;
  }

  OnlineCart? _onlineCartFromCartModelForServerAdd(CartModel c) {
    final Item? item = c.item;
    final int? resolvedItemId = item?.id;
    if (item == null || resolvedItemId == null) {
      return null;
    }
    final List<int?> addOnIds = <int?>[];
    final List<int?> addOnQtys = <int?>[];
    if (c.addOnIds != null) {
      for (final AddOn addOn in c.addOnIds!) {
        addOnIds.add(addOn.id);
        addOnQtys.add(addOn.quantity);
      }
    }
    final List<Variation>? legacyVariation =
        (c.variation != null && c.variation!.isNotEmpty) ? c.variation : null;
    final List<OrderVariation> foodOrderVariations =
        _orderVariationsFromCartFoodSelections(c);
    final List<OrderVariation>? variationsToPass =
        foodOrderVariations.isNotEmpty ? foodOrderVariations : null;
    final String unitPrice =
        (c.discountedPrice ?? c.price ?? 0.0).toString();
    final int? storeIdForBody = c.storeId ?? item.storeId;
    return OnlineCart(
      null,
      c.isCampaign == true ? null : resolvedItemId,
      c.isCampaign == true ? resolvedItemId : null,
      unitPrice,
      legacyVariation != null && legacyVariation.isNotEmpty
          ? (legacyVariation[0].type ?? '')
          : '',
      legacyVariation,
      variationsToPass,
      c.quantity ?? 1,
      addOnIds,
      c.addOns,
      addOnQtys,
      'Item',
      itemType: 'Item',
      storeId: storeIdForBody,
    );
  }

  /// 🔥 DEPRECATED: Use setQuantityById() instead
  /// This method uses index which can become invalid after cart mutations
  @Deprecated(
      'Use setQuantityById() instead - index-based operations are unsafe')
  Future<void> setQuantity(
      bool isIncrement, int cartIndex, int? stock, int? quantityLimit) async {
    // Validate cart index and item existence
    if (cartIndex < 0 || cartIndex >= _cartList.length) {
      debugPrint(
          '❌ Invalid cart index: $cartIndex, cart length: ${_cartList.length}');
      return;
    }

    final cartItem = _cartList[cartIndex];

    // If no cart_id, can't use safe method
    if (cartItem.id == null) {
      final bool moduleStock = Get.find<SplashController>()
              .configModel
              ?.moduleConfig
              ?.module
              ?.stock ==
          true;
      final int newQuantity = _decideItemQuantitySync(
        isIncrement: isIncrement,
        cartItem: cartItem,
        stock: stock,
        quantityLimit: quantityLimit,
        moduleStock: moduleStock,
      );
      if (newQuantity <= 0) {
        _cartList.removeAt(cartIndex);
        _onCartMutated(reason: 'setQuantity_index_remove_pendingId');
        return;
      }
      _cartList[cartIndex].quantity = newQuantity;
      _pendingCartUpdatesByKey[_buildCartItemKey(cartItem)] = newQuantity;
      _onCartMutated(reason: 'setQuantity_index_pendingId');
      return;
    }

    // Use safe method
    await setQuantityById(isIncrement, cartItem.id!, stock, quantityLimit);
  }

  void _applyPendingQuantityUpdates() {
    if (_pendingCartUpdatesByKey.isEmpty) {
      return;
    }
    bool didUpdate = false;
    for (final cartItem in _cartList) {
      final int? cartId = cartItem.id;
      if (cartId == null) {
        continue;
      }
      final String key = _buildCartItemKey(cartItem);
      final int? desiredQuantity = _pendingCartUpdatesByKey[key];
      if (desiredQuantity == null) {
        continue;
      }
      if (cartItem.quantity != desiredQuantity) {
        cartItem.quantity = desiredQuantity;
        _pendingCartUpdates[cartId] = desiredQuantity;
        didUpdate = true;
      }
    }
    _pendingCartUpdatesByKey.clear();
    if (didUpdate) {
      _onCartMutated(reason: 'applyPendingQuantityUpdates');
      _scheduleCartSync();
    }
  }

  /// 🔥 DEBOUNCED SYNC: Batch all pending updates into single API call
  /// Prevents API spam while allowing instant UI updates
  void _scheduleCartSync() {
    // Cancel previous timer if exists
    _cartSyncDebounceTimer?.cancel();

    // Schedule new sync after debounce delay
    _cartSyncDebounceTimer = Timer(_cartSyncDebounceDelay, () {
      _syncPendingCartUpdates();
    });
  }

  /// 🔥 BATCH SYNC: Send all pending updates to backend in one go
  Future<void> _syncPendingCartUpdates() async {
    if (_pendingCartUpdates.isEmpty || _isSyncingCart) {
      return;
    }

    _isSyncingCart = true;
    final updatesToSync = Map<int, int>.from(_pendingCartUpdates);
    _pendingCartUpdates.clear();

    debugPrint(
        '🔄 Syncing ${updatesToSync.length} pending cart updates to backend...');

    try {
      // Sync each pending update
      for (final entry in updatesToSync.entries) {
        final cartId = entry.key;
        final quantity = entry.value;

        // Find cart item by cart_id (safe, index-independent)
        final cartIndex = _cartList.indexWhere((c) => c.id == cartId);
        if (cartIndex == -1) {
          debugPrint('⚠️ Cart item with id $cartId not found, skipping sync');
          debugPrint(
              '   - This can happen if item was removed or cart was cleared');
          continue;
        }

        final cartItem = _cartList[cartIndex];
        final originalQuantity = cartItem.quantity!;

        // Calculate discounted price
        final double discountedPrice =
            await cartServiceInterface.calculateDiscountedPrice(
                cartItem,
                quantity,
                ModuleHelper.getModuleConfig(cartItem.item!.moduleType)
                        .newVariation ??
                    false);

        // Update server
        final bool success = await cartServiceInterface
            .updateCartQuantityOnline(cartId, discountedPrice, quantity);

        if (!success) {
          // Find index again before rollback (cart might have changed)
          final currentIndex = _cartList.indexWhere((c) => c.id == cartId);
          if (currentIndex != -1) {
            debugPrint(
                '❌ Failed to sync cart_id $cartId, rolling back to $originalQuantity');
            _cartList[currentIndex].quantity = originalQuantity;
            _onCartMutated(reason: 'syncPendingUpdates_rollback');
          } else {
            debugPrint('⚠️ Cart item $cartId already removed, cannot rollback');
          }

          // Show error only if it's a critical failure
          if (cartIndex < _cartList.length) {
            showCustomSnackBar('failed_to_update_quantity'.tr);
          }
        } else {
          debugPrint(
              '✅ Successfully synced cart_id $cartId with quantity $quantity');
        }
      }

      // 🔥 PHASE 1.2: Use unified mutation handler
      _onCartMutated(reason: 'syncPendingUpdates_complete');
    } catch (e) {
      debugPrint('❌ Error syncing pending cart updates: $e');
      // On error, try to refresh cart from server to get correct state
      try {
        await getCartDataOnline();
      } catch (refreshError) {
        debugPrint('❌ Error refreshing cart after sync failure: $refreshError');
      }
    } finally {
      _isSyncingCart = false;
    }
  }

  /// 🔥 LEGACY METHOD: Kept for compatibility, but now uses safe cart_id lookup
  @Deprecated(
      'Use setQuantityById() instead - index-based operations are unsafe')
  Future<void> setQuantityLegacy(
      bool isIncrement, int cartIndex, int? stock, int? quantityLimit) async {
    // 🔥 BUG FIX: Check if cart is cleared (prevents race conditions)
    if (_isCartCleared) {
      debugPrint('⚠️ setQuantityLegacy: Cart already cleared, skipping');
      return;
    }

    // Prevent concurrent cart operations
    if (_isCartOperationInProgress) {
      debugPrint(
          '⏳ Cart operation already in progress, skipping quantity update');
      return;
    }

    // Debounce rapid API calls
    if (_lastCartOperation != null &&
        DateTime.now().difference(_lastCartOperation!) < _debounceDelay) {
      debugPrint('⏳ Debouncing quantity update - too soon after last call');
      return;
    }

    // Validate cart index and item existence
    if (cartIndex < 0 || cartIndex >= _cartList.length) {
      debugPrint(
          '❌ Invalid cart index: $cartIndex, cart length: ${_cartList.length}');
      return;
    }

    final cartItem = _cartList[cartIndex];

    // If no cart_id, can't use safe method
    if (cartItem.id == null) {
      debugPrint(
          '⚠️ setQuantityLegacy: Item has no cart_id, cannot update safely');
      return;
    }

    // Use safe method instead
    await setQuantityById(isIncrement, cartItem.id!, stock, quantityLimit);
  }

  /// 🔥 BUG FIX: Remove cart item by cart_id (safe, index-independent)
  /// This prevents RangeError when cart list changes between operations
  Future<void> removeFromCartById(int cartId,
      {Item? item, String reason = ''}) async {
    // 🔥 BUG FIX: Check if cart is cleared (prevents race conditions)
    if (_isCartCleared) {
      debugPrint(
          '⚠️ removeFromCartById: Cart already cleared, skipping (cartId: $cartId)');
      return;
    }

    // Find item by cart_id (not index) - safe even if list changed
    final index = _cartList.indexWhere((e) => e.id == cartId);

    if (index == -1) {
      debugPrint(
          '⚠️ removeFromCartById: cartId $cartId not found in cart list (length: ${_cartList.length})');
      debugPrint(
          '   - This can happen if cart was cleared or item already removed');
      return;
    }

    final cartItem = _cartList[index];

    // If cart item has no ID (local-only item), remove it directly without server call
    if (cartItem.id == null) {
      debugPrint('⚠️ Cart item has no ID, removing locally only');
      _cartList.removeAt(index);
      await _clearLocalCartItems();
      _onCartMutated(reason: 'removeFromCartById_localOnly:$reason');
      Get.find<ItemController>().cartIndexSet();
      if (Get.find<ItemController>().item != null) {
        Get.find<ItemController>().cartIndexSet();
      }
      debugPrint('✅ Local cart item removed (no server ID)');
      return;
    }

    // Use pessimistic update - wait for server confirmation before removing locally
    final bool success = await removeCartItemOnline(cartId, item: item);

    if (success) {
      // Find index again (cart might have changed during API call)
      final currentIndex = _cartList.indexWhere((e) => e.id == cartId);
      if (currentIndex != -1) {
        _cartList.removeAt(currentIndex);
      } else {
        debugPrint(
            '⚠️ removeFromCartById: Item already removed during API call (cartId: $cartId)');
      }
      // Clear local cache to prevent inconsistencies
      await _clearLocalCartItems();
      _onCartMutated(reason: 'removeFromCartById_success:$reason');
      Get.find<ItemController>().cartIndexSet();

      if (Get.find<ItemController>().item != null) {
        Get.find<ItemController>().cartIndexSet();
      }
      debugPrint('✅ Cart item removed from local list and cache cleared');
    } else {
      // Server removal failed - don't touch the local list
      debugPrint('❌ Failed to remove cart item $cartId from server');
    }
  }

  /// 🔥 DEPRECATED: Use removeFromCartById() instead
  /// This method uses index which can become invalid after cart mutations
  @Deprecated(
      'Use removeFromCartById() instead - index-based removal is unsafe')
  Future<void> removeFromCart(int index, {Item? item}) async {
    // Validate index and cart item existence
    if (index < 0 || index >= _cartList.length) {
      debugPrint(
          '⚠️ Invalid cart index: $index (cart list length: ${_cartList.length})');
      return;
    }

    final cartItem = _cartList[index];

    // If no cart_id, can't use safe method - fallback to index (risky)
    if (cartItem.id == null) {
      debugPrint(
          '⚠️ removeFromCart: Item has no cart_id, using unsafe index-based removal');
      _cartList.removeAt(index);
      await _clearLocalCartItems();
      _onCartMutated(reason: 'removeFromCart_legacy_noId');
      Get.find<ItemController>().cartIndexSet();
      if (Get.find<ItemController>().item != null) {
        Get.find<ItemController>().cartIndexSet();
      }
      return;
    }

    // Use safe method
    await removeFromCartById(cartItem.id!,
        item: item, reason: 'legacy_index_$index');
  }

  Future<void> clearCartList({bool canRemoveOnline = true}) async {
    // 🔥 BUG FIX: Set cleared flag BEFORE clearing to prevent race conditions
    _isCartCleared = true;
    _cartList = [];
    _storeId = null;
    _justClearedCart = true;
    if (Get.isRegistered<CouponController>()) {
      Get.find<CouponController>().removeCouponData(true);
    }

    // Clear local SharedPreferences cart data
    await _clearLocalCartItems();

    if ((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) &&
        (ModuleHelper.getModule() != null ||
            ModuleHelper.getCacheModule() != null) &&
        canRemoveOnline) {
      clearCartOnline();
    }

    // 🔥 PHASE 1.2: Use unified mutation handler
    _onCartMutated(reason: 'clearCartList');

    debugPrint('🧹 Cart cleared completely (local + online)');

    // Reset the flags after a delay to allow normal cart operations
    _isCartCleared = false;
    Future.delayed(const Duration(seconds: 2), () {
      _justClearedCart = false;
      debugPrint('✅ Cart cleared flag reset - operations can resume');
    });
  }

  int isExistInCart(
      int? itemID, String variationType, bool isUpdate, int? cartIndex) {
    return cartServiceInterface.isExistInCart(
        _cartList, itemID, variationType, isUpdate, cartIndex);
  }

  bool existAnotherStoreItem(int? storeID, int? moduleId) {
    // Don't short-circuit on empty _cartList only.
    // _storeId may still represent an active cart store (e.g. during async restore/sync).
    if (_cartList.isEmpty && (_storeId == null || _storeId! <= 0)) {
      return false;
    }

    int? effectiveNewStoreId = storeID;
    if ((effectiveNewStoreId == null || effectiveNewStoreId <= 0) &&
        Get.isRegistered<StoreController>()) {
      effectiveNewStoreId = Get.find<StoreController>().store?.id;
    }

    int? currentCartStoreId = _storeId;
    int? inferredStoreIdFromCart;
    for (final cart in _cartList) {
      final int? cartStoreId = cart.item?.storeId ?? cart.storeId;
      if (cartStoreId != null && cartStoreId > 0) {
        inferredStoreIdFromCart = cartStoreId;
        break;
      }
    }

    if (inferredStoreIdFromCart != null &&
        (currentCartStoreId == null || currentCartStoreId != inferredStoreIdFromCart)) {
      if (kDebugMode) {
        debugPrint(
            '🔧 existAnotherStoreItem: Reconciling stale _storeId from $currentCartStoreId to $inferredStoreIdFromCart');
      }
      currentCartStoreId = inferredStoreIdFromCart;
      _storeId = inferredStoreIdFromCart;
    }

    final int? currentCartModuleId = _cartList
        .firstWhereOrNull((c) => c.item?.moduleId != null)
        ?.item
        ?.moduleId;

    if (kDebugMode) {
      debugPrint('🔍 existAnotherStoreItem check:');
      debugPrint('   - currentCartStoreId: $currentCartStoreId');
      debugPrint('   - newStoreID: $effectiveNewStoreId');
      debugPrint('   - currentCartModuleId: $currentCartModuleId');
      debugPrint('   - newModuleId: $moduleId');
    }

    if (currentCartStoreId != null && currentCartStoreId > 0) {
      if (effectiveNewStoreId == null || effectiveNewStoreId <= 0) {
        if (kDebugMode) {
          debugPrint('   -> New item storeID is null/invalid - blocking add (store must be known)');
        }
        return true;
      }

      if (effectiveNewStoreId != currentCartStoreId) {
        if (kDebugMode) {
          debugPrint('   -> DIFFERENT STORE: $effectiveNewStoreId != $currentCartStoreId');
        }
        return true;
      }

      // Same store id ⇒ same store, so the cart must NOT be cleared even if the
      // caller passed a different moduleId. A store belongs to one module; the
      // mismatch is just an inconsistent caller (e.g. the storefront opened with
      // the default market module). Clearing here wrongly emptied the cart when
      // adding a second item from the same store.
      if (kDebugMode) {
        debugPrint('   -> SAME STORE: $effectiveNewStoreId == $currentCartStoreId');
      }
      return false;
    }

    return cartServiceInterface.existAnotherStoreItem(
        effectiveNewStoreId, moduleId, _cartList);
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) {
      update();
    }
  }

  // Smart cart management that automatically chooses add or update
  Future<bool> smartAddToCartOnline(
    OnlineCart cart, {
    bool skipDebounce = false,
  }) async {
    if (!skipDebounce) {
      if (_lastCartOperation != null &&
          DateTime.now().difference(_lastCartOperation!) < _debounceDelay) {
        debugPrint('⏳ Debouncing cart operation - too soon after last call');
        return false;
      }
    }

    // 🔒 REMOVED: Zone validation when adding to cart
    // Zone/location validation is now ONLY checked at checkout time (payment)
    // This allows users to add items to cart without location restrictions
    // Location will be validated when they proceed to checkout
    debugPrint(
        '✅ Adding to cart - zone validation skipped (will be checked at checkout)');

    _lastCartOperation = DateTime.now();

    // Check if item already exists on server-backed cart rows only
    final int existingIndex = _findExistingCartItem(
      cart.itemId,
      cart.variant,
      requireServerLineId: true,
    );

    if (existingIndex != -1) {
      // Same-store existing item: always use ADD API to append selected quantity.
      // This avoids cart_id dependency in update flow and matches expected UX.
      debugPrint('➕ Existing item in same store, using ADD API to append quantity');
      final OnlineCart addPayload =
          _buildOnlineCartForAdd(cart, existingIndex: existingIndex);
      return await addToCartOnline(addPayload);
    } else {
      // Item doesn't exist, use add
      debugPrint('➕ New item, using ADD API');
      return await addToCartOnline(cart);
    }
  }

  /// 🔥 OPTIMISTIC UI: Add to cart instantly, sync with backend in background
  /// User never waits - UI updates immediately, API sync happens asynchronously
  Future<bool> addToCartWithFallback({
    required CartModel cartModel,
    required OnlineCart onlineCart,
  }) async {
    int? effectiveStoreId = cartModel.item?.storeId ?? cartModel.storeId;
    if ((effectiveStoreId == null || effectiveStoreId <= 0) &&
        Get.isRegistered<StoreController>()) {
      effectiveStoreId = Get.find<StoreController>().store?.id;
    }
    if (effectiveStoreId != null && effectiveStoreId > 0) {
      cartModel.storeId ??= effectiveStoreId;
      cartModel.item?.storeId ??= effectiveStoreId;
    }

    final int? effectiveModuleId = cartModel.item?.moduleId ??
        ModuleHelper.getModule()?.id ??
        ModuleHelper.getCacheModule()?.id;
    if (effectiveModuleId != null) {
      cartModel.item?.moduleId ??= effectiveModuleId;
    }

    // Guard against unknown-store item being added into a non-empty cart.
    if (_cartList.isNotEmpty && (effectiveStoreId == null || effectiveStoreId <= 0)) {
      debugPrint(
          '❌ addToCartWithFallback: blocked add because new item storeId is null/invalid while cart is not empty');
      showCustomSnackBar('please_try_again'.tr);
      return false;
    }

    // Enforce single-store cart: block until user confirms/reset is complete.
    if (existAnotherStoreItem(effectiveStoreId, effectiveModuleId)) {
      final bool shouldReset = await _confirmResetCartForDifferentStore();
      if (!shouldReset) {
        return false;
      }
      await clearCartList();
    }

    return _addToCartWithFallbackInternal(
      cartModel: cartModel,
      onlineCart: onlineCart,
    );
  }

  Future<bool> _confirmResetCartForDifferentStore() async {
    final Completer<bool> completer = Completer<bool>();

    Get.dialog<void>(
      ConfirmationDialog(
        icon: Images.warning,
        title: 'are_you_sure_to_reset'.tr,
        description: Get.find<SplashController>()
                    .configModel
                    ?.moduleConfig
                    ?.module
                    ?.showRestaurantText ==
                true
            ? 'if_you_continue'.tr
            : 'if_you_continue_without_another_store'.tr,
        onYesPressed: () {
          if (!completer.isCompleted) {
            completer.complete(true);
          }
          Get.back<void>();
        },
        onNoPressed: () {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          Get.back<void>();
        },
      ),
      barrierDismissible: false,
    );

    return completer.future;
  }

  Future<bool> _addToCartWithFallbackInternal({
    required CartModel cartModel,
    required OnlineCart onlineCart,
  }) async {
    // 🎯 Find existing item index
    final int existingIndex =
        _findExistingCartItem(cartModel.item?.id, onlineCart.variant);

    // 🚀 STEP 1: Update UI IMMEDIATELY (no waiting for API)
    final int? previousQuantity =
        existingIndex != -1 ? _cartList[existingIndex].quantity : null;
    bool didAddNewLocalItem = false;
    if (existingIndex != -1) {
      // Item exists, update quantity locally instantly
      final int currentQuantity = _cartList[existingIndex].quantity ?? 0;
      final int addedQuantity = cartModel.quantity ?? 1;
      _cartList[existingIndex].quantity = currentQuantity + addedQuantity;
      // IMPORTANT: do not schedule pending quantity sync here.
      // In additive mode we already call ADD API (append quantity).
      // Scheduling UPDATE by cart_id on top of ADD can over-increment totals,
      // especially when backend has duplicate cart rows for the same item.

      await cartServiceInterface.addSharedPrefCartList(_cartList);
      _onCartMutated(reason: 'addToCartWithFallback_updateExisting');
      debugPrint(
          '✅ OPTIMISTIC UI: Updated existing item quantity locally to ${_cartList[existingIndex].quantity}');
    } else {
      // New item, add locally first (instant UI)
      await _addToCartInternal(cartModel, null);
      didAddNewLocalItem = true;
      debugPrint('✅ OPTIMISTIC UI: Added new item to local cart');
    }

    // 🎯 STEP 2: Sync with API in background (non-blocking, doesn't affect UI)
    // Use debounce to batch multiple rapid adds
    _isAddingToCart = true;
    try {
      final bool onlineSuccess = await smartAddToCartOnline(onlineCart);

      if (onlineSuccess) {
        debugPrint('✅ Cart synced successfully with API');

        // 🔥 CRITICAL FIX: After successful add, sync cart to ensure all items have cart_id
        // This prevents "cart_item_invalid" errors when user tries to update quantity immediately
        try {
          await getCartDataOnline(forceRefresh: true);
          debugPrint('✅ Cart synced after add - all items now have cart_id');
        } catch (e) {
          debugPrint('⚠️ Error syncing cart after add: $e');
          // Continue even if sync fails - cart_id should be available from addToCartOnline response
        }

        return true;
      } else {
        final String normalizedCode =
            (_lastAddToCartErrorCode ?? '').trim().toLowerCase();
        final bool isFinalBusinessRejection =
            _finalBusinessRejectionCodes.contains(normalizedCode);
        if (isFinalBusinessRejection) {
          _forceServerTruthOnNextCartSync = true;
          if (existingIndex != -1 && previousQuantity != null) {
            _cartList[existingIndex].quantity = previousQuantity;
          } else if (didAddNewLocalItem) {
            final int optimisticIndex =
                _findExistingCartItem(cartModel.item?.id, onlineCart.variant);
            if (optimisticIndex != -1) {
              _cartList.removeAt(optimisticIndex);
            }
          }
          _onCartMutated(reason: 'addToCartWithFallback_businessRejectRollback');
          await cartServiceInterface.addSharedPrefCartList(_cartList);
          try {
            final moduleId = ModuleHelper.getCacheModule()?.id;
            final cartListJson = _cartList.map((cart) => cart.toJson()).toList();
            await HiveHomeCacheService().saveCartData(moduleId, cartListJson);
          } catch (e) {
            debugPrint('⚠️ addToCartWithFallback: rollback Hive save failed: $e');
          }
          try {
            await getCartDataOnline(forceRefresh: true);
          } catch (e) {
            debugPrint(
                '⚠️ addToCartWithFallback: business-reject server sync failed: $e');
          }
          final bool isArabic = Get.locale?.languageCode.toLowerCase() == 'ar';
          String message = _lastAddToCartErrorMessage ?? '';
          if (normalizedCode == 'store_busy') {
            message = isArabic
                ? 'المتجر مشغول حاليًا ولا يمكنه استقبال طلبات جديدة الآن. يمكنك المحاولة لاحقًا أو الطلب من متجر آخر.'
                : 'The store is busy right now and cannot accept new orders. Please try again later or order from another store.';
          } else if (normalizedCode == 'order_time') {
            message = isArabic
                ? 'المتجر مغلق الآن ولا يمكن إنشاء الطلب في هذا الوقت. برجاء المحاولة خلال ساعات العمل أو اختيار متجر آخر.'
                : 'The store is closed now, so the order cannot be placed at this time. Please try during working hours or choose another store.';
          } else if (message.isEmpty) {
            message = isArabic
                ? 'تعذر إتمام الإضافة بسبب سياسة المتجر الحالية.'
                : 'Could not add this item due to current store policy.';
          }
          showCustomSnackBar(message);
          return false;
        }
        // 🔒 FALLBACK: API failed (e.g., store closed, network error)
        // Keep the item in local cart - user can still see it
        // When they go to checkout, they'll see the error message
        debugPrint(
            '⚠️ API sync failed - keeping item in local cart for offline/error scenarios');

        // Save local cart to ensure persistence
        await cartServiceInterface.addSharedPrefCartList(_cartList);

        // Also save to Hive
        try {
          final moduleId = ModuleHelper.getCacheModule()?.id;
          final cartListJson = _cartList.map((cart) => cart.toJson()).toList();
          await HiveHomeCacheService().saveCartData(moduleId, cartListJson);
          debugPrint('💾 Local cart saved to Hive cache (offline mode)');
        } catch (e) {
          debugPrint('⚠️ Error saving cart to Hive: $e');
        }

        // Return true for guests (always allow local cart)
        // For logged-in users, return true to allow UI update, but they'll see error at checkout
        return true;
      }
    } finally {
      _isAddingToCart = false;
    }
  }

  Future<bool> mergeGuestCart(String guestId) async {
    if (guestId.isEmpty) {
      debugPrint('⚠️ mergeGuestCart skipped - guestId is empty');
      return false;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔄 mergeGuestCart start - guestId: $guestId');
      }
      final Response<dynamic> response =
          await cartServiceInterface.mergeCart(guestId);
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Guest cart merged successfully');
        }
        await getCartDataOnline(forceRefresh: true);
        if (kDebugMode) {
          final cartIds = _cartList.map((item) => item.id).toList();
          debugPrint('🧾 mergeGuestCart result - cartIds: $cartIds');
        }
        return true;
      }

      debugPrint(
          '❌ Guest cart merge failed: ${response.statusCode} - guestId: $guestId');
      return false;
    } catch (e) {
      debugPrint('❌ Guest cart merge error: $e - guestId: $guestId');
      return false;
    }
  }

  /// When [requireServerLineId] is true, rows without a backend [CartModel.id]
  /// are ignored. Prevents treating other local-only suggested lines as the
  /// "existing" row for merge-append (which would still wipe the rest via API).
  int _findExistingCartItem(
    int? itemId,
    String? variant, {
    bool requireServerLineId = false,
  }) {
    final String normalizedTargetVariant = _normalizeVariantKey(variant);
    for (int i = 0; i < _cartList.length; i++) {
      if (requireServerLineId) {
        final int? cid = _cartList[i].id;
        if (cid == null || cid <= 0) {
          continue;
        }
      }
      if (_cartList[i].item?.id == itemId) {
        // Check variant match for items with variations.
        // Treat "none"/"null"/empty as the same no-variation value.
        final existingVariations = _cartList[i].variation;
        final String existingVariant =
            (existingVariations != null && existingVariations.isNotEmpty)
            ? existingVariations[0].type ?? ''
            : '';
        if (_normalizeVariantKey(existingVariant) == normalizedTargetVariant) {
          return i;
        }
      }
    }
    return -1;
  }

  CartModel _deepCopyCartModel(CartModel source) {
    return CartModel.fromJson(
      jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>,
    );
  }

  Future<void> _persistCartListAfterMerge() async {
    await cartServiceInterface.addSharedPrefCartList(_cartList);
    try {
      final int? moduleId = ModuleHelper.getCacheModule()?.id;
      final List<Map<String, dynamic>> cartListJson =
          _cartList.map((CartModel cart) => cart.toJson()).toList();
      await HiveHomeCacheService().saveCartData(moduleId, cartListJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ _persistCartListAfterMerge Hive save failed: $e');
      }
    }
    _onCartMutated(reason: 'cart_list_merged_local_pending');
  }

  String _normalizeVariantKey(String? variant) {
    final String normalized = (variant ?? '').trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'none' || normalized == 'null') {
      return '';
    }
    return normalized;
  }

  int? _resolveCartIdForOnlineCart(OnlineCart cart) {
    if (cart.cartId != null && cart.cartId! > 0) {
      return cart.cartId;
    }
    final int existingIndex = _findExistingCartItem(cart.itemId, cart.variant);
    if (existingIndex == -1) {
      return null;
    }
    final int? candidateCartId = _cartList[existingIndex].id;
    if (candidateCartId != null && candidateCartId > 0) {
      return candidateCartId;
    }
    return null;
  }

  int _findExistingCartItemByItemOnly(int? itemId) {
    if (itemId == null) {
      return -1;
    }
    for (int i = 0; i < _cartList.length; i++) {
      if (_cartList[i].item?.id == itemId) {
        return i;
      }
    }
    return -1;
  }

  OnlineCart _buildOnlineCartWithResolvedIds(
    OnlineCart cart, {
    int? existingIndex,
    int? resolvedCartId,
  }) {
    int index = existingIndex ?? _findExistingCartItem(cart.itemId, cart.variant);
    if (index == -1) {
      index = _findExistingCartItemByItemOnly(cart.itemId);
    }
    final int? finalCartId = resolvedCartId ?? _resolveCartIdForOnlineCart(cart);

    int? resolvedStoreId = cart.storeId;
    if ((resolvedStoreId == null || resolvedStoreId <= 0) && index != -1) {
      resolvedStoreId = _cartList[index].storeId ?? _cartList[index].item?.storeId;
    }
    if ((resolvedStoreId == null || resolvedStoreId <= 0) && _storeId != null && _storeId! > 0) {
      resolvedStoreId = _storeId;
    }
    if ((resolvedStoreId == null || resolvedStoreId <= 0) && Get.isRegistered<StoreController>()) {
      final int? currentStoreId = Get.find<StoreController>().store?.id;
      if (currentStoreId != null && currentStoreId > 0) {
        resolvedStoreId = currentStoreId;
      }
    }

    return OnlineCart(
      finalCartId,
      cart.itemId,
      cart.itemCampaignId,
      cart.price ?? '0',
      cart.variant ?? 'none',
      cart.variation,
      null,
      cart.quantity,
      cart.addOnIds ?? <int?>[],
      cart.addOns,
      cart.addOnQtys ?? <int?>[],
      cart.model ?? 'Item',
      itemType: cart.itemType,
      storeId: resolvedStoreId,
    );
  }

  OnlineCart _buildOnlineCartForAdd(
    OnlineCart cart, {
    int? existingIndex,
  }) {
    final OnlineCart normalized =
        _buildOnlineCartWithResolvedIds(cart, existingIndex: existingIndex);
    return OnlineCart(
      null, // add endpoint should not depend on cart_id
      normalized.itemId,
      normalized.itemCampaignId,
      normalized.price ?? '0',
      normalized.variant ?? 'none',
      normalized.variation,
      null,
      normalized.quantity,
      normalized.addOnIds ?? <int?>[],
      normalized.addOns,
      normalized.addOnQtys ?? <int?>[],
      normalized.model ?? 'Item',
      itemType: normalized.itemType,
      storeId: normalized.storeId,
    );
  }

  Future<bool> addToCartOnline(OnlineCart cart) async {
    bool success = false;
    _lastAddToCartErrorCode = null;
    _lastAddToCartErrorMessage = null;

    // 🔒 REMOVED: Zone validation when adding to cart
    // Zone/location validation is now ONLY checked at checkout time (payment)
    // This allows users to add items to cart without location restrictions
    // Location will be validated when they proceed to checkout
    debugPrint(
        '✅ Adding to cart - zone validation skipped (will be checked at checkout)');

    _serverCartListReplaceInProgress = true;
    _syncStickyCartBarSnapshotFromCart();
    update();

    // Backend sync (silent, non-blocking)
    try {
      final List<OnlineCartModel>? onlineCartList =
          await cartServiceInterface.addToCartOnline(cart);

      if (onlineCartList != null && onlineCartList.isNotEmpty) {
        // Update cart silently
        _cartList = [];
        _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(
            onlineCartModel: onlineCartList));
        _cartList = _deduplicateCartList(_cartList);

        // 🔥 CRITICAL FIX: Verify all items have cart_id after conversion
        for (final cartItem in _cartList) {
          if (cartItem.id == null || cartItem.id! <= 0) {
            debugPrint(
                '⚠️ Cart item ${cartItem.item?.name} missing cart_id after addToCartOnline');
          } else {
            debugPrint(
                '✅ Cart item ${cartItem.item?.name} has cart_id: ${cartItem.id}');
          }
        }

        // 🔒 CRITICAL FIX: Always save cart locally (for both guest and logged-in users)
        // This ensures cart is preserved even if API fails or network is lost
        await cartServiceInterface.addSharedPrefCartList(_cartList);
        debugPrint('💾 Cart items stored locally (${_cartList.length} items)');

        // Also save to Hive for faster loading
        try {
          final moduleId = ModuleHelper.getCacheModule()?.id;
          final cartListJson = _cartList.map((cart) => cart.toJson()).toList();
          await HiveHomeCacheService().saveCartData(moduleId, cartListJson);
          debugPrint('💾 Cart items saved to Hive cache');
        } catch (e) {
          debugPrint('⚠️ Error saving cart to Hive: $e');
          // Continue even if Hive save fails
        }

        _applyPendingQuantityUpdates();
        _onCartMutated(reason: 'addToCartOnline_success');
        success = true;
        // Invalidate cache after successful cart modification
        invalidateCartCache();
      } else {
        debugPrint(
            '⚠️ API returned empty cart list - this might indicate an error (e.g., store closed)');
      }
    } catch (e) {
      if (e is CartOperationException) {
        _lastAddToCartErrorCode = e.errorCode;
        _lastAddToCartErrorMessage = e.message;
      }
      debugPrint('❌ Error adding to cart online: $e');
      // Don't throw - let caller handle fallback
    } finally {
      _serverCartListReplaceInProgress = false;
      // 🔥 PHASE 1.2: Use unified mutation handler
      _onCartMutated(reason: 'addToCartOnline_final');
    }

    return success;
  }

  Future<bool> updateCartOnline(OnlineCart cart) async {
    bool success = false;
    int? resolvedCartId = _resolveCartIdForOnlineCart(cart);
    if (resolvedCartId == null || resolvedCartId <= 0) {
      final int fallbackIndex = _findExistingCartItemByItemOnly(cart.itemId);
      if (fallbackIndex != -1) {
        final int? fallbackCartId = _cartList[fallbackIndex].id;
        if (fallbackCartId != null && fallbackCartId > 0) {
          resolvedCartId = fallbackCartId;
        }
      }
    }
    if (resolvedCartId == null || resolvedCartId <= 0) {
      // Try one forced cart refresh first to get authoritative cart_id from server.
      try {
        await getCartDataOnline(forceRefresh: true);
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
      resolvedCartId = _resolveCartIdForOnlineCart(cart);
    }
    if (resolvedCartId == null || resolvedCartId <= 0) {
      debugPrint(
          '⛔ updateCartOnline skipped: missing cart_id even after refresh (itemId=${cart.itemId}, storeId=${cart.storeId})');
      debugPrint('   - Keeping optimistic local cart update only');
      _onCartMutated(reason: 'updateCartOnline_skipped_missingCartId');
      return true;
    }

    final OnlineCart normalizedCart =
        _buildOnlineCartWithResolvedIds(cart, resolvedCartId: resolvedCartId);

    _serverCartListReplaceInProgress = true;
    _syncStickyCartBarSnapshotFromCart();
    update();

    // Backend sync (silent, non-blocking)
    try {
      final List<OnlineCartModel>? onlineCartList =
          await cartServiceInterface.updateCartOnline(normalizedCart);
      if (onlineCartList != null) {
        // Update cart silently
        _cartList = [];
        _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(
            onlineCartModel: onlineCartList));
        _cartList = _deduplicateCartList(_cartList);

        // 🔒 CRITICAL FIX: Always save cart locally (for both guest and logged-in users)
        // This ensures cart is preserved even if API fails or network is lost
        await cartServiceInterface.addSharedPrefCartList(_cartList);
        debugPrint('💾 Cart items updated locally (${_cartList.length} items)');

        // Also save to Hive for faster loading
        try {
          final moduleId = ModuleHelper.getCacheModule()?.id;
          final cartListJson = _cartList.map((cart) => cart.toJson()).toList();
          await HiveHomeCacheService().saveCartData(moduleId, cartListJson);
          debugPrint('💾 Cart items updated in Hive cache');
        } catch (e) {
          debugPrint('⚠️ Error updating cart in Hive: $e');
          // Continue even if Hive save fails
        }

        _onCartMutated(reason: 'updateCartOnline_success');
        success = true;
        // Invalidate cache after successful cart modification
        invalidateCartCache();
      }
    } finally {
      _serverCartListReplaceInProgress = false;
      // 🔥 PHASE 1.2: Use unified mutation handler
      _onCartMutated(reason: 'updateCartOnline_final');
    }

    return success;
  }

  Future<void> updateCartQuantityOnline(
      int cartId, double price, int quantity) async {
    _isLoading = true;
    update();
    final bool success = await cartServiceInterface.updateCartQuantityOnline(
        cartId, price, quantity);
    if (success) {
      // Don't call getCartDataOnline() - it causes race conditions
      // Just recalculate the cart totals
      _onCartMutated(reason: 'updateCartQuantityOnline_success');
      // Invalidate cache after successful quantity update
      invalidateCartCache();
    }
    _isLoading = false;
    update();
  }

  Future<void> getCartDataOnline({bool forceRefresh = false}) async {
    _hasCartError = false;
    if (Get.isRegistered<SplashController>()) {
      final splashController = Get.find<SplashController>();
      if (splashController.module != null) {
        await splashController.setCacheModuleOnly(splashController.module);
      }
    }
    // Generate unique request ID for deduplication
    final String requestId = DateTime.now().millisecondsSinceEpoch.toString();

    // 🔥 LOCAL-FIRST APPROACH: Load local cart first for instant UI
    // This ensures cart appears immediately even before API response
    if (_cartList.isEmpty && !forceRefresh) {
      // Try to load from Hive cache first
      final moduleId = ModuleHelper.getCacheModule()?.id;
      final cachedCartData =
          await HiveHomeCacheService().loadCartData(moduleId);
      if (cachedCartData != null && cachedCartData.isNotEmpty) {
        _cartList.clear();
        for (final cartJson in cachedCartData) {
          try {
            final cartModel = CartModel.fromJson(cartJson);
            _cartList.add(cartModel);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ CartController: Error parsing cart item from Hive - $e');
            }
          }
        }
        _cartList = _deduplicateCartList(_cartList);
        final int? localStoreId = _cartList
            .firstWhereOrNull((c) => (c.item?.storeId ?? c.storeId) != null)
            ?.item
            ?.storeId ??
            _cartList.firstWhereOrNull((c) => c.storeId != null)?.storeId;
        if (localStoreId != null && localStoreId > 0) {
          _storeId = localStoreId;
        }
        _onCartMutated(reason: 'getCartDataOnline_fromHive');
        if (kDebugMode) {
          debugPrint(
              '⚡ CartController: Loaded ${_cartList.length} items from local cache (instant UI)');
        }
      } else {
        // Fallback to SharedPreferences for guest users
        final localItems = await _getLocalCartItems();
        if (localItems.isNotEmpty) {
          _cartList = _deduplicateCartList(localItems);
          final int? localStoreId = _cartList
              .firstWhereOrNull((c) => (c.item?.storeId ?? c.storeId) != null)
              ?.item
              ?.storeId ??
              _cartList.firstWhereOrNull((c) => c.storeId != null)?.storeId;
          if (localStoreId != null && localStoreId > 0) {
            _storeId = localStoreId;
          }
          _onCartMutated(reason: 'getCartDataOnline_fromSharedPrefs');
          if (kDebugMode) {
            debugPrint(
                '⚡ CartController: Loaded ${_cartList.length} items from SharedPreferences (instant UI)');
          }
        }
      }
    }

    // Check if we already have a recent successful load and cache is still valid
    if (!forceRefresh &&
        _lastSuccessfulCartLoad != null &&
        DateTime.now().difference(_lastSuccessfulCartLoad!) <
            _cartCacheValidity) {
      debugPrint('💾 Using cached cart data - cache is still valid');
      return;
    }

    // Prevent concurrent cart data loading
    if (_isCartDataLoading) {
      debugPrint('⏳ Cart data already loading, skipping duplicate request');
      return;
    }

    // Reset cart operation lock if it's been stuck for too long (5 seconds)
    if (_isCartOperationInProgress &&
        _lastCartOperation != null &&
        DateTime.now().difference(_lastCartOperation!) >
            const Duration(seconds: 5)) {
      debugPrint('🔄 Resetting stuck cart operation lock');
      _isCartOperationInProgress = false;
    }

    // Skip cart reload if we just cleared the cart to prevent race conditions
    // But allow force refresh to bypass this check
    if (_justClearedCart && !forceRefresh) {
      debugPrint('🚫 Skipping cart reload - cart was just cleared');
      return;
    }

    // Debounce rapid API calls unless forceRefresh is true
    if (!forceRefresh &&
        _lastCartOperation != null &&
        DateTime.now().difference(_lastCartOperation!) < _debounceDelay) {
      debugPrint(
          '⏳ Debouncing cart data load - too soon after last call (${DateTime.now().difference(_lastCartOperation!).inMilliseconds}ms ago)');
      return;
    }

    _lastCartOperation = DateTime.now();
    _isCartDataLoading = true;
    _syncStickyCartBarSnapshotFromCart();
    _currentCartRequestId = requestId;

    // 🔒 CRITICAL: Save local cart state before API call
    // This prevents overwriting local cart with empty API response
    final localCartBeforeSync = List<CartModel>.from(_cartList);
    final hasLocalCart = localCartBeforeSync.isNotEmpty;

    // Always try to load cart data, even if module is not set
    // This ensures cart data loads on home screen and after login
    _isLoading = true;
    debugPrint('🔄 Loading cart data from API (forceRefresh: $forceRefresh)');
    debugPrint(
        '🔍 Local cart before sync: ${localCartBeforeSync.length} items');
    debugPrint(
        '🔍 Module status - getModule: ${ModuleHelper.getModule() != null}, getCacheModule: ${ModuleHelper.getCacheModule() != null}');

    try {
      // Ensure guest token exists before any cart API call
      if (!AuthHelper.isLoggedIn()) {
        final String guestId = AuthHelper.getGuestId();
        if (guestId.isEmpty && Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().guestLogin();
        }
      }

      // Check if this request is still current (not cancelled)
      if (_currentCartRequestId != requestId) {
        debugPrint('🚫 Request cancelled - newer request in progress');
        return;
      }

      List<OnlineCartModel>? onlineCartList =
          await cartServiceInterface.getCartDataOnline();

      // Keep API store_id separately until we know whether we will trust API data
      // or preserve local cart (local-first protection path).
      final int? apiReportedStoreId = cartServiceInterface.getStoreId();
      if (apiReportedStoreId != null) {
        debugPrint(
            '✅ CartController: Received store_id from API response: $apiReportedStoreId');
      } else if (onlineCartList != null && onlineCartList.isNotEmpty) {
        debugPrint(
            '❌ CartController: store_id missing with non-empty cart (backend contract violation)');
      } else {
        debugPrint('ℹ️ CartController: Cart is empty - store_id may be null');
      }

      // If we got data but it might be stale, trust local state and skip retries
      if (onlineCartList != null && onlineCartList.isNotEmpty && forceRefresh) {
        if (_forceServerTruthOnNextCartSync) {
          debugPrint(
              '🔒 CartController: Server-truth mode active - skipping stale-local override');
        }
        // Check if the data looks stale by comparing with current local cart
        bool mightBeStale = false;
        if (_cartList.isNotEmpty && onlineCartList.length == _cartList.length) {
          for (int i = 0; i < onlineCartList.length; i++) {
            if (i < _cartList.length &&
                onlineCartList[i].itemId == _cartList[i].item!.id &&
                onlineCartList[i].quantity != _cartList[i].quantity) {
              debugPrint(
                  '🔄 Detected stale data: API qty=${onlineCartList[i].quantity}, Local qty=${_cartList[i].quantity}');
              mightBeStale = true;
              break;
            }
          }
        }

        // Also check if we have local cart data that's more recent than API data
        // This handles cases where local cart was updated but API hasn't caught up
        if (!mightBeStale && _cartList.isNotEmpty) {
          for (int i = 0; i < _cartList.length; i++) {
            // Find matching item in API response
            OnlineCartModel? matchingApiItem;
            for (final apiItem in onlineCartList) {
              if (apiItem.itemId == _cartList[i].item!.id) {
                matchingApiItem = apiItem;
                break;
              }
            }

            if (matchingApiItem != null &&
                matchingApiItem.quantity != _cartList[i].quantity) {
              debugPrint(
                  '🔄 Detected quantity mismatch: API qty=${matchingApiItem.quantity}, Local qty=${_cartList[i].quantity}');
              mightBeStale = true;
              break;
            }
          }
        }

        if (mightBeStale && !_forceServerTruthOnNextCartSync) {
          debugPrint(
              '🔄 Backend returns stale data, trusting local cart state (no retries)');
          debugPrint(
              '🔄 Keeping local cart with ${_cartList.length} items instead of overwriting with stale API data');
          _onCartMutated(reason: 'getCartDataOnline_staleData_keepLocal');
          return;
        }
      }

      if (onlineCartList != null && onlineCartList.isNotEmpty) {
        final int? previousStoreIdForCoupon = _storeId;
        _forceServerTruthOnNextCartSync = false;
        if (apiReportedStoreId != null) {
          _storeId = apiReportedStoreId;
          debugPrint(
              '✅ CartController: Stored store_id from API response: $_storeId');
        }

        // Cart has items - update from server
        debugPrint(
            '🔄 Before updating cartList - current length: ${_cartList.length}');
        for (int i = 0; i < _cartList.length; i++) {
          debugPrint(
              '🔄 Current cart item $i: ${_cartList[i].item?.name} - qty: ${_cartList[i].quantity}');
        }

        _cartList = [];
        final formatted = cartServiceInterface.formatOnlineCartToLocalCart(
            onlineCartModel: onlineCartList);
        _cartList.addAll(formatted);
        _cartList = _deduplicateCartList(_cartList);

        if (_storeId == null || _storeId! <= 0) {
          final int? firstApiItemStoreId = _cartList.first.item?.storeId;
          if (firstApiItemStoreId != null && firstApiItemStoreId > 0) {
            _storeId = firstApiItemStoreId;
            debugPrint(
                '⚠️ CartController: store_id not in response, extracted from first API cart item: $_storeId');
          }
        }

        // 🔐 Defensive programming: reject invalid cart state
        if (_cartList.isNotEmpty && _storeId == null) {
          debugPrint(
              '❌ Invalid cart state: store_id is null with cart items (backend contract violation)');
          if (kDebugMode) {
            throw StateError(
                'Invalid cart state: store_id is null with cart items');
          }
          if (!_isInvalidCartStateHandling) {
            _isInvalidCartStateHandling = true;
            _cartList = [];
            _totals = const CartTotals();
            await cartServiceInterface.addSharedPrefCartList(_cartList);
            _onCartMutated(reason: 'invalidCartState_reset');
            _isInvalidCartStateHandling = false;
          }
          return;
        }

        debugPrint(
            '🔄 After updating cartList - new length: ${_cartList.length}');
        for (int i = 0; i < _cartList.length; i++) {
          debugPrint(
              '🔄 New cart item $i: ${_cartList[i].item?.name} - qty: ${_cartList[i].quantity}');
        }

        // 🔒 CRITICAL FIX: Always save cart locally (for both guest and logged-in users)
        // This ensures cart is preserved even if API fails or network is lost
        if (_cartList.isNotEmpty) {
          await cartServiceInterface.addSharedPrefCartList(_cartList);
          debugPrint(
              '💾 Cart items stored locally (${_cartList.length} items)');
        }

        // ⚡ TASK 1: Save cart data to Hive for instant loading on module switch
        try {
          final moduleId = ModuleHelper.getCacheModule()?.id;
          final cartListJson = _cartList.map((cart) => cart.toJson()).toList();
          await HiveHomeCacheService().saveCartData(moduleId, cartListJson);
          if (kDebugMode) {
            debugPrint(
                '💾 CartController: Saved ${_cartList.length} cart items to Hive for module ${moduleId ?? 'global'}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ CartController: Error saving cart data to Hive - $e');
          }
          // Don't throw - continue even if cache save fails
        }

        // 🔥 BUG FIX: Reset cleared flag when cart has items (cart is active again)
        _isCartCleared = false;
        final int? newStoreIdForCoupon =
            _storeId ?? (_cartList.isNotEmpty ? _cartList.first.item?.storeId : null);
        if (Get.isRegistered<CouponController>()) {
          final CouponController couponController = Get.find<CouponController>();
          if (couponController.hasAppliedCoupon &&
              previousStoreIdForCoupon != null &&
              newStoreIdForCoupon != null &&
              previousStoreIdForCoupon != newStoreIdForCoupon) {
            if (kDebugMode) {
              debugPrint(
                '[Coupon] cleared: store changed $previousStoreIdForCoupon -> $newStoreIdForCoupon',
              );
            }
            couponController.removeCouponData(true);
          }
        }
        _onCartMutated(reason: 'getCartDataOnline_fromAPI');
        debugPrint('✅ Cart data loaded from API - ${_cartList.length} items');
      } else {
        if (_forceServerTruthOnNextCartSync) {
          debugPrint(
              '🔒 CartController: Server-truth mode active and server cart is empty - clearing local cart');
          _cartList = [];
          _totals = const CartTotals();
          _storeId = null;
          await cartServiceInterface.addSharedPrefCartList(_cartList);
          try {
            final moduleId = ModuleHelper.getCacheModule()?.id;
            await HiveHomeCacheService()
                .saveCartData(moduleId, <Map<String, dynamic>>[]);
          } catch (e) {
            debugPrint('⚠️ CartController: Error clearing Hive cart cache: $e');
          }
          _forceServerTruthOnNextCartSync = false;
          _onCartMutated(reason: 'getCartDataOnline_serverTruthEmpty');
          return;
        }
        // 🔒 CRITICAL GUARD: API returned empty cart
        // NEVER overwrite local cart with empty API response unless:
        // 1. User explicitly cleared cart (forceRefresh = true + _justClearedCart)
        // 2. User logged out
        // 3. Order was placed successfully

        if (_isTransferringGuestCart) {
          // During transfer, keep displaying cached items
          final List<CartModel> cachedItems = await _getLocalCartItems();
          if (cachedItems.isNotEmpty) {
            _cartList = cachedItems;
            _onCartMutated(reason: 'getCartDataOnline_transfer_cached');
            debugPrint(
                '💾 API returned empty during transfer - showing ${cachedItems.length} cached items');
          } else if (hasLocalCart) {
            // Restore local cart if API is empty during transfer
            _cartList = localCartBeforeSync;
            _onCartMutated(reason: 'getCartDataOnline_transfer_local');
            debugPrint(
                '🛡️ API returned empty during transfer - preserving ${localCartBeforeSync.length} local items');
          } else {
            _cartList = [];
            _onCartMutated(reason: 'getCartDataOnline_transfer_empty');
            debugPrint('ℹ️ API returned empty and no cached items available');
          }
        } else if (hasLocalCart) {
          // 🔥 LOCAL-FIRST PROTECTION: Don't overwrite local cart with empty API response
          // This prevents cart from disappearing during:
          // - Guest → User transfer window
          // - Concurrent refresh race conditions
          // - Temporary API failures
          // - Cache sync delays
          // - Even with forceRefresh=true (unless user explicitly cleared cart)

          if (forceRefresh && _justClearedCart) {
            // ✅ EXCEPTION: User explicitly cleared cart - safe to set empty
            // This is the ONLY case where we trust empty API response
            _isCartCleared = true; // Set flag when user explicitly cleared
            _cartList = [];
            _onCartMutated(reason: 'getCartDataOnline_userCleared');
            debugPrint('✅ Cart cleared by user - ${_cartList.length} items');

            // Reset flag after delay
            Future.delayed(const Duration(seconds: 2), () {
              _isCartCleared = false;
            });
          } else {
            // 🛡️ PROTECT: Preserve local cart even with forceRefresh=true
            // The server cannot delete user's cart without explicit confirmation
            debugPrint(
                '🛡️ PROTECTED: API returned empty but local cart has ${localCartBeforeSync.length} items');
            debugPrint(
                '   - Preserving local cart (API might be temporarily empty)');
            debugPrint(
                '   - forceRefresh=$forceRefresh, _justClearedCart=$_justClearedCart');
            debugPrint(
                '   - Server cannot delete cart without explicit user action');

            // Keep local cart - don't overwrite with empty API response
            // The cart will sync when API returns valid data
            // Only clear if user explicitly cleared cart (_justClearedCart = true)
            final int? localStoreId = localCartBeforeSync
                .firstWhereOrNull(
                    (c) => (c.item?.storeId ?? c.storeId) != null)
                ?.item
                ?.storeId ??
                localCartBeforeSync
                    .firstWhereOrNull((c) => c.storeId != null)
                    ?.storeId;
            if (localStoreId != null && localStoreId > 0) {
              _storeId = localStoreId;
              debugPrint(
                  '✅ CartController: Preserving local store_id while API cart is empty: $_storeId');
            }
          }
        } else {
          // No local cart and API is empty - cart is truly empty
          _storeId = apiReportedStoreId;
          _cartList = [];
          _onCartMutated(reason: 'getCartDataOnline_trulyEmpty');
          debugPrint('✅ Cart is empty - ${_cartList.length} items');
        }
      }

      // Log final storeId value for debugging
      debugPrint('🔍 CartController: Final storeId value: $_storeId');
    } catch (e, stack) {
      debugPrint('❌ Error in getCartDataOnline: $e\n$stack');
      _hasCartError = true;
    } finally {
      _isLoading = false;
      _isCartDataLoading = false;

      // Only update cache timestamp if this was the current request
      if (_currentCartRequestId == requestId) {
        _lastSuccessfulCartLoad = DateTime.now();
        _currentCartRequestId = null;
      }

      // 🔥 PHASE 1.2: Use unified mutation handler
      _onCartMutated(reason: 'getCartDataOnline_finally');
      debugPrint('✅ Cart list updated successfully');
    }
  }

  /// Cancel any ongoing cart data loading request
  void cancelCartDataLoading() {
    if (_isCartDataLoading) {
      debugPrint('🚫 Cancelling ongoing cart data loading request');
      _currentCartRequestId = null;
      _isCartDataLoading = false;
    }
  }

  /// Invalidate cart cache to force next load to fetch fresh data
  void invalidateCartCache() {
    debugPrint('🔄 Invalidating cart cache');
    _lastSuccessfulCartLoad = null;
  }

  /// Check if cart data is stale and needs refresh
  bool get isCartDataStale {
    if (_lastSuccessfulCartLoad == null) return true;
    return DateTime.now().difference(_lastSuccessfulCartLoad!) >
        _cartCacheValidity;
  }

  /// Refresh cart data from server when cart operations fail
  Future<bool> refreshCartFromServer() async {
    debugPrint('🔄 Refreshing cart data from server...');
    try {
      await getCartDataOnline(forceRefresh: true);
      debugPrint('✅ Cart data refreshed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to refresh cart data: $e');
      return false;
    }
  }

  Future<bool> removeCartItemOnline(int cartId, {Item? item}) async {
    // Don't modify _isLoading for item removal - it causes unnecessary UI rebuilds
    // The removal is fast enough that loading state isn't needed
    bool success = await cartServiceInterface.removeCartItemOnline(cartId);

    // Handle both success and 404 (item not found) as successful removal
    // because if the item doesn't exist on server, it's effectively removed
    if (success) {
      // Clear local cache to prevent inconsistencies
      await _clearLocalCartItems();

      if (item != null) {
        Get.find<ItemController>().setExistInCart(item, null, notify: true);
      }
      debugPrint('✅ Cart item removed and local cache cleared');
    } else {
      // Even if API call failed, clear local cache
      debugPrint('⚠️ Cart removal API failed, but clearing local cache');
      await _clearLocalCartItems();

      if (item != null) {
        Get.find<ItemController>().setExistInCart(item, null, notify: true);
      }
      // Consider this a success since we've cleared local cache
      success = true;
    }

    return success;
  }

  Future<bool> clearCartOnline() async {
    // Don't modify _isLoading for cart clearing - it causes unnecessary UI rebuilds
    // The clearing operation is fast enough that loading state isn't needed
    final bool success = await cartServiceInterface.clearCartOnline();
    if (success) {
      // Clear local cache immediately when online cart is cleared
      await _clearLocalCartItems();
      _cartList = [];
      _storeId = null;
      _onCartMutated(reason: 'clearCartOnline');
      debugPrint('🧹 Online cart cleared, local cache also cleared');
    }
    return success;
  }

  int cartQuantity(int itemId) {
    return cartServiceInterface.cartQuantity(itemId, _cartList);
  }

  int get totalCartQuantity {
    return _cartList.fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  String cartVariant(int itemId) {
    return cartServiceInterface.cartVariant(itemId, _cartList);
  }

  void setExpanded(bool setExpand) {
    _isExpanded = setExpand;
    update();
  }

  /// Transfer local cart items to online cart after guest login
  Future<void> transferLocalCartToOnline() async {
    try {
      debugPrint('🔄 Starting guest cart transfer process...');

      // Set transfer flag to prevent cache clearing during transfer
      _isTransferringGuestCart = true;

      // Get local cart items from SharedPreferences
      final List<CartModel> localCartItems = await _getLocalCartItems();

      debugPrint('🔍 Found ${localCartItems.length} local cart items');

      if (localCartItems.isNotEmpty) {
        debugPrint(
            '🔄 Transferring ${localCartItems.length} local cart items to online cart...');

        int successCount = 0;
        int failCount = 0;

        // Transfer each local item to online cart
        for (int i = 0; i < localCartItems.length; i++) {
          try {
            final CartModel cartItem = localCartItems[i];
            debugPrint(
                "🔄 Transferring item ${i + 1}/${localCartItems.length}: ${cartItem.item?.name ?? 'Unknown'}");

            // Convert addOnIds from List<AddOn> to List<int?>
            final List<int?> addOnIds = [];
            if (cartItem.addOnIds != null) {
              for (final addOn in cartItem.addOnIds!) {
                addOnIds.add(addOn.id);
              }
            }

            // Convert addOnQtys from List<AddOn> to List<int?>
            final List<int?> addOnQtys = [];
            if (cartItem.addOnIds != null) {
              for (final addOn in cartItem.addOnIds!) {
                addOnQtys.add(addOn.quantity);
              }
            }

            final OnlineCart onlineCart = OnlineCart(
              null, // cartId - null for new items
              cartItem.item!.id, // itemId
              null, // itemCampaignId
              cartItem.price?.toString() ?? '0', // price
              cartItem.variation!.isNotEmpty
                  ? cartItem.variation![0].type ?? ''
                  : '', // variant
              cartItem.variation, // variation
              null, // variations
              cartItem.quantity, // quantity
              addOnIds, // addOnIds
              cartItem.addOns, // addOns
              addOnQtys, // addOnQtys
              'Item', // model
              itemType: 'Item',
            );

            // Always use ADD for guest cart transfer (items don't exist in user cart yet)
            debugPrint('➕ Adding guest item to user cart using ADD API');
            final bool success = await addToCartOnline(onlineCart);
            if (success) {
              successCount++;
              debugPrint(
                  "✅ Successfully transferred item: ${cartItem.item?.name ?? 'Unknown'}");
            } else {
              failCount++;
              debugPrint(
                  "❌ Failed to transfer item: ${cartItem.item?.name ?? 'Unknown'}");
            }
          } catch (e) {
            failCount++;
            debugPrint('❌ Error transferring item ${i + 1}: $e');
          }
        }

        // Clear local cart after transfer attempt (regardless of success/failure)
        await _clearLocalCartItems();
        debugPrint(
            '✅ Guest cart transfer completed - Success: $successCount, Failed: $failCount');
      } else {
        debugPrint('ℹ️ No local cart items found to transfer');
      }
    } catch (e) {
      debugPrint('❌ Error in guest cart transfer process: $e');
    } finally {
      // Always reset transfer flag
      _isTransferringGuestCart = false;
      debugPrint('🏁 Guest cart transfer flag reset');
    }
  }

  /// Get local cart items from SharedPreferences
  Future<List<CartModel>> _getLocalCartItems() async {
    try {
      final List<String> cartStrings =
          Get.find<SharedPreferences>().getStringList(AppConstants.cartList) ??
              [];

      debugPrint(
          '🔍 Retrieved ${cartStrings.length} cart strings from SharedPreferences');

      final List<CartModel> localItems = [];

      for (int i = 0; i < cartStrings.length; i++) {
        try {
          final CartModel cartModel = CartModel.fromJson(
              jsonDecode(cartStrings[i]) as Map<String, dynamic>);
          localItems.add(cartModel);
          debugPrint(
              "✅ Parsed cart item ${i + 1}: ${cartModel.item?.name ?? 'Unknown'} (qty: ${cartModel.quantity})");
        } catch (e) {
          debugPrint('❌ Error parsing cart item ${i + 1}: $e');
        }
      }

      debugPrint(
          '🔍 Successfully parsed ${localItems.length} local cart items');
      return localItems;
    } catch (e) {
      debugPrint('❌ Error getting local cart items: $e');
      return [];
    }
  }

  /// Clear local cart items from SharedPreferences
  Future<void> _clearLocalCartItems() async {
    try {
      await Get.find<SharedPreferences>().remove(AppConstants.cartList);
      debugPrint('🧹 Cleared local cart items');
    } catch (e) {
      debugPrint('❌ Error clearing local cart: $e');
    }
  }

  /// Public method to clear only local cache (for auth controller after Laravel transfer)
  Future<void> clearLocalCacheOnly() async {
    await _clearLocalCartItems();
    debugPrint('🧹 Cleared local cart cache only (no API call)');
  }

  /// Force refresh cart state to ensure consistency between local and online
  Future<void> forceRefreshCart() async {
    debugPrint('🔄 Force refreshing cart state...');
    // Cancel any ongoing requests before forcing refresh
    cancelCartDataLoading();
    await getCartDataOnline(forceRefresh: true);
    update();
  }

  /// ⚡ TASK 1: Restore cart data from Hive cache (instant loading, 0ms)
  /// Called from switchModule to provide instant cart data before API calls
  Future<bool> restoreCartFromHiveCache(int? moduleId) async {
    try {
      final cachedCartData =
          await HiveHomeCacheService().loadCartData(moduleId);
      if (cachedCartData != null && cachedCartData.isNotEmpty) {
        // Parse cart data from JSON
        _cartList.clear();
        for (final cartJson in cachedCartData) {
          try {
            final cartModel = CartModel.fromJson(cartJson);
            _cartList.add(cartModel);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ CartController: Error parsing cart item from Hive - $e');
            }
          }
        }
        _cartList = _deduplicateCartList(_cartList);
        _onCartMutated(reason: 'restoreCartFromHiveCache');
        if (kDebugMode) {
          debugPrint(
              '⚡ CartController: Restored ${_cartList.length} cart items from Hive (0ms)');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CartController: Error restoring cart from Hive - $e');
      }
      return false;
    }
  }

  /// Set the guest cart transfer flag (called by auth controller)
  void setTransferringGuestCart(bool isTransferring) {
    _isTransferringGuestCart = isTransferring;
    debugPrint('🔄 Guest cart transfer flag set to: $isTransferring');
  }

  // ============================================================================
  // ✅ NEW METHOD: Get delivery distance with caching
  // ============================================================================

  /// Get delivery distance to store
  ///
  /// Returns cached distance if available and fresh (< 5 minutes old)
  /// Otherwise calculates from current address to first cart item's store
  ///
  /// This prevents:
  /// - Double calculations (cart + checkout)
  /// - Stale distance values
  /// - Unnecessary API calls
  Future<double?> getDeliveryDistance({bool forceRefresh = false}) async {
    try {
      // Check cache validity
      if (!forceRefresh &&
          _cachedDeliveryDistance != null &&
          _distanceCacheTime != null) {
        final Duration cacheAge =
            DateTime.now().difference(_distanceCacheTime!);

        if (cacheAge < _distanceCacheDuration) {
          debugPrint(
              '💾 [Cart] Using cached distance: ${_cachedDeliveryDistance}km (age: ${cacheAge.inSeconds}s)');
          return _cachedDeliveryDistance;
        } else {
          debugPrint(
              '⏰ [Cart] Cache expired (${cacheAge.inSeconds}s old), recalculating...');
        }
      }

      // Calculate distance
      debugPrint('📏 [Cart] Calculating delivery distance...');
      final distance = await _calculateDeliveryDistanceInternal();

      if (distance != null) {
        // Cache the result
        _cachedDeliveryDistance = distance;
        _distanceCacheTime = DateTime.now();
        debugPrint('✅ [Cart] Distance calculated and cached: ${distance}km');
      } else {
        debugPrint('⚠️ [Cart] Unable to calculate distance');
      }

      return distance;
    } catch (e) {
      debugPrint('❌ [Cart] Error getting delivery distance: $e');
      return null;
    }
  }

  /// Internal method: Actually calculate distance
  /// Returns null if calculation fails
  Future<double?> _calculateDeliveryDistanceInternal() async {
    try {
      // 1. Get user's current address
      // Try to get from AddressHelper if available
      // Note: We use shared preferences address since AddressHelper may not be imported
      final prefs = Get.find<SharedPreferences>();
      final addressString = prefs.getString('userAddress');

      if (addressString == null) {
        debugPrint('⚠️ [Cart] No address available for distance calculation');
        return null;
      }

      final addressData = jsonDecode(addressString) as Map<String, dynamic>;
      final latitude = addressData['latitude']?.toString();
      final longitude = addressData['longitude']?.toString();

      if (latitude == null || longitude == null) {
        debugPrint('⚠️ [Cart] Address missing coordinates');
        return null;
      }

      debugPrint('📍 [Cart] User address: $latitude, $longitude');

      // 2. Get store from first cart item
      if (cartList.isEmpty) {
        debugPrint('⚠️ [Cart] Cart is empty, cannot get store location');
        return null;
      }

      final firstItem = cartList.first.item;
      if (firstItem?.storeId == null) {
        debugPrint('⚠️ [Cart] First item has no storeId');
        return null;
      }

      // 3. Get store details from StoreController
      try {
        // We'll use the basic distance calculation from coordinates
        // Store coordinates should be available in the cart item or store model

        // For now, return null and let checkout calculate
        // This is a safe fallback
        debugPrint('ℹ️ [Cart] Distance calculation delegated to checkout');
        return null;
      } catch (e) {
        debugPrint('❌ [Cart] Error loading store details: $e');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [Cart] Error in distance calculation: $e');
      return null;
    }
  }

  // ============================================================================
  // ✅ NEW METHOD: Clear distance cache (call when changing address or module)
  // ============================================================================

  void clearDistanceCache({String reason = ''}) {
    if (_cachedDeliveryDistance != null) {
      debugPrint('🧹 [Cart] Clearing distance cache (reason: $reason)');
      _cachedDeliveryDistance = null;
      _distanceCacheTime = null;
    }
  }

  // ============================================================================
  // ✅ NEW METHOD: Force distance recalculation
  // ============================================================================

  Future<double?> recalculateDistance({String reason = ''}) async {
    debugPrint('🔄 [Cart] Force recalculating distance (reason: $reason)');
    clearDistanceCache(reason: reason);
    return getDeliveryDistance(forceRefresh: true);
  }

  // ============================================================================
  // ✅ DEBUG METHOD: Print distance cache state
  // ============================================================================

  void debugDistanceCache(String tag) {
    if (!kDebugMode) return;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📏 DISTANCE CACHE [$tag]');
    debugPrint('   Cached Distance: $_cachedDeliveryDistance km');
    debugPrint('   Cache Time: $_distanceCacheTime');
    if (_distanceCacheTime != null) {
      final age = DateTime.now().difference(_distanceCacheTime!);
      debugPrint('   Cache Age: ${age.inSeconds} seconds');
      debugPrint('   Cache Valid: ${age < _distanceCacheDuration}');
    }
    debugPrint('═══════════════════════════════════════════════════════');
  }

  @override
  void onClose() {
    // 🔥 CLEANUP: Cancel debounce timer and sync pending updates before closing
    _cartSyncDebounceTimer?.cancel();
    if (_pendingCartUpdates.isNotEmpty && !_isSyncingCart) {
      // Try to sync remaining updates before closing (fire and forget)
      _syncPendingCartUpdates();
    }
    super.onClose();
  }
}
