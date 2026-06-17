import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/home/screens/home_search_screen.dart';
import 'package:sixam_mart/features/home/screens/market_product_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 REDESIGN (Market): store category / "Best Offers" screen.
///
/// Opened from a store's category tile (or the Best Offers tile). Loads
/// `GET /api/v2/stores/{store_id}/categories/{category_id}?limit=20`, which
/// returns `sub_categories` — each a second-bar tab carrying its own embedded
/// products (first page) plus `total_products`/`has_more`. Normal categories
/// and Best Offers share the same structure; only `is_discount_category` differs.
class MarketOffersScreen extends StatefulWidget {
  final String title;
  final int moduleId;

  /// Store the category belongs to (required for the store-scoped endpoints).
  final int? storeId;

  /// Category id within the store: a numeric id (as a string) or "offers".
  final String? categoryId;

  const MarketOffersScreen({
    super.key,
    this.title = '',
    this.moduleId = 3,
    this.storeId,
    this.categoryId,
  });

  @override
  State<MarketOffersScreen> createState() => _MarketOffersScreenState();
}

/// Product row returned inside a sub_category:
/// `{ id, name, full_image_url, price, discounted_price, discount_percentage }`.
class _OfferProduct {
  final int? id;
  final String? name;
  final String? image;
  final double price;
  final double discountedPrice;
  final double discountPercentage;

  _OfferProduct({
    this.id,
    this.name,
    this.image,
    this.price = 0,
    this.discountedPrice = 0,
    this.discountPercentage = 0,
  });

  static double _d(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  factory _OfferProduct.fromJson(Map<String, dynamic> j) => _OfferProduct(
        id: int.tryParse('${j['id']}'),
        name: j['name']?.toString(),
        image: (j['full_image_url'] ?? j['image_full_url'] ?? j['image'])
            ?.toString(),
        price: _d(j['price']),
        discountedPrice: _d(j['discounted_price']),
        discountPercentage: _d(j['discount_percentage']),
      );

  bool get hasDiscount => discountedPrice > 0 && price > discountedPrice;

  double get shownPrice => hasDiscount ? discountedPrice : price;

  /// Discount percentage for the "-X%" badge.
  int get discountPercent {
    if (discountPercentage > 0) return discountPercentage.round();
    if (hasDiscount) return (((price - discountedPrice) / price) * 100).round();
    return 0;
  }
}

/// One second-bar tab = a sub_category with its embedded first page of products.
class _SubCat {
  final String id;
  final String name;
  final List<_OfferProduct> products;
  final int total;
  final bool hasMore;

  const _SubCat({
    required this.id,
    required this.name,
    this.products = const [],
    this.total = 0,
    this.hasMore = false,
  });

  factory _SubCat.fromJson(Map<String, dynamic> j) => _SubCat(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        products: (j['products'] is List)
            ? (j['products'] as List)
                .whereType<Map>()
                .map((e) => _OfferProduct.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        total: int.tryParse('${j['total_products']}') ?? 0,
        hasMore: j['has_more'] == true,
      );
}

/// Top-bar store category: `{ id, name, is_discount_category }` from
/// `GET /api/v2/stores/{store_id}/categories`.
class _StoreCat {
  final String id;
  final String name;
  final bool isDiscount;
  const _StoreCat(
      {required this.id, required this.name, this.isDiscount = false});

  factory _StoreCat.fromJson(Map<String, dynamic> j) => _StoreCat(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        isDiscount: j['is_discount_category'] == true,
      );
}

// ─── Cart helpers ────────────────────────────────────────────────────────────

/// Units of [id] currently in the cart.
int _offerCartQty(int? id) {
  if (id == null || !Get.isRegistered<CartController>()) return 0;
  int q = 0;
  for (final c in Get.find<CartController>().cartList) {
    if (c.item?.id == id) q += c.quantity ?? 0;
  }
  return q;
}

int? _offerCartLineId(int? id) {
  if (id == null || !Get.isRegistered<CartController>()) return null;
  for (final c in Get.find<CartController>().cartList) {
    if (c.item?.id == id) return c.id;
  }
  return null;
}

/// Scope the cart to the product's module. The active module may differ
/// (e.g. the app sits on restaurants/6 while browsing the market/3); the cart
/// keys its cache on the *cache* module, so both the request header
/// ([setModuleHeaderOnly]) and the cache module ([setCacheModuleOnly]) must be
/// aligned — otherwise the cart desyncs (saves under the wrong module).
Future<void> _ensureModule(int moduleId) async {
  if (!Get.isRegistered<SplashController>()) return;
  final sc = Get.find<SplashController>();
  final list = sc.moduleList;
  if (list == null) return;
  for (final m in list) {
    if (m.id == moduleId) {
      if (sc.module?.id != moduleId) await sc.setModuleHeaderOnly(m);
      await sc.setCacheModuleOnly(m);
      return;
    }
  }
}

Future<void> _addOfferToCart(_OfferProduct p, int? storeId, int moduleId) async {
  if (p.id == null || !Get.isRegistered<CartController>()) return;
  await _ensureModule(moduleId);
  final cart = OnlineCart(null, p.id, null, p.shownPrice.toString(), '', [], [],
      1, [], [], [], 'Item',
      storeId: storeId);
  // Silent add: the card's stepper + floating badge reflect the new count.
  await Get.find<CartController>().addToCartOnline(cart);
}

Future<void> _decOfferFromCart(_OfferProduct p) async {
  final lineId = _offerCartLineId(p.id);
  if (lineId == null || !Get.isRegistered<CartController>()) return;
  final cart = Get.find<CartController>();
  if (_offerCartQty(p.id) <= 1) {
    await cart.removeFromCartById(lineId);
  } else {
    await cart.setQuantityById(false, lineId, 9999, 0);
  }
}

class _MarketOffersScreenState extends State<MarketOffersScreen> {
  final ScrollController _scroll = ScrollController();

  // Top bar: store categories (Best Offers + others).
  List<_StoreCat> _cats = const [];
  int _selectedCat = -1;

  // Second bar + content: the selected category's sub_categories, each rendered
  // as a stacked titled section. The pills scroll to their section.
  List<_SubCat> _subs = const [];
  final Map<int, GlobalKey> _sectionKeys = {};
  int _selectedTab = 0;
  bool _loadingDetail = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  ApiClient? get _api =>
      Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;

  Map<String, String> get _headers => {
        AppConstants.localizationKey: 'ar',
        AppConstants.moduleId: widget.moduleId.toString(),
      };

  /// Initial category id — "offers" by default (Best Offers).
  String get _initialCatId =>
      (widget.categoryId == null || widget.categoryId!.isEmpty)
          ? 'offers'
          : widget.categoryId!;

  Future<void> _init() async {
    await _fetchCats();
    final id = _selectedCat >= 0 ? _cats[_selectedCat].id : _initialCatId;
    await _fetchDetail(id);
  }

  /// Top bar: the store's categories, pre-selecting the requested one.
  Future<void> _fetchCats() async {
    final api = _api;
    if (api == null || widget.storeId == null) return;
    try {
      final response = await api.getData(
        '/api/v2/stores/${widget.storeId}/categories',
        headers: _headers,
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = body is List
          ? body
          : (body is Map && body['data'] is List
              ? body['data'] as List
              : const []);
      final cats = raw
          .whereType<Map>()
          .map((e) => _StoreCat.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      int sel = cats.indexWhere((c) => c.id == _initialCatId);
      if (sel < 0) sel = 0;
      setState(() {
        _cats = cats;
        _selectedCat = cats.isEmpty ? -1 : sel;
      });
    } catch (_) {
      // Top bar is optional; ignore failures.
    }
  }

  /// Load one category's sub_categories (each carries its embedded products).
  Future<void> _fetchDetail(String catId) async {
    final api = _api;
    if (api == null || widget.storeId == null) {
      if (mounted) setState(() => _loadingDetail = false);
      return;
    }
    if (mounted) setState(() => _loadingDetail = true);
    try {
      final response = await api.getData(
        '/api/v2/stores/${widget.storeId}/categories/$catId?limit=20',
        headers: _headers,
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = (body is Map && body['sub_categories'] is List)
          ? body['sub_categories'] as List
          : const [];
      final subs = raw
          .whereType<Map>()
          .map((e) => _SubCat.fromJson(Map<String, dynamic>.from(e)))
          .where((s) => s.products.isNotEmpty)
          .toList();
      setState(() {
        _subs = subs;
        _selectedTab = 0;
        _sectionKeys
          ..clear()
          ..addEntries(
              List.generate(subs.length, (i) => MapEntry(i, GlobalKey())));
        _loadingDetail = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  /// Switching the top category reloads its sub_category sections.
  void _onCatTap(int i) {
    if (i == _selectedCat) return;
    setState(() {
      _selectedCat = i;
      _subs = const [];
      _selectedTab = 0;
    });
    _fetchDetail(_cats[i].id);
  }

  /// Tapping a sub_category pill scrolls to its stacked section.
  void _onTabTap(int i) {
    setState(() => _selectedTab = i);
    final ctx = _sectionKeys[i]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: Column(
          children: [
            // Green band fills behind the status bar; SafeArea pads the content.
            Container(
              color: const Color(0xFF1F7A35),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _header(),
                    if (_cats.isNotEmpty) _topBar(),
                  ],
                ),
              ),
            ),
            // Second bar (sub_category pills) on a white strip.
            if (!_loadingDetail && _subs.isNotEmpty) _tabsBar(),
            Expanded(child: _body()),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: const _CartSearchBar(),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Get.back<void>(),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_ios_new,
                  size: 20, color: Colors.white),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// Top green row: store categories; the active one is underlined.
  Widget _topBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final bool selected = i == _selectedCat;
          return GestureDetector(
            onTap: () => _onCatTap(i),
            child: Center(
              child: _CaretTab(label: _cats[i].name, selected: selected),
            ),
          );
        },
      ),
    );
  }

  /// Second row: sub_category pills (scroll-to-section) on white.
  Widget _tabsBar() {
    return Container(
      height: 52,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: _subs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final bool selected = i == _selectedTab;
          return GestureDetector(
            onTap: () => _onTabTap(i),
            child: Center(
              child: _PillTab(label: _subs[i].name, selected: selected),
            ),
          );
        },
      ),
    );
  }

  /// Stacked sections: each sub_category = green title + a 3-col products grid.
  Widget _body() {
    if (_loadingDetail) return _gridSkeleton();
    if (_subs.isEmpty) return _emptyState('no_data_available'.tr);

    final List<Widget> children = [];
    for (int i = 0; i < _subs.length; i++) {
      final sub = _subs[i];
      if (sub.products.isEmpty) continue;
      children.add(
        Padding(
          key: _sectionKeys[i],
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            8,
          ),
          child: Text(
            sub.name,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1F7A35),
            ),
          ),
        ),
      );
      children.add(
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          itemCount: sub.products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 104 / 130,
          ),
          itemBuilder: (_, j) => _OfferProductCard(
            product: sub.products[j],
            storeId: widget.storeId,
            moduleId: widget.moduleId,
          ),
        ),
      );
    }

    if (children.isEmpty) return _emptyState('no_data_available'.tr);

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
      children: children,
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Color(0xFF717885),
        ),
      ),
    );
  }

  Widget _gridSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 104 / 130,
      ),
      itemBuilder: (_, __) => _skeletonCard(),
    );
  }

  /// Product-card-shaped placeholder (image block + two name lines + price),
  /// pulsing via Shimmer — mirrors [_OfferProductCard]'s layout.
  Widget _skeletonCard() {
    Widget block({double? width, required double height, double radius = 4}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
      highlightColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFEFEFF1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            block(height: 64, radius: 0),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(height: 9),
                  const SizedBox(height: 5),
                  block(width: 60, height: 9),
                  const SizedBox(height: 10),
                  block(width: 42, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top-bar category tab: when active, the label + a 2px underline are tinted
/// #9DFCA3; otherwise dim white.
class _CaretTab extends StatelessWidget {
  final String label;
  final bool selected;
  const _CaretTab({required this.label, required this.selected});

  static const Color _activeColor = Color(0xFF9DFCA3);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? _activeColor : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          height: 1.0,
          color: selected ? _activeColor : const Color(0xCCFFFFFF),
        ),
      ),
    );
  }
}

/// Outlined pill on white: active = light-green fill + green border/text,
/// idle = white fill + light-grey border + grey text.
class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  const _PillTab({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEBFEEB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFF1F7A35) : const Color(0xFFE3E5EA),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
          height: 1.0,
          color: selected ? const Color(0xFF1F7A35) : const Color(0xFF717885),
        ),
      ),
    );
  }
}

/// Compact product card (≈104×130): image with red "-X%" badge + add button,
/// then name and price (struck original + discounted).
class _OfferProductCard extends StatelessWidget {
  final _OfferProduct product;
  final int? storeId;
  final int moduleId;
  const _OfferProductCard({
    required this.product,
    this.storeId,
    this.moduleId = 3,
  });

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => MarketProductScreen.show(
        itemId: product.id ?? 0,
        storeId: storeId,
        moduleId: moduleId,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFEFEFF1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                CustomImage(
                  image: product.image ?? '',
                  width: double.infinity,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: Images.placeholder,
                ),
                if (product.discountPercent > 0)
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
                        '-${product.discountPercent}%',
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
                  child: _AddControl(
                    product: product,
                    storeId: storeId,
                    moduleId: moduleId,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w500,
                        fontSize: 9,
                        height: 1.2,
                        color: Color(0xFF121C19),
                      ),
                    ),
                    const Spacer(),
                    _price(product.shownPrice, bold: true),
                    if (product.hasDiscount) _price(product.price, struck: true),
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
          Image.asset(
            Images.sar,
            width: struck ? 9 : 11,
            height: struck ? 9 : 11,
            color: color,
            errorBuilder: (_, __, ___) => Text('﷼',
                style: robotoBold.copyWith(fontSize: 9, color: color)),
          ),
          const SizedBox(width: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: struck ? FontWeight.w500 : FontWeight.w700,
              fontSize: struck ? 9 : 11,
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

/// Add button on a product card: a green "+" circle that becomes a green
/// "- qty +" stepper once the item is in the cart.
class _AddControl extends StatelessWidget {
  final _OfferProduct product;
  final int? storeId;
  final int moduleId;
  const _AddControl({
    required this.product,
    this.storeId,
    this.moduleId = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (_) {
        final int qty = _offerCartQty(product.id);
        if (qty == 0) {
          return Material(
            color: const Color(0xFFD1FDD2),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _addOfferToCart(product, storeId, moduleId),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.add, size: 18, color: Color(0xFF1F7A35)),
              ),
            ),
          );
        }
        return Container(
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1F7A35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _step(Icons.remove, () => _decOfferFromCart(product)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              _step(Icons.add, () => _addOfferToCart(product, storeId, moduleId)),
            ],
          ),
        );
      },
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 16, color: Colors.white),
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
