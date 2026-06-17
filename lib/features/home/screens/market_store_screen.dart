import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/home/screens/home_search_screen.dart';
import 'package:sixam_mart/features/home/screens/market_offers_screen.dart';
import 'package:sixam_mart/features/home/screens/market_product_screen.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 REDESIGN (Market): grocery store detail screen opened when tapping a
/// store card in the market.
///
/// Wired to `GET /api/v2/stores/{store_id}`, which returns the whole page:
/// header, categories, one category's products, and two featured product
/// sections (each with its own slogan/logo). The header renders instantly from
/// the values carried by the tapped card while the rest loads.
class MarketStoreScreen extends StatefulWidget {
  final int? storeId;

  /// Module the store belongs to. Defaults to the market (3), but featured
  /// "other store" sections open this screen for a store in another module.
  final int moduleId;
  final String? name;
  final String? logo;
  final String? cover;
  final double rating;
  final bool freeDelivery;
  final String? deliveryTime;

  const MarketStoreScreen({
    super.key,
    required this.storeId,
    this.moduleId = _marketModuleId,
    this.name,
    this.logo,
    this.cover,
    this.rating = 0,
    this.freeDelivery = false,
    this.deliveryTime,
  });

  @override
  State<MarketStoreScreen> createState() => _MarketStoreScreenState();
}

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

  _Product({
    this.id,
    this.name,
    this.image,
    this.price = 0,
    this.originalPrice = 0,
    this.discountedPrice = 0,
  });

  static double _d(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  factory _Product.fromJson(Map<String, dynamic> j) => _Product(
        id: int.tryParse('${j['id']}'),
        name: j['name']?.toString(),
        image: (j['full_image_url'] ?? j['image_full_url'])?.toString(),
        price: _d(j['price']),
        originalPrice: _d(j['original_price']),
        discountedPrice: _d(j['discounted_price']),
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
    final bool ok = await cartController.addToCartOnline(cart);
    if (!ok) {
      showCustomSnackBar('failed_to_add_to_cart'.tr, isError: true);
    }
  } catch (e) {
    showCustomSnackBar(e.toString(), isError: true);
  }
}

class _FeaturedSection {
  final int? storeId;

  /// Module of the featured store — its products live in this module, not
  /// necessarily the market (3), so opening their details must use it.
  final int? moduleId;
  final String? logo;
  final String? slogan;
  final List<_Product> products;
  _FeaturedSection(
      {this.storeId,
      this.moduleId,
      this.logo,
      this.slogan,
      this.products = const []});

  factory _FeaturedSection.fromJson(Map<String, dynamic> j) => _FeaturedSection(
        storeId: int.tryParse('${j['store_id']}'),
        moduleId: int.tryParse('${j['module_id']}'),
        logo: j['logo_url']?.toString(),
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

// ─── Screen ──────────────────────────────────────────────────────────────────

class _MarketStoreScreenState extends State<MarketStoreScreen> {
  _StoreDetail? _detail;

  /// Full category list from `/stores/{id}/categories` (falls back to the
  /// subset embedded in the main detail response).
  List<_Category> _categories = const [];
  bool _loading = true;
  int? _selectedCategoryId;

  List<_Category> get _resolvedCategories =>
      _categories.isNotEmpty ? _categories : (_detail?.categories ?? const []);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (widget.storeId == null || !Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final api = Get.find<ApiClient>();
    final headers = {
      AppConstants.localizationKey: 'ar',
      AppConstants.moduleId: widget.moduleId.toString(),
    };
    final id = widget.storeId;
    try {
      // Fetch the page detail and the full category list together.
      final results = await Future.wait([
        api.getData('/api/v2/stores/$id', headers: headers, useEtag: false),
        api.getData('/api/v2/stores/$id/categories',
            headers: headers, useEtag: false),
      ]);
      if (!mounted) return;
      final dynamic detailBody = results[0].body;
      final dynamic catBody = results[1].body;
      final List rawCats = catBody is List
          ? catBody
          : (catBody is Map && catBody['data'] is List)
              ? catBody['data'] as List
              : (catBody is Map && catBody['categories'] is List)
                  ? catBody['categories'] as List
                  : const [];
      setState(() {
        _detail = detailBody is Map
            ? _StoreDetail.fromJson(Map<String, dynamic>.from(detailBody))
            : null;
        _categories = rawCats
            .whereType<Map>()
            .map((e) => _Category.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header — uses fetched data, falling back to the tapped card values.
          SliverToBoxAdapter(
            child: _StoreHeader(
              name: d?.name ?? widget.name,
              logo: d?.logo ?? widget.logo,
              cover: d?.cover ?? widget.cover,
              description: d?.description,
              rating: d?.rating ?? widget.rating,
              freeDelivery: d?.freeDelivery ?? widget.freeDelivery,
              deliveryTime: d?.deliveryTime ?? widget.deliveryTime,
            ),
          ),

          if (_loading)
            const SliverToBoxAdapter(child: _BodySkeleton())
          else if (d != null) ...[
            // Categories grid (full list from /categories, else inline subset).
            if (_resolvedCategories.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoriesGrid(
                  categories: _resolvedCategories,
                  storeId: widget.storeId,
                  moduleId: widget.moduleId,
                ),
              ),

            // Sticky category filter chips.
            if (_resolvedCategories.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoryChips(
                  categories: _resolvedCategories,
                  selectedId: _selectedCategoryId,
                  onSelect: (id) => setState(() => _selectedCategoryId = id),
                ),
              ),

            // Selected category's products.
            if (d.categoryProducts.isNotEmpty)
              SliverToBoxAdapter(
                child: _ProductSection(
                  title: d.categoryName ?? '',
                  products: d.categoryProducts,
                  storeId: widget.storeId,
                  moduleId: widget.moduleId,
                  categoryId: d.categoryId,
                ),
              ),

            // Featured discounted products (with slogan + logo).
            if (d.discounted != null && d.discounted!.products.isNotEmpty)
              SliverToBoxAdapter(
                  child: _FeaturedSectionView(section: d.discounted!)),

            // Featured products from another store.
            if (d.featured != null && d.featured!.products.isNotEmpty)
              SliverToBoxAdapter(
                  child: _FeaturedSectionView(section: d.featured!)),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: Dimensions.paddingSizeLarge),
          ),
        ],
          ),
          // Cart tab docked to the right edge (rounded on the left only).
          const Positioned(
            right: 0,
            bottom: 24,
            child: _StoreCartFab(),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _StoreHeader extends StatelessWidget {
  final String? name;
  final String? logo;
  final String? cover;
  final String? description;
  final double rating;
  final bool freeDelivery;
  final String? deliveryTime;

  const _StoreHeader({
    this.name,
    this.logo,
    this.cover,
    this.description,
    this.rating = 0,
    this.freeDelivery = false,
    this.deliveryTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CustomImage(
              image: cover ?? '',
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              placeholder: Images.placeholder,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        image: Images.arrow_back_ios_new,
                        onTap: () => Get.back<void>(),
                      ),
                      const Spacer(),
                      _CircleIconButton(
                        image: Images.heart_v2,
                        onTap: () {},
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      _CircleIconButton(
                        image: Images.search_v2,
                        onTap: () =>
                            Get.to<void>(() => const HomeSearchScreen()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Delivery + time pills centered at the bottom of the cover.
            Positioned(
              left: 0,
              right: 0,
              bottom: Dimensions.paddingSizeSmall,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (freeDelivery) ...[
                    _CoverPill(
                      image: Images.truck_delivery_v2,
                      label: 'free_delivery'.tr,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                  ],
                  if (deliveryTime != null && deliveryTime!.isNotEmpty)
                    _CoverPill(
                      image: Images.time_v2,
                      label: deliveryTime!,
                    ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
            0,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomImage(
                    image: logo ?? '',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: Images.placeholder,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1.3,
                        color: Color(0xFF121C19),
                      ),
                    ),
                    if ((description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.3,
                          color: Color(0xFF717885),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Rating badge sits on the left (RTL), aligned with the name.
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _RatingBadge(rating: rating),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Categories grid ─────────────────────────────────────────────────────────

class _CategoriesGrid extends StatefulWidget {
  final List<_Category> categories;
  final int? storeId;
  final int moduleId;
  const _CategoriesGrid(
      {required this.categories,
      this.storeId,
      this.moduleId = _marketModuleId});

  /// Collapsed preview shows this many categories + a "view more" tile (= 8).
  static const int _previewCount = 7;

  @override
  State<_CategoriesGrid> createState() => _CategoriesGridState();
}

class _CategoriesGridState extends State<_CategoriesGrid> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cats = widget.categories;

    // Expanded: full vertical 3-column grid (all categories).
    if (_expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          itemCount: cats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (_, i) => _CategoryTile(
            category: cats[i],
            index: i,
            storeId: widget.storeId,
            moduleId: widget.moduleId,
          ),
        ),
      );
    }

    // Collapsed: two fixed rows scrolling horizontally; 7 cats + view-more.
    final bool hasMore = cats.length > _CategoriesGrid._previewCount;
    final int previewLen =
        hasMore ? _CategoriesGrid._previewCount : cats.length;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: SizedBox(
        height: 200,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          itemCount: previewLen + (hasMore ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (_, i) {
            if (hasMore && i == previewLen) {
              return _ViewMoreCategoryTile(
                index: previewLen,
                onTap: () => setState(() => _expanded = true),
              );
            }
            return _CategoryTile(
              category: cats[i],
              index: i,
              storeId: widget.storeId,
              moduleId: widget.moduleId,
            );
          },
        ),
      ),
    );
  }
}

/// Category-tile-sized "اطّلع على المزيد" tile that expands the grid.
/// Uses the same back_N artwork as the surrounding category tiles.
class _ViewMoreCategoryTile extends StatelessWidget {
  final VoidCallback onTap;
  final int index;
  const _ViewMoreCategoryTile({required this.onTap, required this.index});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    final String bg =
        Images.categoryBackgrounds[index % Images.categoryBackgrounds.length];
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            image: DecorationImage(
              image: AssetImage(bg),
              fit: BoxFit.cover,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'see_more'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                  color: Color(0xFF1F7A35),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(Icons.arrow_back, size: 18, color: Color(0xFF1F7A35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final int index;
  final int? storeId;
  final int moduleId;
  const _CategoryTile(
      {required this.category,
      required this.index,
      this.storeId,
      this.moduleId = _marketModuleId});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    final String bg =
        Images.categoryBackgrounds[index % Images.categoryBackgrounds.length];
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.to<void>(
          () => MarketOffersScreen(
            title: category.name ?? '',
            storeId: storeId,
            moduleId: moduleId,
            categoryId: category.rawId,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            image: DecorationImage(
              image: AssetImage(bg),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Category product image (56×56) centered at the bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Center(
                  child: CustomImage(
                    image: category.image ?? '',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                    placeholder: Images.placeholder,
                  ),
                ),
              ),
              // Name at the top, centered.
              Positioned(
                top: 8,
                right: 6,
                left: 6,
                child: Text(
                  category.name ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.0,
                    color: Color(0xFF30913F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category chips ──────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<_Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = categories[i];
          final bool selected = c.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(selected ? null : c.id),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEBFEEB),
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: const Color(0xFF1F7A35), width: 2)
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(8),
              child: CustomImage(
                image: c.image ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                placeholder: Images.placeholder,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Product sections ────────────────────────────────────────────────────────

class _ProductSection extends StatelessWidget {
  final String title;
  final List<_Product> products;
  final int? storeId;
  final int moduleId;

  /// Category id for the "see more" stacked screen (null → see-all grid).
  final String? categoryId;
  const _ProductSection(
      {required this.title,
      required this.products,
      this.storeId,
      this.moduleId = _marketModuleId,
      this.categoryId});

  @override
  Widget build(BuildContext context) {
    // Card with a green slogan-style header (matches the featured sections,
    // minus the protruding logo).
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFBF1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFCDEBD6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFF57D06C),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                title,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _ProductRail(
                products: products,
                title: title,
                storeId: storeId,
                moduleId: moduleId,
                viewMoreCategoryId: categoryId),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],
        ),
      ),
    );
  }
}

/// Featured section: a coloured header band with the store logo + slogan, then
/// the product rail.
class _FeaturedSectionView extends StatelessWidget {
  final _FeaturedSection section;
  const _FeaturedSectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Extra top room so the logo can protrude above the card.
      padding: const EdgeInsets.only(
        top: 20,
        bottom: Dimensions.paddingSizeSmall,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card: green slogan header + product rail.
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFBF1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFCDEBD6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Green slogan header (right padding leaves room for the logo).
                Container(
                  color: const Color(0xFF1F7A35),
                  padding: const EdgeInsets.fromLTRB(12, 12, 84, 12),
                  child: Text(
                    section.slogan ?? '',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                _ProductRail(
                  products: section.products,
                  title: section.slogan ?? '',
                  storeId: section.storeId,
                  viewMoreCategoryId: 'offers',
                  moduleId: section.moduleId ?? _marketModuleId,
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ],
            ),
          ),
          // Logo (65×63, white 2px border) protruding at the top-right.
          Positioned(
            top: -16,
            right: Dimensions.paddingSizeDefault + 12,
            child: Container(
              width: 65,
              height: 63,
              decoration: BoxDecoration(
                color: const Color(0xFF1F7A35),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomImage(
                image: section.logo ?? '',
                width: 65,
                height: 63,
                fit: BoxFit.contain,
                placeholder: Images.placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRail extends StatelessWidget {
  final List<_Product> products;

  /// Title for the "see all" grid page opened from the view-more tile.
  final String title;
  final int? storeId;

  /// When set, "see more" opens the stacked category screen for this category
  /// id ("offers" for featured sections, else the section's category). Falls
  /// back to the plain see-all grid when null.
  final String? viewMoreCategoryId;

  /// Module the products belong to (featured sections may be cross-module).
  final int moduleId;
  const _ProductRail({
    required this.products,
    this.title = '',
    this.storeId,
    this.viewMoreCategoryId,
    this.moduleId = _marketModuleId,
  });

  /// Show at most this many products before the "view more" tile.
  static const int _maxVisible = 4;

  @override
  Widget build(BuildContext context) {
    final bool showMore = products.length > _maxVisible;
    // Leave a slot for the "view more" tile when there are extra products.
    final int cardCount = showMore ? _maxVisible - 1 : _maxVisible;
    final visible = products.take(cardCount).toList();

    final children = <Widget>[];
    for (int i = 0; i < visible.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 8));
      children.add(
        Expanded(
          child: _ProductCard(
            product: visible[i],
            storeId: storeId,
            moduleId: moduleId,
          ),
        ),
      );
    }
    if (showMore) {
      children.add(const SizedBox(width: 8));
      children.add(
        _ViewMoreTile(
          onTap: () => Get.to<void>(
            () => viewMoreCategoryId != null
                ? MarketOffersScreen(
                    title: title,
                    storeId: storeId,
                    moduleId: moduleId,
                    categoryId: viewMoreCategoryId)
                : _SeeAllProductsScreen(
                    title: title, products: products, storeId: storeId),
          ),
        ),
      );
    }

    return SizedBox(
      height: 116,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        child: Row(children: children),
      ),
    );
  }
}

/// Trailing "عرض المزيد" tile at the end of a product rail.
class _ViewMoreTile extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewMoreTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusDefault);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFEBFEEB),
          borderRadius: radius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vertical (rotated) label.
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                'see_more'.tr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFF1F7A35),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Icon(Icons.arrow_downward,
                size: 16, color: Color(0xFF1F7A35)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final int? storeId;
  final int moduleId;
  const _ProductCard({
    required this.product,
    this.storeId,
    this.moduleId = _marketModuleId,
  });

  static const double _imageHeight = 52;

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    return GestureDetector(
      onTap: () => MarketProductScreen.show(
        itemId: product.id ?? 0,
        storeId: storeId,
        moduleId: moduleId,
      ),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFEFEFF1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with the "+" button anchored at its bottom-left.
          Stack(
            children: [
              CustomImage(
                image: product.image ?? '',
                width: double.infinity,
                height: _imageHeight,
                fit: BoxFit.cover,
                placeholder: Images.placeholder,
              ),
              Positioned(
                left: 5,
                bottom: 5,
                child: _AddButton(
                  onTap: () =>
                      _addProductToCart(product, storeId, moduleId: moduleId),
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
                  // Price (struck original under the discounted price).
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      _price(product.shownPrice, bold: true),
                      if (product.hasDiscount)
                        _price(product.originalPrice, struck: true),
                    ],
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

  Widget _price(double value, {bool bold = false, bool struck = false}) {
    final color = struck ? const Color(0xFF9AA0A6) : const Color(0xFF121C19);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.sar,
            width: struck ? 8 : 10,
            height: struck ? 8 : 10,
            color: color,
            errorBuilder: (_, __, ___) => Text('﷼',
                style: robotoBold.copyWith(fontSize: 9, color: color)),
          ),
          const SizedBox(width: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: struck ? 9 : 11,
              decoration:
                  struck ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: const Color(0xFFE53935),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD1FDD2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.add, size: 18, color: Color(0xFF1F7A35)),
        ),
      ),
    );
  }
}

// ─── Shared bits ─────────────────────────────────────────────────────────────

/// White pill overlaid on the cover (delivery / time).
class _CoverPill extends StatelessWidget {
  final String image;
  final String label;
  const _CoverPill({required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // Translucent near-white — hsba(260, 1%, 97%, 0.8).
        color: const Color.fromRGBO(246, 245, 247, 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            image,
            width: 14,
            height: 14,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Color(0xFF121C19),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green rating badge with diagonal corners (top-right + bottom-left rounded).
class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF1F7A35),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star, size: 14, color: Colors.white),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final String image;
  final VoidCallback onTap;
  const _CircleIconButton({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(image, width: 20, height: 20),
        ),
      ),
    );
  }
}

class _BodySkeleton extends StatelessWidget {
  const _BodySkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      highlightColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: List.generate(
                8,
                (_) => Container(
                  width: 56,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 132,
                    height: 150,
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
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

// ─── See-all products grid ────────────────────────────────────────────────────

/// Full grid of a section's products, opened from a rail's "view more" tile.
class _SeeAllProductsScreen extends StatelessWidget {
  final String title;
  final List<_Product> products;
  final int? storeId;
  const _SeeAllProductsScreen(
      {required this.title, required this.products, this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Green header band: back chevron (RTL right) + centered title.
            Container(
              color: const Color(0xFF1F7A35),
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
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  // 104×130 design card.
                  childAspectRatio: 104 / 130,
                ),
                itemBuilder: (_, i) =>
                    _GridProductCard(product: products[i], storeId: storeId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact product card (≈104×130) for the see-all grid: image with a red
/// discount badge + add button, then name and price.
class _GridProductCard extends StatelessWidget {
  final _Product product;
  final int? storeId;
  const _GridProductCard({required this.product, this.storeId});

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFEFEFF1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image + discount badge (top-right) + add button (bottom-left).
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(6),
                      ),
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
                child: _AddButton(
                  onTap: () => _addProductToCart(product, storeId),
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
                  if (product.hasDiscount)
                    _price(product.originalPrice, struck: true),
                ],
              ),
            ),
          ),
        ],
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

/// Floating cart button shown once the cart has items; opens the cart screen.
class _StoreCartFab extends StatelessWidget {
  const _StoreCartFab();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(56),
      bottomLeft: Radius.circular(56),
    );
    return GetBuilder<CartController>(
      builder: (cartController) {
        final int count = cartController.cartList.length;
        if (count == 0) return const SizedBox.shrink();
        return Material(
          color: const Color(0xFF30913F),
          elevation: 6,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
            child: SizedBox(
              width: 88,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 26, color: Colors.white),
                  Positioned(
                    top: 8,
                    right: 22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
