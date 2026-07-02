import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🔎 Category browse results — opened after the customer taps a category on the
/// search screen. Shows the stores that carry the category (horizontal cards)
/// then its products in a grid. Data:
///   • stores   → GET /api/v1/categories/stores/{id}
///   • products → GET /api/v1/categories/items/{id}?offset=&limit=
class CategoryResultsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int? moduleId;
  const CategoryResultsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.moduleId,
  });

  @override
  State<CategoryResultsScreen> createState() => _CategoryResultsScreenState();
}

class _CategoryResultsScreenState extends State<CategoryResultsScreen> {
  final ScrollController _scroll = ScrollController();
  static const int _pageSize = 20;

  List<_CatStore> _stores = const [];
  final List<_CatProduct> _products = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Map<String, String> get _headers => {
        AppConstants.localizationKey: 'ar',
        if (widget.moduleId != null)
          AppConstants.moduleId: widget.moduleId.toString(),
      };

  void _onScroll() {
    if (_scroll.position.pixels >
            _scroll.position.maxScrollExtent - 400 &&
        !_loadingMore &&
        _hasMore) {
      _loadMoreProducts();
    }
  }

  Future<void> _load() async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final api = Get.find<ApiClient>();
    try {
      final results = await Future.wait([
        api.getData('${AppConstants.categoryStoreUri}${widget.categoryId}',
            headers: _headers, useEtag: false),
        api.getData(
            '${AppConstants.categoryItemUri}${widget.categoryId}?offset=1&limit=$_pageSize&type=all',
            headers: _headers,
            useEtag: false),
      ]);
      if (!mounted) return;
      final stores = _parseStores(results[0].body);
      final products = _parseProducts(results[1].body);
      setState(() {
        _stores = stores;
        _products
          ..clear()
          ..addAll(products);
        _hasMore = products.length >= _pageSize;
        _offset = 2;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    setState(() => _loadingMore = true);
    try {
      final api = Get.find<ApiClient>();
      final r = await api.getData(
          '${AppConstants.categoryItemUri}${widget.categoryId}?offset=$_offset&limit=$_pageSize&type=all',
          headers: _headers,
          useEtag: false);
      final page = _parseProducts(r.body);
      if (!mounted) return;
      setState(() {
        _products.addAll(page);
        _hasMore = page.length >= _pageSize;
        _offset += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<_CatStore> _parseStores(dynamic body) {
    final List raw = body is List
        ? body
        : (body is Map && body['stores'] is List)
            ? body['stores'] as List
            : (body is Map && body['data'] is List)
                ? body['data'] as List
                : const [];
    return raw
        .whereType<Map>()
        .map((e) => _CatStore.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<_CatProduct> _parseProducts(dynamic body) {
    final List raw = body is List
        ? body
        : (body is Map && body['products'] is List)
            ? body['products'] as List
            : (body is Map && body['items'] is List)
                ? body['items'] as List
                : (body is Map && body['data'] is List)
                    ? body['data'] as List
                    : const [];
    return raw
        .whereType<Map>()
        .map((e) => _CatProduct.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(title: widget.categoryName),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: CustomScrollView(
                        controller: _scroll,
                        slivers: [
                          if (_stores.isNotEmpty) ...[
                            _sectionTitle('المتاجر'),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 118,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal:
                                          Dimensions.paddingSizeDefault),
                                  itemCount: _stores.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (_, i) =>
                                      _StoreChip(store: _stores[i]),
                                ),
                              ),
                            ),
                          ],
                          _sectionTitle('المنتجات'),
                          if (_products.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Center(
                                  child: Text('لا توجد منتجات في هذا القسم',
                                      style: robotoRegular.copyWith(
                                          color:
                                              Theme.of(context).hintColor)),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) =>
                                      _ProductCard(product: _products[i]),
                                  childCount: _products.length,
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 60,
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : const SizedBox(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 8),
          child: Text(t,
              textAlign: TextAlign.right,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),
      );
}

// ─── header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Get.back<void>(),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ─── store chip ──────────────────────────────────────────────────────────────

class _StoreChip extends StatelessWidget {
  final _CatStore store;
  const _StoreChip({required this.store});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to<void>(() => MarketStoreScreen(
            storeId: store.id,
            moduleId: store.moduleId ?? 3,
            name: store.name,
            logo: store.logo,
            rating: store.rating,
            useCoverHeader: true,
          )),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomImage(
                image: store.logo ?? '',
                fit: BoxFit.cover,
                placeholder: Images.placeholder,
              ),
            ),
            const SizedBox(height: 6),
            Text(store.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall)),
          ],
        ),
      ),
    );
  }
}

// ─── product card ────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final _CatProduct product;
  const _ProductCard({required this.product});

  String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount =
        product.discountedPrice > 0 && product.discountedPrice < product.price;
    return InkWell(
      onTap: () => Get.toNamed<void>(
          RouteHelper.getItemDetailsRoute(product.id, false)),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomImage(
                      image: product.image ?? '',
                      fit: BoxFit.cover,
                      placeholder: Images.placeholder,
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚡ ${_discountPct(product)}%',
                          style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: Color(0xFF121C19)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall)),
                  if ((product.storeName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(product.storeName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).hintColor)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        '${_money(hasDiscount ? product.discountedPrice : product.price)} ر.س',
                        style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: hasDiscount
                                ? const Color(0xFFD64545)
                                : const Color(0xFF121C19)),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          _money(product.price),
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).hintColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _discountPct(_CatProduct p) {
    if (p.price <= 0) return 0;
    return (((p.price - p.discountedPrice) / p.price) * 100).round();
  }
}

// ─── models ──────────────────────────────────────────────────────────────────

class _CatStore {
  final int? id;
  final String? name;
  final String? logo;
  final double rating;
  final int? moduleId;
  _CatStore(
      {this.id, this.name, this.logo, this.rating = 0, this.moduleId});

  factory _CatStore.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;
    return _CatStore(
      id: int.tryParse('${j['id'] ?? ''}'),
      name: j['name']?.toString(),
      logo: (j['logo_full_url'] ?? j['logo'] ?? j['image_full_url'])
          ?.toString(),
      rating: d(j['avg_rating'] ?? j['rating']),
      moduleId: int.tryParse('${j['module_id'] ?? ''}'),
    );
  }
}

class _CatProduct {
  final int? id;
  final String? name;
  final String? image;
  final String? storeName;
  final double price;
  final double discountedPrice;
  _CatProduct({
    this.id,
    this.name,
    this.image,
    this.storeName,
    this.price = 0,
    this.discountedPrice = 0,
  });

  factory _CatProduct.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;
    final double price = d(j['price']);
    final double discount = d(j['discount']);
    final String discountType = (j['discount_type'] ?? '').toString();
    double discounted = price;
    if (discount > 0) {
      discounted = discountType == 'percent'
          ? price - (price * discount / 100)
          : price - discount;
    }
    final images = j['image_full_url'];
    String? img;
    if (images is List && images.isNotEmpty) {
      img = images.first?.toString();
    } else if (images is String) {
      img = images;
    } else {
      img = (j['image'] ?? '').toString();
    }
    return _CatProduct(
      id: int.tryParse('${j['id'] ?? ''}'),
      name: j['name']?.toString(),
      image: img,
      storeName: j['store_name']?.toString(),
      price: price,
      discountedPrice: discounted,
    );
  }
}
