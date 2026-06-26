import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/home/screens/home_search_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 REDESIGN (Market): product details screen.
///
/// Wired to `GET /api/v2/items/details/{id}` (module-3 scoped). Shows a
/// collapsing image gallery, the price + unit, an add/quantity control bound to
/// the cart, and the "يُباع معها أيضاً" rail from `/api/v2/items/related-items`.
///
/// The v2 details payload is lean (`id, name, description, price, discount,
/// image_full_url, stock, is_available`); the richer v1 fields (gallery, unit,
/// discounted_price, rating, recommended_items) are still read when present, so
/// fuller items keep rendering.
class MarketProductScreen extends StatefulWidget {
  final int itemId;
  final int? storeId;
  final int moduleId;

  const MarketProductScreen({
    super.key,
    required this.itemId,
    this.storeId,
    this.moduleId = 3,
  });

  /// Presents the product details as a draggable bottom sheet.
  static Future<void> show({
    required int itemId,
    int? storeId,
    int moduleId = 3,
  }) {
    return Get.bottomSheet(
      MarketProductScreen(
        itemId: itemId,
        storeId: storeId,
        moduleId: moduleId,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<MarketProductScreen> createState() => _MarketProductScreenState();
}

/// Lightweight product model for the details + recommended rows.
class _Item {
  final int? id;
  final String? name;
  final String? image;
  final List<String> images;
  final String? unit;
  final String? description;
  final double price;
  final double discountedPrice;
  final double discount;
  final String discountType;
  final double rating;
  final int ratingCount;
  final int? storeId;
  final int stock;
  final int maxCartQty;
  final bool available;
  final List<_Item> recommended;

  _Item({
    this.id,
    this.name,
    this.image,
    this.images = const [],
    this.unit,
    this.description,
    this.price = 0,
    this.discountedPrice = 0,
    this.discount = 0,
    this.discountType = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.storeId,
    this.stock = 0,
    this.maxCartQty = 0,
    this.available = true,
    this.recommended = const [],
  });

  static double _d(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);
  static int _i(dynamic v) => int.tryParse('${v ?? ''}') ?? 0;

  factory _Item.fromJson(Map<String, dynamic> j) {
    final imgs = <String>[];
    if (j['images_full_url'] is List) {
      for (final e in j['images_full_url'] as List) {
        final s = e?.toString();
        if (s != null && s.isNotEmpty) imgs.add(s);
      }
    }
    final main = (j['image_full_url'] ?? j['image'])?.toString();
    if (imgs.isEmpty && main != null && main.isNotEmpty) imgs.add(main);

    return _Item(
      id: int.tryParse('${j['id']}'),
      name: j['name']?.toString(),
      image: main,
      images: imgs,
      unit: (j['unit_type'] ??
              (j['unit'] is Map ? (j['unit'] as Map)['unit'] : null))
          ?.toString(),
      description: j['description']?.toString(),
      price: _d(j['price']),
      discountedPrice: _d(j['discounted_price']),
      discount: _d(j['discount']),
      discountType: j['discount_type']?.toString() ?? '',
      rating: _d(j['avg_rating']),
      ratingCount: _i(j['rating_count']),
      storeId: int.tryParse('${j['store_id']}'),
      stock: _i(j['stock']),
      maxCartQty: _i(j['maximum_cart_quantity']),
      // v2 sends `is_available`; absent on older/related payloads → assume true.
      available: j['is_available'] == null
          ? true
          : (j['is_available'] == true ||
              j['is_available'] == 1 ||
              j['is_available'].toString() == '1' ||
              j['is_available'].toString() == 'true'),
      recommended: (j['recommended_items'] is List)
          ? (j['recommended_items'] as List)
              .whereType<Map>()
              .map((e) => _Item.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  /// Discounted price, falling back to deriving it from [discount] when the
  /// backend only returns the raw discount (e.g. related-items rows).
  double get _effectiveDiscounted {
    if (discountedPrice > 0) return discountedPrice;
    if (discount > 0 && price > 0) {
      final off = discountType == 'amount' ? discount : price * discount / 100;
      final d = price - off;
      return d > 0 ? d : 0;
    }
    return 0;
  }

  bool get hasDiscount =>
      _effectiveDiscounted > 0 && price > _effectiveDiscounted;
  double get shownPrice => hasDiscount ? _effectiveDiscounted : price;
  int get discountPercent {
    if (!hasDiscount) return 0;
    if (discountType == 'percent' && discount > 0) return discount.round();
    return (((price - _effectiveDiscounted) / price) * 100).round();
  }

  /// Discount percentage as a precise value (keeps decimals, e.g. 6.68).
  double get discountPercentValue {
    if (!hasDiscount) return 0;
    if (discountType == 'percent' && discount > 0) return discount;
    return ((price - _effectiveDiscounted) / price) * 100;
  }
}

class _MarketProductScreenState extends State<MarketProductScreen> {
  _Item? _item;
  List<_Item> _related = const [];
  bool _loading = true;
  int _gallery = 0;

  /// The item currently shown — changes in place when a related item is tapped
  /// (so the sheet updates instead of stacking a new one).
  late int _currentItemId;
  int? _currentStoreId;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentItemId = widget.itemId;
    _currentStoreId = widget.storeId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Loads a different product into the same sheet (no new sheet on the stack).
  void _openItem(int id, int? storeId) {
    if (id == _currentItemId) return;
    setState(() {
      _currentItemId = id;
      _currentStoreId = storeId;
      _item = null;
      _related = const [];
      _loading = true;
      _gallery = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _fetch();
  }

  ApiClient? get _api =>
      Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;

  Future<void> _fetch() async {
    final api = _api;
    if (api == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // v2 item details is MODULE-SCOPED when a module-id header is sent: the
    // backend only finds the item within that module and 404s otherwise. A
    // market store can list products that belong to other modules, so scoping
    // to the store's module fails for them. Omitting the module-id lets the
    // backend resolve the item by id across modules (verified against the API).
    Map<String, dynamic>? data;
    try {
      final response = await api.getData(
        '/api/v2/items/details/$_currentItemId',
        headers: {AppConstants.localizationKey: 'ar'},
        useEtag: false,
        omitModuleId: true,
      );
      final dynamic body = response.body;
      if (response.statusCode == 200 && body is Map && body['id'] != null) {
        data = Map<String, dynamic>.from(body);
      }
    } catch (_) {
      // Item couldn't be resolved; the sheet shows its empty state.
    }
    if (!mounted) return;
    setState(() {
      _item = data != null ? _Item.fromJson(data) : null;
      _loading = false;
    });
    if (data != null) _fetchRelated();
  }

  /// "يُباع معها أيضاً" — fetched from the dedicated related-items endpoint.
  /// Like item details, the module-id is omitted so the backend resolves the
  /// related items by the parent item id rather than scoping to a module.
  Future<void> _fetchRelated() async {
    final api = _api;
    if (api == null) return;
    try {
      final response = await api.getData(
        '/api/v2/items/related-items/$_currentItemId',
        headers: {AppConstants.localizationKey: 'ar'},
        useEtag: false,
        omitModuleId: true,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = body is List
          ? body
          : (body is Map && body['data'] is List
              ? body['data'] as List
              : const []);
      setState(() {
        _related = raw
            .whereType<Map>()
            .map((e) => _Item.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (_) {
      // Related rail is optional; ignore failures.
    }
  }

  /// Related items from the dedicated endpoint, falling back to the ones
  /// embedded in the details response.
  List<_Item> get _relatedItems =>
      _related.isNotEmpty ? _related : (_item?.recommended ?? const []);

  // ── Cart helpers ───────────────────────────────────────────────────────────

  int _cartQuantity(int? id) {
    if (id == null || !Get.isRegistered<CartController>()) return 0;
    int q = 0;
    for (final c in Get.find<CartController>().cartList) {
      if (c.item?.id == id) q += c.quantity ?? 0;
    }
    return q;
  }

  int? _cartId(int? id) {
    if (id == null || !Get.isRegistered<CartController>()) return null;
    for (final c in Get.find<CartController>().cartList) {
      if (c.item?.id == id) return c.id;
    }
    return null;
  }

  /// Scope the cart request to the market module (the active module may differ).
  Future<void> _ensureMarketModule() async {
    if (!Get.isRegistered<SplashController>()) return;
    final sc = Get.find<SplashController>();
    if (sc.module?.id == widget.moduleId) return;
    for (final m in sc.moduleList ?? const []) {
      if (m.id == widget.moduleId) {
        await sc.setModuleHeaderOnly(m);
        break;
      }
    }
  }

  Future<void> _add(_Item item) async {
    if (item.id == null || !Get.isRegistered<CartController>()) return;
    await _ensureMarketModule();
    final cartController = Get.find<CartController>();
    final onlineCart = OnlineCart(
      null,
      item.id,
      null,
      item.shownPrice.toString(),
      '',
      [],
      [],
      1,
      [],
      [],
      [],
      // Backend expects the Eloquent model name 'Item' (capitalized); a
      // lowercase 'item' is rejected with 403 "The selected model is invalid".
      'Item',
      storeId: item.storeId ?? _currentStoreId,
    );
    // Silent add: the inline stepper / floating badge reflect the new count.
    final bool ok = await cartController.addToCartOnline(onlineCart);
    // The cart holds one store at a time; the backend rejects a cross-store add
    // with `different_store`. Offer to clear the cart, then retry.
    if (!ok && cartController.lastAddToCartErrorCode == 'different_store') {
      final bool confirmed = await _confirmClearCart();
      if (!confirmed) return;
      await cartController.clearCartList();
      await cartController.addToCartOnline(onlineCart);
    }
  }

  /// Asks the user to confirm clearing a cart that holds items from another
  /// store before adding this market item (shown on a `different_store` reject).
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

  Future<void> _decrement(_Item item) async {
    final cartId = _cartId(item.id);
    if (cartId == null || !Get.isRegistered<CartController>()) return;
    final cart = Get.find<CartController>();
    if (_cartQuantity(item.id) <= 1) {
      await cart.removeFromCartById(cartId);
    } else {
      await cart.setQuantityById(false, cartId, item.stock, item.maxCartQty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton:
            (!_loading && _item != null)
                ? _BottomActionBar(
                    storeId: widget.storeId, moduleId: widget.moduleId)
                : null,
        body: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Drag handle.
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DCE1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? _skeleton()
                      : _item == null
                          ? _error()
                          : _content(_item!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _error() {
    return SafeArea(
      child: Column(
        children: [
          _closeRow(),
          const Spacer(),
          Text('no_data_available'.tr,
              style: const TextStyle(
                  fontFamily: 'Tajawal', color: Color(0xFF717885))),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _closeRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Get.back<void>(),
        icon: const Icon(Icons.close, color: Color(0xFF121C19)),
      ),
    );
  }

  Widget _content(_Item item) {
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        // Collapsing image gallery — shrinks to a smaller pinned image on scroll.
        SliverAppBar(
          pinned: true,
          primary: false,
          expandedHeight: 300,
          collapsedHeight: 64,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          // In RTL, `leading` sits on the RIGHT; the design wants the close on
          // the LEFT, so use `actions` (the end edge → left in RTL).
          actions: [
            IconButton(
              onPressed: () => Get.back<void>(),
              icon: const Icon(Icons.close, color: Color(0xFF121C19)),
            ),
          ],
          flexibleSpace: LayoutBuilder(
            builder: (context, constraints) {
              const double maxH = 300, minH = 64;
              // t: 1 fully expanded → 0 fully collapsed.
              final double t = ((constraints.maxHeight - minH) / (maxH - minH))
                  .clamp(0.0, 1.0);
              // Image stays fully visible while shrinking, then crossfades to
              // the pinned name only in the last ~12% of the collapse (i.e. when
              // the header is almost fully collapsed), so the name doesn't show
              // while the image is still large.
              final double imageOpacity = (t / 0.12).clamp(0.0, 1.0);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (imageOpacity > 0)
                    Opacity(
                      opacity: imageOpacity,
                      child: _gallerySlider(item),
                    ),
                  // Pinned name, driven by the real scroll offset (not the
                  // header's own collapse): it fades in only AFTER the in-body
                  // name has scrolled up under the app bar, so the two titles
                  // are never visible at the same time.
                  AnimatedBuilder(
                    animation: _scroll,
                    builder: (context, _) {
                      final double offset =
                          _scroll.hasClients ? _scroll.offset : 0;
                      const double fadeStart = (maxH - minH) + 16;
                      const double fadeEnd = (maxH - minH) + 48;
                      final double nameOpacity =
                          ((offset - fadeStart) / (fadeEnd - fadeStart))
                              .clamp(0.0, 1.0);
                      if (nameOpacity == 0) return const SizedBox.shrink();
                      return IgnorePointer(
                        child: Opacity(
                          opacity: nameOpacity,
                          child: Padding(
                            // Leave room for the close button on the left (RTL).
                            padding: const EdgeInsets.only(left: 56, right: 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                item.name ?? '',
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  height: 1.3,
                                  color: Color(0xFF121C19),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: _info(item)),
        if (_relatedItems.isNotEmpty)
          SliverToBoxAdapter(child: _recommendedSection(_relatedItems)),
        const SliverToBoxAdapter(
          child: SizedBox(height: Dimensions.paddingSizeLarge),
        ),
      ],
    );
  }

  Widget _gallerySlider(_Item item) {
    final imgs = item.images.isNotEmpty ? item.images : [''];
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          itemCount: imgs.length,
          onPageChanged: (i) => setState(() => _gallery = i),
          itemBuilder: (_, i) => CustomImage(
            image: imgs[i],
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            placeholder: Images.placeholder,
          ),
        ),
        // Discount badge pinned to the image's top-right corner.
        if (item.hasDiscount)
          Positioned(
            top: 12,
            right: 12,
            child: _discountBadge(item),
          ),
        if (imgs.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imgs.length, (i) {
                final active = i == _gallery;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: active ? 16 : 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF1F7A35)
                        : const Color(0x331F7A35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _info(_Item item) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Row(
        // Force LTR so the favourite + add column sits on the LEFT and the
        // name/price (right-aligned) stays on the RIGHT, matching the design.
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: favorite (white circle) + add/quantity control (light-green
          // circle), and a green discount pill below when the item is discounted.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0xffFAFAFB),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(Images.heart_v2),
              ),
              const SizedBox(height: 12),
              _addControl(item),
            ],
          ),
          const SizedBox(width: 12),
          // Right: name, unit, price, description (right-aligned).
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.name ?? '',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.3,
                    color: Color(0xFF121C19),
                  ),
                ),
                if ((item.unit ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.unit!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Color(0xFF717885),
                    ),
                  ),
                ],
                if ((item.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description!.trim(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.4,
                      color: Color(0xFF4A4F58),
                    ),
                  ),
                ],
                // Price + struck original, placed below the description.
                const SizedBox(height: 14),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    _priceWidget(item.shownPrice, bold: true),
                    if (item.hasDiscount) ...[
                      const SizedBox(width: 6),
                      _priceWidget(item.price, struck: true),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Green "خصم %X" pill shown under the add control for a discounted item.
  Widget _discountBadge(_Item item) {
    final double v = item.discountPercentValue;
    final String txt =
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDCDC),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Text(
        'خصم %$txt',
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Colors.red,
        ),
      ),
    );
  }

  /// Floating green "+" that turns into a "- qty +" stepper when in the cart.
  Widget _addControl(_Item item) {
    // Out-of-stock / unavailable items can't be added — show a muted disc.
    if (!item.available) {
      return Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFF0F1F3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.do_not_disturb_alt,
            size: 22, color: Color(0xFF9AA0A6)),
      );
    }
    return GetBuilder<CartController>(
      builder: (_) {
        final qty = _cartQuantity(item.id);
        if (qty == 0) {
          return Material(
            color: const Color(0xFFD1FDD2),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _add(item),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.add, size: 35, color: Color(0xFF1F7A35)),
              ),
            ),
          );
        }
        return Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF1F7A35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepBtn(Icons.remove, () => _decrement(item)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              _stepBtn(Icons.add, () => _add(item)),
            ],
          ),
        );
      },
    );
  }

  Widget _recommendedSection(List<_Item> items) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: const Text(
              'يُباع معها أيضاً',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.4,
                color: Color(0xFF121C19),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              // Design card is 104×130.
              childAspectRatio: 104 / 130,
            ),
            itemBuilder: (_, i) => _RecommendedCard(
              item: items[i],
              onAdd: () => _add(items[i]),
              onTap: () => _openItem(items[i].id ?? 0, items[i].storeId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 36,
      height: 38,
      child: InkWell(
        onTap: onTap,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _priceWidget(double value, {bool bold = false, bool struck = false}) {
    final color = struck ? const Color(0xFF9AA0A6) : const Color(0xFF121C19);
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          Images.sar,
          width: struck ? 18 : 22,
          height: struck ? 18 : 22,
          color: color,
          errorBuilder: (_, __, ___) => Text('﷼',
              style: robotoBold.copyWith(
                  fontSize: struck ? 18 : 22, color: color)),
        ),
        const SizedBox(width: 3),
        Text(
          fmt(value),
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontSize: struck ? 20 : 24,
            height: 1.2,
            color: color,
          ),
        ),
      ],
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: struck
          // A line drawn across the whole price (currency icon + number), so the
          // discounted original always reads as struck-through.
          ? Stack(
              alignment: Alignment.center,
              children: [
                row,
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 1.5,
                      // Red strikethrough line over the (grey) original price.
                      child: const ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ],
            )
          : row,
    );
  }

  Widget _skeleton() {
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        highlightColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 300, color: Colors.white),
            const SizedBox(height: 16),
            Container(
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Container(
              height: 16,
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact card for the "يُباع معها أيضاً" rail: image with a "-X%" badge and a
/// "+" add button, then the name and price (struck original + discounted).
class _RecommendedCard extends StatelessWidget {
  final _Item item;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const _RecommendedCard({
    required this.item,
    required this.onTap,
    required this.onAdd,
  });

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image flexes to fill whatever height the (fixed) text leaves, so
            // a 2-line name always fits the fixed-size card without overflow.
            Expanded(
              child: Stack(
                // Let the "+" button straddle the image's bottom edge.
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomImage(
                      image: item.image ?? '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: Images.placeholder,
                    ),
                  ),
                  if (item.discountPercent > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          borderRadius:
                              BorderRadius.only(bottomLeft: Radius.circular(6)),
                        ),
                        child: Text(
                          '-${item.discountPercent}%',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 4,
                    bottom: -16,
                    child: Material(
                      color: const Color(0xFFD1FDD2),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onAdd,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.add,
                              size: 25, color: Color(0xFF1F7A35)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed 2-line height so the name shows fully and every card's
                  // image stays the same size. The left lane keeps the text off
                  // the straddling "+" button.
                  SizedBox(
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 38),
                      child: Text(
                        item.name ?? '',
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF121C19),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _price(item.shownPrice, bold: true),
                  if (item.hasDiscount) _price(item.price, struck: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _price(double value, {bool bold = false, bool struck = false}) {
    // Spec: Tajawal / Medium 500 / 10px / line-height 140% / right / black.
    // The struck original stays a lighter grey to read as the "before" price.
    final color = struck ? const Color(0xFF9AA0A6) : const Color(0xFF000000);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Images.sar,
              width: 15,
              height: 15,
              color: color,
              errorBuilder: (_, __, ___) => const SizedBox()),
          const SizedBox(width: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.4,
              decoration: struck ? TextDecoration.lineThrough : null,
              decorationColor: color,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom green pill with two actions: open cart (with a count badge) and open
/// search. Centered above the bottom edge of the sheet.
class _BottomActionBar extends StatelessWidget {
  final int? storeId;
  final int? moduleId;
  const _BottomActionBar({this.storeId, this.moduleId});

  static const Color _accent = Color(0xFF1F7A35);
  // The pill is split into two shades: the cart half (lighter) and the search
  // half (darker), matching the design.
  static const Color _cartColor = Color(0xFF30913F);
  static const Color _searchColor = Color(0xFF237D2D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _accent,
      borderRadius: BorderRadius.circular(30),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 128,
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cart half (lighter green) with a count badge.
            Expanded(
              child: ColoredBox(
                color: _cartColor,
                child: Center(
                  child: GetBuilder<CartController>(
                    builder: (cartController) {
                      final int count = cartController.cartList.length;
                      final bool hasItems = count > 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () =>
                                Get.toNamed(RouteHelper.getCartRoute()),
                            icon: Image.asset(
                              hasItems ? Images.bag_v2_active : Images.bag_v2,
                              width: 24,
                              height: 24,
                              // Active cart icon tinted white to match the design.
                              color: Colors.white,
                            ),
                          ),
                          if (hasItems)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                constraints: const BoxConstraints(minWidth: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    height: 1.3,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Search half (darker green).
            Expanded(
              child: ColoredBox(
                color: _searchColor,
                child: Center(
                  child: IconButton(
                    onPressed: () =>
                        Get.to<void>(() =>
                            HomeSearchScreen(storeId: storeId, moduleId: moduleId)),
                    icon: Image.asset(
                      Images.search_v2,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.search,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
