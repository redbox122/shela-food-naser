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
/// Wired to `GET /api/v1/items/details/{id}` (module-3 scoped). Shows a
/// collapsing image gallery, the price + unit, an add/quantity control bound to
/// the cart, and the "يُباع معها أيضاً" rail from `recommended_items`.
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

  bool get hasDiscount => _effectiveDiscounted > 0 && price > _effectiveDiscounted;
  double get shownPrice => hasDiscount ? _effectiveDiscounted : price;
  int get discountPercent {
    if (!hasDiscount) return 0;
    if (discountType == 'percent' && discount > 0) return discount.round();
    return (((price - _effectiveDiscounted) / price) * 100).round();
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

  Map<String, String> get _headers => {
        AppConstants.localizationKey: 'ar',
        AppConstants.moduleId: widget.moduleId.toString(),
      };

  Future<void> _fetch() async {
    final api = _api;
    if (api == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final response = await api.getData(
        '${AppConstants.itemDetailsUri}$_currentItemId',
        headers: _headers,
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      // Only treat a 200 object with a real id as a product — an error payload
      // (e.g. 403/404 for a cross-module item) must not render as an empty card.
      final bool ok = response.statusCode == 200 &&
          body is Map &&
          (body['id'] != null);
      setState(() {
        _item = ok ? _Item.fromJson(Map<String, dynamic>.from(body)) : null;
        _loading = false;
      });
      if (ok) _fetchRelated();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// "يُباع معها أيضاً" — fetched from the dedicated related-items endpoint.
  Future<void> _fetchRelated() async {
    final api = _api;
    if (api == null) return;
    try {
      final response = await api.getData(
        '/api/v1/items/related-items/$_currentItemId',
        headers: _headers,
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = body is List
          ? body
          : (body is Map && body['data'] is List ? body['data'] as List : const []);
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
    final cart = OnlineCart(
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
      'item',
      storeId: item.storeId ?? _currentStoreId,
    );
    // Silent add: the inline stepper / floating badge reflect the new count.
    await Get.find<CartController>().addToCartOnline(cart);
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
            (!_loading && _item != null) ? const _CartSearchBar() : null,
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
      alignment: Alignment.centerRight,
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
          collapsedHeight: 140,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.close, color: Color(0xFF121C19)),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _gallerySlider(item),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: favorite + add/quantity control.
          Column(
            children: [
              const Icon(Icons.favorite_border,
                  size: 24, color: Color(0xFF717885)),
              const SizedBox(height: 16),
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
                const SizedBox(height: 8),
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
                if ((item.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    item.description!.trim(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      height: 1.6,
                      color: Color(0xFF4A4F58),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Floating green "+" that turns into a "- qty +" stepper when in the cart.
  Widget _addControl(_Item item) {
    return GetBuilder<CartController>(
      builder: (_) {
        final qty = _cartQuantity(item.id);
        if (qty == 0) {
          return Material(
            color: const Color(0xFF1F7A35),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _add(item),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.add, size: 22, color: Colors.white),
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
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: const Text(
              'يُباع معها أيضاً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
              childAspectRatio: 104 / 150,
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.sar,
            width: struck ? 12 : 15,
            height: struck ? 12 : 15,
            color: color,
            errorBuilder: (_, __, ___) => Text('﷼',
                style: robotoBold.copyWith(fontSize: 13, color: color)),
          ),
          const SizedBox(width: 3),
          Text(
            fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: struck ? 13 : 18,
              decoration: struck ? TextDecoration.lineThrough : null,
              decorationColor: color,
              color: color,
            ),
          ),
        ],
      ),
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
          border: Border.all(color: const Color(0xFFEFEFF1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CustomImage(
                  image: item.image ?? '',
                  width: double.infinity,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: Images.placeholder,
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
                  bottom: 4,
                  child: Material(
                    color: const Color(0xFFD1FDD2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onAdd,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.add,
                            size: 18, color: Color(0xFF1F7A35)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        height: 1.2,
                        color: Color(0xFF121C19),
                      ),
                    ),
                    const Spacer(),
                    _price(item.shownPrice, bold: true),
                    if (item.hasDiscount) _price(item.price, struck: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _price(double value, {bool bold = false, bool struck = false}) {
    final color = struck ? const Color(0xFF9AA0A6) : const Color(0xFF121C19);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Images.sar,
              width: struck ? 9 : 11,
              height: struck ? 9 : 11,
              color: color,
              errorBuilder: (_, __, ___) => const SizedBox()),
          const SizedBox(width: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: struck ? FontWeight.w500 : FontWeight.w700,
              fontSize: struck ? 9 : 12,
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

/// Floating green pill (cart + search), shown once the cart has items.
class _CartSearchBar extends StatelessWidget {
  const _CartSearchBar();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final int count = cartController.cartList.length;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1F7A35),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FabIconButton(
                icon: Icons.shopping_bag_outlined,
                badge: count,
                onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
              ),
              const SizedBox(width: 6),
              _FabIconButton(
                icon: Icons.search,
                onTap: () => Get.to<void>(() => const HomeSearchScreen()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FabIconButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _FabIconButton(
      {required this.icon, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 26, color: Colors.white),
          ),
          if (badge > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    height: 1.4,
                    color: Color(0xFF1F7A35),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
