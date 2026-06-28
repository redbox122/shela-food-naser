part of 'market_store_screen.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class _Category {
  final int? id;

  /// Raw id as returned (a numeric id, or "offers" for the Best Offers tile).
  final String rawId;
  final String? name;
  final String? image;
  final bool isDiscount;
  _Category(
      {this.id,
      this.rawId = '',
      this.name,
      this.image,
      this.isDiscount = false});
  factory _Category.fromJson(Map<String, dynamic> j) => _Category(
        id: int.tryParse('${j['id']}'),
        rawId: j['id']?.toString() ?? '',
        name: j['name']?.toString(),
        image: (j['full_image_url'] ?? j['image_full_url'] ?? j['image'])
            ?.toString(),
        isDiscount: j['is_discount_category'] == true,
      );
}

class _Product {
  final int? id;
  final String? name;
  final String? image;
  final double price;
  final double originalPrice;
  final double discountedPrice;

  /// Short product description shown under the name in the list rows.
  final String? description;

  /// How many times the item has been ordered (e.g. "عدد الطلبات: +500").
  final int orderCount;

  _Product({
    this.id,
    this.name,
    this.image,
    this.price = 0,
    this.originalPrice = 0,
    this.discountedPrice = 0,
    this.description,
    this.orderCount = 0,
  });

  static double _d(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  factory _Product.fromJson(Map<String, dynamic> j) => _Product(
        // Featured/discount sections may carry the item id under
        // item_id/product_id instead of id; fall back so taps still open it.
        id: int.tryParse('${j['id'] ?? j['item_id'] ?? j['product_id']}'),
        name: j['name']?.toString(),
        image: (j['full_image_url'] ?? j['image_full_url'])?.toString(),
        price: _d(j['price']),
        originalPrice: _d(j['original_price']),
        discountedPrice: _d(j['discounted_price']),
        description: j['description']?.toString(),
        orderCount: int.tryParse('${j['order_count'] ?? 0}') ?? 0,
      );

  bool get hasDiscount =>
      discountedPrice > 0 && originalPrice > discountedPrice;

  /// Discount percentage (e.g. 6 → "-6%"); 0 when there is no discount.
  int get discountPercent => hasDiscount
      ? (((originalPrice - discountedPrice) / originalPrice) * 100).round()
      : 0;

  /// Effective price to show as the main (bold) price.
  double get shownPrice =>
      hasDiscount ? discountedPrice : (price > 0 ? price : discountedPrice);
}

/// The market lives in module 3; cart requests must be scoped to it.
const int _marketModuleId = 3;

/// Asks the user to confirm clearing a cart that holds items from another
/// store/module before adding a market item.
Future<bool> _confirmClearCart() async {
  final result = await Get.dialog<bool>(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_shopping_cart_outlined,
                size: 44, color: Color(0xFF1F7A35)),
            const SizedBox(height: 12),
            Text(
              'cart_has_other_store_items'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.4,
                color: Color(0xFF121C19),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'clear_cart_to_continue'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF717885),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back<bool>(result: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF121C19),
                      side: const BorderSide(color: Color(0xFFE6E8EC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('cancel'.tr,
                        style: const TextStyle(fontFamily: 'Tajawal')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back<bool>(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F7A35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('clear_and_add'.tr,
                        style: const TextStyle(fontFamily: 'Tajawal')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result == true;
}

/// Adds a single unit of [product] (from store [storeId], module [moduleId]) to
/// the online cart.
Future<void> _addProductToCart(_Product product, int? storeId,
    {int moduleId = _marketModuleId}) async {
  if (product.id == null || !Get.isRegistered<CartController>()) return;
  final cartController = Get.find<CartController>();

  // The cart can only hold items from one store/module at a time. If it already
  // has items from another store/module, confirm clearing it first.
  if (cartController.existAnotherStoreItem(storeId, moduleId)) {
    final bool confirmed = await _confirmClearCart();
    if (!confirmed) return;
    await cartController.clearCartList();
  }

  // The add-to-cart endpoint reads the module from the request header, and the
  // cart keys its cache on the *cache* module. The app's active module may
  // differ (e.g. restaurants/6 while browsing the market/3), so align both —
  // otherwise the cart desyncs (saves under the wrong module).
  if (Get.isRegistered<SplashController>()) {
    final sc = Get.find<SplashController>();
    for (final m in sc.moduleList ?? const []) {
      if (m.id == moduleId) {
        if (sc.module?.id != moduleId) await sc.setModuleHeaderOnly(m);
        await sc.setCacheModuleOnly(m);
        break;
      }
    }
  }
  final cart = OnlineCart(
    null,
    product.id,
    null,
    product.shownPrice.toString(),
    '',
    [],
    [],
    1,
    [],
    [],
    [],
    'Item',
    itemType: 'Item',
    storeId: storeId,
  );
  try {
    bool ok = await cartController.addToCartOnline(cart);
    // Belt-and-suspenders: if the pre-check missed and the backend rejected the
    // cross-store add, confirm clearing the cart and retry.
    if (!ok && cartController.lastAddToCartErrorCode == 'different_store') {
      final bool confirmed = await _confirmClearCart();
      if (!confirmed) return;
      await cartController.clearCartList();
      ok = await cartController.addToCartOnline(cart);
    }
    if (!ok) {
      showCustomSnackBar('failed_to_add_to_cart'.tr, isError: true);
    } else {
      _showAddedToCartToast();
    }
  } catch (e) {
    showCustomSnackBar(e.toString(), isError: true);
  }
}

/// "تمت إضافة المنتج بنجاح" toast shown after a successful add-to-cart. A light
/// green pill that floats just above the bottom nav bar, with a dark check badge.
void _showAddedToCartToast() {
  if (Get.isSnackbarOpen) return;
  Get.rawSnackbar(
    messageText: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF143A2B),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'product_added_successfully'.tr,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF143A2B),
            ),
          ),
        ),
      ],
    ),
    backgroundColor: const Color(0xFFD7F7DB),
    borderRadius: 30,
    // Float the pill above the bottom nav bar, inset from the side edges.
    margin: const EdgeInsets.only(left: 36, right: 36, bottom: 90),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(milliseconds: 1800),
    animationDuration: const Duration(milliseconds: 250),
    boxShadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Units of [id] currently in the cart.
int _cartQty(int? id) {
  if (id == null || !Get.isRegistered<CartController>()) return 0;
  int q = 0;
  for (final c in Get.find<CartController>().cartList) {
    if (c.item?.id == id) q += c.quantity ?? 0;
  }
  return q;
}

int? _cartLineId(int? id) {
  if (id == null || !Get.isRegistered<CartController>()) return null;
  for (final c in Get.find<CartController>().cartList) {
    if (c.item?.id == id) return c.id;
  }
  return null;
}

/// Removes one unit of [product] (or the whole line when it reaches zero).
Future<void> _decProductFromCart(_Product product) async {
  final lineId = _cartLineId(product.id);
  if (lineId == null || !Get.isRegistered<CartController>()) return;
  final cart = Get.find<CartController>();
  if (_cartQty(product.id) <= 1) {
    await cart.removeFromCartById(lineId);
  } else {
    await cart.setQuantityById(false, lineId, 9999, 0);
  }
}

class _FeaturedSection {
  final int? storeId;

  /// Module of the featured store — its products live in this module, not
  /// necessarily the market (3), so opening their details must use it.
  final int? moduleId;
  final String? logo;

  /// Cover/banner image for the branded "see more" header (when the API
  /// provides one — keys vary, so several are tried).
  final String? cover;
  final String? slogan;
  final List<_Product> products;
  _FeaturedSection(
      {this.storeId,
      this.moduleId,
      this.logo,
      this.cover,
      this.slogan,
      this.products = const []});

  factory _FeaturedSection.fromJson(Map<String, dynamic> j) => _FeaturedSection(
        storeId: int.tryParse('${j['store_id']}'),
        moduleId: int.tryParse('${j['module_id']}'),
        logo: j['logo_url']?.toString(),
        // Featured-store cover — the cover of the store that owns this block's
        // `store_id` (not the page's root store). The backend returns it as
        // `cover_photo_full_url`; older keys kept as fallbacks. Empty → the
        // branded offers header falls back to a solid accent band.
        cover: (j['cover_photo_full_url'] ??
                j['cover_url'] ??
                j['store_image_full_url'] ??
                j['store_image_url'] ??
                j['image_url'] ??
                j['cover'])
            ?.toString(),
        slogan: j['slogan']?.toString(),
        products: (j['products'] is List)
            ? (j['products'] as List)
                .whereType<Map>()
                .map((e) => _Product.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
      );
}

class _StoreDetail {
  final String? name;
  final String? logo;
  final String? cover;
  final String? description;
  final double rating;
  final bool freeDelivery;
  final String? deliveryTime;
  final double? distance;
  final List<_Category> categories;
  final String? categoryId;
  final String? categoryName;
  final List<_Product> categoryProducts;
  final _FeaturedSection? discounted;
  final _FeaturedSection? featured;

  _StoreDetail({
    this.name,
    this.logo,
    this.cover,
    this.description,
    this.rating = 0,
    this.freeDelivery = false,
    this.deliveryTime,
    this.distance,
    this.categories = const [],
    this.categoryId,
    this.categoryName,
    this.categoryProducts = const [],
    this.discounted,
    this.featured,
  });

  static bool _toBool(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';

  factory _StoreDetail.fromJson(Map<String, dynamic> j) {
    List<_Product> products(dynamic node) =>
        (node is Map && node['products'] is List)
            ? (node['products'] as List)
                .whereType<Map>()
                .map((e) => _Product.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [];
    final catProd = j['category_products'];
    return _StoreDetail(
      name: j['store_name']?.toString(),
      logo: j['store_logo_url']?.toString(),
      cover: j['store_image_url']?.toString(),
      description: j['store_description']?.toString(),
      rating: _Product._d(j['rating']),
      freeDelivery: _toBool(j['free_delivery']),
      deliveryTime: j['delivery_time']?.toString(),
      distance: (j['distance'] == null && j['distance_in_meters'] == null)
          ? null
          : _Product._d(j['distance'] ?? j['distance_in_meters']),
      categories: (j['categories'] is List)
          ? (j['categories'] as List)
              .whereType<Map>()
              .map((e) => _Category.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      categoryId: catProd is Map ? catProd['category_id']?.toString() : null,
      categoryName:
          catProd is Map ? catProd['category_name']?.toString() : null,
      categoryProducts: products(catProd),
      discounted: j['featured_store_discounted'] is Map
          ? _FeaturedSection.fromJson(
              Map<String, dynamic>.from(j['featured_store_discounted'] as Map))
          : null,
      featured: j['featured_store_products'] is Map
          ? _FeaturedSection.fromJson(
              Map<String, dynamic>.from(j['featured_store_products'] as Map))
          : null,
    );
  }
}
