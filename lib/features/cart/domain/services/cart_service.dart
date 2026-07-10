import 'package:flutter/foundation.dart';
import 'package:get/get_connect.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart'
    as online_cart;
import 'package:sixam_mart/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:sixam_mart/features/cart/domain/services/cart_service_interface.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart'
    as item_variation;
import 'package:sixam_mart/util/app_constants.dart';

class CartService implements CartServiceInterface {
  final CartRepositoryInterface cartRepositoryInterface;
  CartService({required this.cartRepositoryInterface});

  @override
  Future<List<online_cart.OnlineCartModel>?> addToCartOnline(
      OnlineCart cart) async {
    final result = await cartRepositoryInterface.add(cart);
    return result is List<online_cart.OnlineCartModel>? ? result : null;
  }

  @override
  Future<Response<dynamic>> mergeCart(String guestId) async {
    return await cartRepositoryInterface.mergeCart(guestId);
  }

  @override
  Future<List<online_cart.OnlineCartModel>?> updateCartOnline(
      OnlineCart cart) async {
    final result = await cartRepositoryInterface.update(cart.toJson(), null);
    return result is List<online_cart.OnlineCartModel>? ? result : null;
  }

  @override
  Future<bool> updateCartQuantityOnline(
      int cartId, double price, int quantity) async {
    final result = await cartRepositoryInterface.update({}, cartId,
        price: price, quantity: quantity, isUpdateQty: true);
    return result is bool ? result : false;
  }

  @override
  Future<List<online_cart.OnlineCartModel>?> getCartDataOnline() async {
    final result = await cartRepositoryInterface.getList();
    return result is List<online_cart.OnlineCartModel>? ? result : null;
  }

  @override
  int? getStoreId() {
    return cartRepositoryInterface.getStoreId();
  }

  @override
  Future<bool> removeCartItemOnline(int cartId) async {
    return await cartRepositoryInterface.delete(cartId);
  }

  @override
  Future<bool> clearCartOnline() async {
    return await cartRepositoryInterface.delete(null, isRemoveAll: true);
  }

  @override
  int availableSelectedIndex(int selectedIndex, int index) {
    int notAvailableIndex = selectedIndex;
    if (notAvailableIndex == index) {
      notAvailableIndex = -1;
    } else {
      notAvailableIndex = index;
    }
    return notAvailableIndex;
  }

  @override
  ModuleModel? forcefullySetModule(ModuleModel? selectedModule,
      List<ModuleModel>? moduleList, int moduleId) {
    ModuleModel? module;
    if (selectedModule == null && moduleList != null) {
      for (final ModuleModel m in moduleList) {
        if (m.id == moduleId) {
          module = m;
          break;
        }
      }
    }
    return module;
  }

  @override
  List<AddOns> prepareAddonList(CartModel cartModel) {
    final List<AddOns> addOnList = [];
    for (final addOnId in cartModel.addOnIds!) {
      for (final AddOns addOns in cartModel.item!.addOns!) {
        if (addOns.id == addOnId.id) {
          addOnList.add(addOns);
          break;
        }
      }
    }
    return addOnList;
  }

  @override
  double calculateAddonPrice(
      double addOns, List<AddOns> addOnList, CartModel cartModel) {
    double addonPrice = addOns;
    for (int index = 0; index < addOnList.length; index++) {
      addonPrice = addonPrice +
          (addOnList[index].price! * cartModel.addOnIds![index].quantity!);
    }
    return addonPrice;
  }

  @override
  double calculateVariationPrice(bool isFoodVariation, CartModel cartModel,
      double? discount, String? discountType, double variationPrice) {
    double price = variationPrice;
    if (cartModel.item == null) {
      return price;
    }
    if (isFoodVariation) {
      if (cartModel.item!.foodVariations == null ||
          cartModel.item!.foodVariations!.isEmpty ||
          cartModel.foodVariations == null) {
        return price;
      }
      for (int index = 0;
          index < cartModel.item!.foodVariations!.length;
          index++) {
        if (index >= cartModel.foodVariations!.length) {
          break;
        }
        for (int i = 0;
            i < cartModel.item!.foodVariations![index].variationValues!.length;
            i++) {
          if (i < cartModel.foodVariations![index].length &&
              cartModel.foodVariations![index][i] == true) {
            price += (PriceConverter.convertWithDiscount(
                    cartModel.item!.foodVariations![index].variationValues![i]
                        .optionPrice!,
                    discount,
                    discountType,
                    isFoodVariation: true)! *
                (cartModel.quantity ?? 0));
          }
        }
      }
    } else {
      if (cartModel.variation == null ||
          cartModel.variation!.isEmpty ||
          cartModel.item!.variations == null ||
          cartModel.item!.variations!.isEmpty) {
        return price;
      }
      String variationType = '';
      for (int i = 0; i < cartModel.variation!.length; i++) {
        variationType = cartModel.variation![i].type!;
      }

      for (final item_variation.Variation variation
          in cartModel.item!.variations!) {
        if (variation.type == variationType) {
          price = (PriceConverter.convertWithDiscount(
                  variation.price!, discount, discountType)! *
              (cartModel.quantity ?? 0));
          break;
        }
      }
    }
    return price;
  }

  @override
  double calculateVariationWithoutDiscountPrice(bool isFoodVariation,
      CartModel cartModel, double variationWithoutDiscount) {
    double variationWithoutDiscountPrice = variationWithoutDiscount;
    if (cartModel.item == null) {
      return variationWithoutDiscountPrice;
    }
    if (!isFoodVariation) {
      if (cartModel.variation == null ||
          cartModel.variation!.isEmpty ||
          cartModel.item!.variations == null ||
          cartModel.item!.variations!.isEmpty) {
        return variationWithoutDiscountPrice;
      }
      String variationType = '';
      for (int i = 0; i < cartModel.variation!.length; i++) {
        variationType = cartModel.variation![i].type!;
      }
      for (final item_variation.Variation variation
          in cartModel.item!.variations!) {
        if (variation.type == variationType) {
          variationWithoutDiscountPrice =
              (variation.price! * (cartModel.quantity ?? 0));
          break;
        }
      }
    } else {
      if (cartModel.item!.foodVariations == null ||
          cartModel.item!.foodVariations!.isEmpty ||
          cartModel.foodVariations == null) {
        return variationWithoutDiscountPrice;
      }
      for (int index = 0;
          index < cartModel.item!.foodVariations!.length;
          index++) {
        if (index >= cartModel.foodVariations!.length) {
          break;
        }
        for (int i = 0;
            i < cartModel.item!.foodVariations![index].variationValues!.length;
            i++) {
          if (i < cartModel.foodVariations![index].length &&
              cartModel.foodVariations![index][i] == true) {
            variationWithoutDiscountPrice += (cartModel.item!
                    .foodVariations![index].variationValues![i].optionPrice! *
                (cartModel.quantity ?? 0));
          }
        }
      }
    }
    return variationWithoutDiscountPrice;
  }

  @override
  bool checkVariation(bool isFoodVariation, CartModel cartModel) {
    bool haveVariation = false;
    if (cartModel.item == null) {
      return false;
    }
    if (!isFoodVariation) {
      if (cartModel.variation == null ||
          cartModel.variation!.isEmpty ||
          cartModel.item!.variations == null ||
          cartModel.item!.variations!.isEmpty) {
        return false;
      }
      String variationType = '';
      for (int i = 0; i < cartModel.variation!.length; i++) {
        variationType = cartModel.variation![i].type ?? '';
      }
      for (final item_variation.Variation variation
          in cartModel.item!.variations!) {
        if (variation.type == variationType) {
          haveVariation = true;
          break;
        }
      }
    }
    return haveVariation;
  }

  @override
  Future<void> addSharedPrefCartList(List<CartModel> cartProductList) async {
    await cartRepositoryInterface.addSharedPrefCartList(cartProductList);
  }

  @override
  int? getCartId(int cartIndex, List<CartModel> cartList) {
    // 🔥 BUG FIX: Guard all list access to prevent RangeError
    if (cartIndex == -1 || cartList.isEmpty) {
      return null;
    }

    // 🔥 BUG FIX: Validate index is within bounds
    if (cartIndex < 0 || cartIndex >= cartList.length) {
      debugPrint(
          '⚠️ getCartId: Invalid cartIndex $cartIndex (cartList length: ${cartList.length})');
      return null;
    }

    return cartList[cartIndex].id;
  }

  /// 🔥 BUG FIX: Get cart_id by itemId (safe, index-independent)
  /// This prevents RangeError when searching for items in cart
  @override
  int? getCartIdByItemId(int itemId, List<CartModel> cartList) {
    try {
      // 🔥 BUG FIX: Use firstWhere with orElse instead of where().toList()[0]
      final match = cartList.firstWhere(
        (c) => c.item?.id == itemId,
        orElse: () => CartModel(), // Return empty CartModel if not found
      );

      // Check if match was found (empty CartModel means not found)
      if (match.item == null) {
        debugPrint(
            '⚠️ getCartIdByItemId: itemId $itemId not found in cart (cartList length: ${cartList.length})');
        return null;
      }

      return match.id;
    } catch (e) {
      debugPrint('❌ getCartIdByItemId crashed for itemId=$itemId: $e');
      return null;
    }
  }

  @override
  Future<int> decideItemQuantity(bool isIncrement, List<CartModel> cartList,
      int cartIndex, int? stock, int? quantityLimit, bool moduleStock) async {
    // 🔥 BUG FIX: Guard cartIndex access to prevent RangeError
    if (cartIndex < 0 || cartIndex >= cartList.length) {
      debugPrint(
          '⚠️ decideItemQuantity: Invalid cartIndex $cartIndex (cartList length: ${cartList.length})');
      throw RangeError('Invalid cartIndex: $cartIndex');
    }

    int quantity = cartList[cartIndex].quantity!;
    if (isIncrement) {
      if (moduleStock && cartList[cartIndex].quantity! >= stock!) {
        showCustomSnackBar('out_of_stock'.tr);
      } else if (quantityLimit != null) {
        if (quantity >= quantityLimit && quantityLimit != 0) {
          showCustomSnackBar('${'maximum_quantity_limit'.tr} $quantityLimit');
        } else {
          quantity = quantity + 1;
        }
      } else {
        quantity = quantity + 1;
      }
    } else {
      quantity = quantity - 1;
    }
    return quantity;
  }

  @override
  Future<double> calculateDiscountedPrice(
      CartModel cartModel, int quantity, bool isFoodVariation) async {
    // Use the already parsed unit price from cartModel (backend-sent unit price)
    final double unitPrice = cartModel.price ?? cartModel.discountedPrice ?? 0;

    // Debug logging
    debugPrint('🔍 calculateDiscountedPrice - Item: ${cartModel.item?.name}');
    debugPrint('🔍 calculateDiscountedPrice - Input quantity: $quantity');
    debugPrint(
        '🔍 calculateDiscountedPrice - Unit price from cartModel: $unitPrice');
    debugPrint(
        '🔍 calculateDiscountedPrice - CartModel.price: ${cartModel.price}');
    debugPrint(
        '🔍 calculateDiscountedPrice - CartModel.discountedPrice: ${cartModel.discountedPrice}');

    // Calculate per-unit variation and add-on surcharges
    double perUnitVariationPrice = 0;
    double perUnitAddonPrice = 0;

    if (isFoodVariation) {
      // Calculate per-unit variation price (don't multiply by quantity)
      for (int index = 0;
          index < cartModel.item!.foodVariations!.length;
          index++) {
        for (int i = 0;
            i < cartModel.item!.foodVariations![index].variationValues!.length;
            i++) {
          if (cartModel.foodVariations![index][i]!) {
            perUnitVariationPrice += cartModel
                .item!.foodVariations![index].variationValues![i].optionPrice!;
          }
        }
      }

      // Calculate per-unit add-on price (don't multiply by quantity)
      final List<AddOns> addOnList = [];
      for (final addOnId in cartModel.addOnIds!) {
        for (final AddOns addOns in cartModel.item!.addOns!) {
          if (addOns.id == addOnId.id) {
            addOnList.add(addOns);
            break;
          }
        }
      }
      for (int index = 0; index < addOnList.length; index++) {
        perUnitAddonPrice +=
            addOnList[index].price! * cartModel.addOnIds![index].quantity!;
      }
    }

    // Return unit price: base unit price + per-unit variations + per-unit add-ons
    final double discountedUnitPrice =
        unitPrice + perUnitVariationPrice + perUnitAddonPrice;

    debugPrint(
        '🔍 calculateDiscountedPrice - Per-unit variation price: $perUnitVariationPrice');
    debugPrint(
        '🔍 calculateDiscountedPrice - Per-unit add-on price: $perUnitAddonPrice');
    debugPrint(
        '🔍 calculateDiscountedPrice - Final unit price: $discountedUnitPrice');

    return discountedUnitPrice;
  }

  @override
  List<CartModel> formatOnlineCartToLocalCart(
      {required List<online_cart.OnlineCartModel> onlineCartModel}) {
    final List<CartModel> cartList = [];
    for (final online_cart.OnlineCartModel cart in onlineCartModel) {
      // IMPORTANT: There's a known backend bug where the cart list API returns incorrect quantity
      // The database shows the correct quantity (e.g., 3) but the API returns wrong quantity (e.g., 1)
      // This has been temporarily fixed in the cart repository with a workaround
      // Backend team needs to fix the /api/v1/customer/cart/list endpoint

      // Backend sends unit price (already discounted), use it directly
      final double unitPrice =
          cart.price!; // Backend sends unit price, not total
      double discountedUnitPrice =
          cart.price!; // Same as unit price since backend handles discount

      // Calculate discount amount for display purposes using unit prices
      // Use originalPrice if available, otherwise fall back to item.price
      final double originalUnitPrice =
          cart.item!.originalPrice ?? cart.item!.price!;
      final double discountAmount = (originalUnitPrice - unitPrice) > 0
          ? (originalUnitPrice - unitPrice)
          : 0.0;
      final int? quantity = cart.quantity;
      final int stock = cart.item!.stock ?? 0;

      final List<List<bool?>> selectedFoodVariations = [];
      final List<bool> collapsVariation = [];

      if (cart.item!.moduleType == 'food') {
        // #region agent log - cart service variations
        debugPrint(
            '🔍 [CartService] Building selectedFoodVariations for: ${cart.item!.name}');
        debugPrint(
            '   - cart.foodVariation length: ${cart.foodVariation?.length ?? 0}');
        debugPrint(
            '   - cart.item.foodVariations length: ${cart.item!.foodVariations?.length ?? 0}');
        // #endregion

        // ✅ FIX: Build selectedFoodVariations from cart.foodVariation (actual selected options)
        // NOT from cart.item.foodVariations (all available options with isSelected flags)

        if (cart.foodVariation != null && cart.foodVariation!.isNotEmpty) {
          // Backend sent actual selected variations in cart.foodVariation
          // Map them to the boolean array expected by the rest of the app

          for (int index = 0;
              index < cart.item!.foodVariations!.length;
              index++) {
            selectedFoodVariations.add([]);
            collapsVariation.add(true);

            // Find matching variation group in cart.foodVariation by name
            final String variationGroupName =
                cart.item!.foodVariations![index].name ?? '';
            online_cart.Variation? selectedVariationGroup;
            // 🔥 BUG FIX: Use try-catch with firstWhere (orElse doesn't work well with nullable types)
            try {
              selectedVariationGroup = cart.foodVariation!.firstWhere(
                (v) => v.name == variationGroupName,
              );
            } catch (e) {
              // Not found - this is expected if variation group doesn't exist
              selectedVariationGroup = null;
            }

            // Mark options as selected based on cart.foodVariation
            for (int i = 0;
                i < cart.item!.foodVariations![index].variationValues!.length;
                i++) {
              final String optionLabel =
                  cart.item!.foodVariations![index].variationValues![i].level ??
                      '';
              bool isSelected = false;

              // Check if this option is in the selected variations from backend
              if (selectedVariationGroup != null &&
                  selectedVariationGroup.values != null) {
                if (selectedVariationGroup.values is List) {
                  // New format: array of {label, optionPrice} objects
                  final List selectedValues =
                      selectedVariationGroup.values as List;
                  isSelected =
                      selectedValues.any((v) => v['label'] == optionLabel);
                }
              }

              selectedFoodVariations[index].add(isSelected);
            }
          }
          // #region agent log - selected variations built
          debugPrint(
              '🔍 [CartService] Built ${selectedFoodVariations.length} variation groups from API');
          for (int idx = 0; idx < selectedFoodVariations.length; idx++) {
            debugPrint(
                '   - Group $idx: ${selectedFoodVariations[idx].where((v) => v!).length} selected out of ${selectedFoodVariations[idx].length}');
          }
          // #endregion
        } else if (cart.item!.foodVariations != null &&
            cart.item!.foodVariations!.isNotEmpty) {
          // Fallback: Use isSelected flags from item.foodVariations (old behavior)
          for (int index = 0;
              index < cart.item!.foodVariations!.length;
              index++) {
            selectedFoodVariations.add([]);
            collapsVariation.add(true);
            for (int i = 0;
                i < cart.item!.foodVariations![index].variationValues!.length;
                i++) {
              if (cart.item!.foodVariations![index].variationValues![i]
                      .isSelected ??
                  false) {
                selectedFoodVariations[index].add(true);
              } else {
                selectedFoodVariations[index].add(false);
              }
            }
          }
        }
        // If both foodVariation and item.foodVariations are problematic,
        // selectedFoodVariations will be empty and rawFoodVariations will be used
      } else {
        // For variations, use the unit price
        discountedUnitPrice = unitPrice;
      }

      final List<AddOn> addOnIdList = [];
      final List<AddOns> addOnsList = [];
      for (int index = 0; index < cart.addOnIds!.length; index++) {
        addOnIdList.add(
            AddOn(id: cart.addOnIds![index], quantity: cart.addOnQtys![index]));
        for (int i = 0; i < cart.item!.addOns!.length; i++) {
          if (cart.addOnIds![index] == cart.item!.addOns![i].id) {
            addOnsList.add(AddOns(
                id: cart.item!.addOns![i].id,
                name: cart.item!.addOns![i].name,
                price: cart.item!.addOns![i].price));
          }
        }
      }

      final int? quantityLimit = cart.item!.quantityLimit;

      // Readable labels for the customer's chosen options, built directly from
      // the variations the backend returned (cart.foodVariation). This works even
      // when the item's foodVariations definitions are absent (as with the
      // lightweight v2 cart items), so the cart shows the choices under the name.
      final List<String> variationLabels = [];
      if (cart.foodVariation != null) {
        for (final online_cart.Variation g in cart.foodVariation!) {
          final List<String> chosen = [];
          final dynamic vals = g.values;
          if (vals is List) {
            for (final o in vals) {
              final dynamic label = (o is Map) ? o['label'] : null;
              if (label != null && label.toString().trim().isNotEmpty) {
                chosen.add(label.toString());
              }
            }
          } else if (vals is online_cart.Value && vals.label != null) {
            for (final l in vals.label!) {
              if (l.trim().isNotEmpty) chosen.add(l);
            }
          }
          final String name = (g.name ?? '').trim();
          if (chosen.isNotEmpty) {
            variationLabels.add(
                name.isEmpty ? chosen.join('، ') : '$name: ${chosen.join('، ')}');
          }
        }
      }

      cartList.add(
        CartModel(
          id: cart.id,
          // 🔧 FIX: Explicitly set storeId to enable different-store detection
          storeId: cart.item?.storeId,
          price: unitPrice,
          discountedPrice: discountedUnitPrice,
          variation: cart.productVariation ?? [],
          foodVariations: selectedFoodVariations,
          rawFoodVariations: cart.foodVariation,
          selectedVariationLabels:
              variationLabels.isEmpty ? null : variationLabels,
          discountAmount: discountAmount,
          quantity: quantity,
          addOnIds: addOnIdList,
          addOns: addOnsList,
          isCampaign: false,
          stock: stock,
          item: cart.item,
          quantityLimit: quantityLimit,
        ),
      );
    }

    return cartList;
  }

  @override
  int isExistInCart(List<CartModel> cartList, int? itemID, String variationType,
      bool isUpdate, int? cartIndex) {
    for (int index = 0; index < cartList.length; index++) {
      if (cartList[index].item!.id == itemID &&
          (cartList[index].variation!.isNotEmpty
              ? cartList[index].variation![0].type == variationType
              : true)) {
        if ((isUpdate && index == cartIndex)) {
          return -1;
        } else {
          return index;
        }
      }
    }
    return -1;
  }

  @override
  bool existAnotherStoreItem(
      int? storeID, int? moduleId, List<CartModel> cartList) {
    if (storeID == null || moduleId == null) {
      return false;
    }
    for (final CartModel cartModel in cartList) {
      final item = cartModel.item;
      if (item == null || item.storeId == null || item.moduleId == null) {
        continue;
      }
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('${item.storeId} cartModel.item!.storeId');
        debugPrint('$storeID storeID.item!.storeId');
        debugPrint('$moduleId storeID.item!.moduleId');
        debugPrint('${item.moduleId} cartModel.item!.moduleId');
      }
      final bool differentStore = item.storeId != storeID;
      final bool differentModule = item.moduleId != moduleId;
      if (differentStore || differentModule) {
        return true;
      }
    }
    return false;
  }

  @override
  int cartQuantity(int itemId, List<CartModel> cartList) {
    int quantity = 0;
    for (final CartModel cart in cartList) {
      if (cart.item!.id == itemId) {
        quantity += cart.quantity!;
      }
    }
    return quantity;
  }

  @override
  String cartVariant(int itemId, List<CartModel> cartList) {
    String variant = '';
    for (final CartModel cart in cartList) {
      if (cart.item!.id == itemId) {
        if (!(ModuleHelper.getModuleConfig(cart.item!.moduleType)
                .newVariation ??
            false)) {
          variant = (cart.variation != null && cart.variation!.isNotEmpty)
              ? cart.variation![0].type!
              : '';
        }
      }
    }
    return variant;
  }
}
