// Kept-but-unused helper tiles (_ViewMoreTile / _SeeAllProductsScreen) retain
// their params for later reuse.
// ignore_for_file: unused_element_parameter, unused_element
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/dashboard/widgets/home_bottom_nav_bar.dart';
import 'package:sixam_mart/features/home/widgets/home_top_notice_strip.dart';
import 'package:sixam_mart/features/home/widgets/market/market_banner_section.dart';
import 'package:sixam_mart/features/home/screens/home_search_screen.dart';
import 'package:sixam_mart/features/home/screens/market_offers_screen.dart';
import 'package:sixam_mart/features/home/screens/market_product_screen.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_models.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

// 🧩 Split into part files to keep this screen manageable while the many
// private widgets/helpers/models stay shared in one library.
part 'market_store_screen_models.dart';
part 'market_store_screen_chrome.dart';
part 'market_store_screen_categories.dart';
part 'market_store_screen_products.dart';
part 'market_store_screen_extras.dart';
part 'market_store_screen_options.dart';
part 'market_store_screen_hyper.dart';

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

  /// Distance to this store in **metres** (0 = unknown, badge hidden).
  final double distance;

  /// When true, this is the special "هايبر ماركت شله" storefront: it shows the
  /// fixed "هايبر ماركت شله" title + the promotional banner. For every other
  /// store (opened from أسواق الحي, brands, etc.) this stays false, so the
  /// header shows the real store name and the banner is hidden.
  final bool isHyperStorefront;

  /// When true, use the cover-image header (cover + back/heart/search + delivery
  /// pill + rating + name + description) instead of the plain title bar, and
  /// hide the address notice strip. Enabled only for stores opened from
  /// أسواق الحي so other screens stay unchanged.
  final bool useCoverHeader;

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
    this.distance = 0,
    this.isHyperStorefront = false,
    this.useCoverHeader = false,
  });

  @override
  State<MarketStoreScreen> createState() => _MarketStoreScreenState();
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class _MarketStoreScreenState extends State<MarketStoreScreen> {
  _StoreDetail? _detail;
  int? _storeModuleId;
  List<_Category> _categories = const [];
  bool _loading = true;
  int _activeTab = 0;

  // Single scroll controller for the whole product area.
  final ScrollController _scrollCtrl = ScrollController();
  final ScrollController _tabScrollCtrl = ScrollController();

  // Key on the CustomScrollView so we can localToGlobal section positions.
  final GlobalKey _scrollViewKey = GlobalKey();

  // One key per category section header (the Column with title + rail).
  List<GlobalKey> _sectionKeys = [];

  static const double _tabBarH = 48.0;

  List<_Category> get _resolvedCategories {
    final base =
        _categories.isNotEmpty ? _categories : (_detail?.categories ?? const []);
    return base
        .where((c) => !c.isDiscount && c.rawId.toLowerCase() != 'offers')
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _tabScrollCtrl.dispose();
    super.dispose();
  }

  // ── Scroll-spy ──────────────────────────────────────────────────────────────

  void _onScroll() {
    if (_sectionKeys.isEmpty || !_scrollCtrl.hasClients) return;
    final scrollBox = _scrollViewKey.currentContext?.findRenderObject();
    if (scrollBox is! RenderBox) return;

    int newActive = 0;
    for (int i = 0; i < _sectionKeys.length; i++) {
      final box = _sectionKeys[i].currentContext?.findRenderObject();
      if (box is! RenderBox) continue;
      // dy = visual Y of the section header within the scroll view's frame.
      final dy = box.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      if (dy <= _tabBarH + 2) {
        newActive = i;
      } else {
        break; // sections are in order; stop when one is still below the bar.
      }
    }

    if (newActive != _activeTab) {
      setState(() => _activeTab = newActive);
      _scrollTabIntoView(newActive);
    }
  }

  void _scrollTabIntoView(int i) {
    if (!_tabScrollCtrl.hasClients) return;
    const double estTabW = 100.0;
    final double maxExt = _tabScrollCtrl.position.maxScrollExtent;
    if (maxExt <= 0) return;
    final double viewport = _tabScrollCtrl.position.viewportDimension;
    final double target =
        (i * estTabW - viewport / 2 + estTabW / 2).clamp(0.0, maxExt);
    _tabScrollCtrl.animateTo(target,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  // ── Tab tap → animated scroll to that section ───────────────────────────────

  void _onTabTap(int i) {
    setState(() => _activeTab = i);
    _scrollTabIntoView(i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients || i >= _sectionKeys.length) return;
      final scrollBox = _scrollViewKey.currentContext?.findRenderObject();
      if (scrollBox is! RenderBox) return;
      final box = _sectionKeys[i].currentContext?.findRenderObject();
      if (box is! RenderBox) return;
      // Current visual dy of the section → compute target scroll offset.
      final dy = box.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      final target = (_scrollCtrl.offset + dy - _tabBarH)
          .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
      _scrollCtrl.animateTo(target,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    });
  }

  // ── Data fetch ──────────────────────────────────────────────────────────────

  void _initSectionKeys(int n) {
    if (_sectionKeys.length == n) return;
    _sectionKeys = List.generate(n, (i) => GlobalKey(debugLabel: 'sec_$i'));
  }

  // Cache keys for this store's header + categories (stale-while-revalidate).
  String get _cacheKey => 'mss_${widget.moduleId}_${widget.storeId}';

  /// Parses a raw categories payload (list / {data} / {categories}) into models.
  List<_Category> _parseCats(dynamic catBody) {
    final List rawCats = catBody is List
        ? catBody
        : (catBody is Map && catBody['data'] is List)
            ? catBody['data'] as List
            : (catBody is Map && catBody['categories'] is List)
                ? catBody['categories'] as List
                : const [];
    return rawCats
        .whereType<Map>()
        .map((e) => _Category.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Shows cached header + categories instantly (no white screen on repeat
  /// visits), then revalidates from the network in the background.
  Future<void> _fetch() async {
    if (widget.storeId == null || !Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final api = Get.find<ApiClient>();
    final prefs = api.sharedPreferences;

    // ── 1) Instant paint from cache (if any).
    try {
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        final cats = _parseCats(map['categories']);
        if (mounted && cats.isNotEmpty) {
          setState(() {
            _categories = cats;
            _detail = map['detail'] is Map
                ? _StoreDetail.fromJson(
                    Map<String, dynamic>.from(map['detail'] as Map))
                : _detail;
            _storeModuleId = map['module'] as int? ?? _storeModuleId;
            _loading = false; // reveal the screen immediately
          });
          _initSectionKeys(_resolvedCategories.length);
        }
      }
    } catch (_) {/* ignore corrupt cache */}

    // ── 2) Revalidate from the network.
    final headers = {
      AppConstants.localizationKey: 'ar',
      AppConstants.moduleId: widget.moduleId.toString(),
    };
    final id = widget.storeId;
    try {
      final results = await Future.wait([
        api.getData('/api/v2/stores/$id', headers: headers, useEtag: false),
        api.getData('/api/v2/stores/$id/categories',
            headers: headers, useEtag: false),
        api.getData('/api/v1/stores/details/$id',
            headers: headers, useEtag: false),
      ]);
      if (!mounted) return;
      final dynamic detailBody = results[0].body;
      final dynamic catBody = results[1].body;
      final dynamic v1Body = results[2].body;
      final int? storeModule =
          v1Body is Map ? int.tryParse('${v1Body['module_id']}') : null;
      final List<_Category> parsed = _parseCats(catBody);
      setState(() {
        _detail = detailBody is Map
            ? _StoreDetail.fromJson(Map<String, dynamic>.from(detailBody))
            : _detail;
        if (parsed.isNotEmpty) _categories = parsed;
        _storeModuleId = storeModule ?? _storeModuleId;
        _loading = false;
      });
      _initSectionKeys(_resolvedCategories.length);

      // ── 3) Persist for next time.
      try {
        await prefs.setString(
            _cacheKey,
            jsonEncode({
              'categories': catBody,
              'detail': detailBody is Map ? detailBody : null,
              'module': storeModule,
            }));
      } catch (_) {/* non-fatal */}
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final cats = _resolvedCategories;
    final int sel = cats.isEmpty ? 0 : _activeTab.clamp(0, cats.length - 1);
    final int effectiveModule = _storeModuleId ?? widget.moduleId;
    final String title = widget.isHyperStorefront
        ? 'hyper_market_shella'.tr
        : (d?.name ?? widget.name ?? '');

    if (!_loading) _initSectionKeys(cats.length);

    // Slivers for the CustomScrollView body.
    List<Widget> slivers = [];

    // Cover-store header scrolls away as first sliver (both cases).
    if (widget.useCoverHeader) {
      slivers.add(SliverToBoxAdapter(
        child: _StoreCoverPanel(
          logo: d?.logo ?? widget.logo,
          cover: d?.cover ?? widget.cover,
          description: d?.description,
          rating: d?.rating ?? widget.rating,
          freeDelivery: d?.freeDelivery ?? widget.freeDelivery,
          deliveryTime: d?.deliveryTime ?? widget.deliveryTime,
          distance: (d?.distance != null && d!.distance! > 0)
              ? d.distance
              : (widget.distance > 0 ? widget.distance : null),
        ),
      ));
    }

    // ── Hyper Shela browse block (design ported from the old shop_home): the
    // "الأقسام" green-card grid, the "العلامات التجارية" brand circles, and the
    // "عروض وخصومات" promo banner — shown above the product tabs, only for the
    // هايبر شله storefront, over this store's own (new-app) data.
    if (widget.isHyperStorefront && !_loading) {
      if (cats.isNotEmpty) {
        slivers.add(SliverToBoxAdapter(
          child: _HyperSectionHeader(title: 'sections'.tr),
        ));
        slivers.add(SliverToBoxAdapter(
          // Old shop_home "الأقسام" look: two-row horizontal rail of compact
          // green-name-over-image cards (see _HyperCategoriesRail).
          child: _HyperCategoriesRail(
            categories: cats,
            storeId: widget.storeId,
            moduleId: effectiveModule,
            storeCover: d?.cover ?? widget.cover,
          ),
        ));
      }
      slivers.add(SliverToBoxAdapter(
        child: _HyperBrandsRail(moduleId: widget.moduleId),
      ));
      slivers.add(SliverToBoxAdapter(
        child: _HyperSectionHeader(title: 'offers_and_discounts'.tr),
      ));
      slivers.add(SliverToBoxAdapter(
        child: MarketBannerSection(moduleId: widget.moduleId),
      ));
    }

    // Pinned tab bar — sticks once the cover (if any) scrolls away.
    if (!_loading && cats.isNotEmpty) {
      slivers.add(SliverPersistentHeader(
        pinned: true,
        delegate: _TabBarDelegate(
          categories: cats,
          activeIndex: sel,
          onTap: _onTabTap,
          tabScrollCtrl: _tabScrollCtrl,
        ),
      ));
    }

    // Category product sections.
    if (!_loading && cats.isNotEmpty) {
      for (int i = 0; i < cats.length; i++) {
        slivers.add(SliverToBoxAdapter(
          child: _CategorySection(
            key: _sectionKeys[i],
            category: cats[i],
            storeId: widget.storeId ?? 0,
            moduleId: effectiveModule,
            storeName: d?.name ?? widget.name,
            storeLogo: d?.logo ?? widget.logo,
            storeCover: d?.cover ?? widget.cover,
          ),
        ));
      }
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 60)));
    }

    final Widget scrollArea = _loading
        ? const SingleChildScrollView(child: _BodySkeleton())
        : CustomScrollView(
            key: _scrollViewKey,
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: slivers,
          );

    // Both cover and non-cover use the same slim fixed header at the top
    // (back button + store name + search). Only the area below differs:
    // cover stores show the cover panel as first scrollable sliver.
    return Scaffold(
      backgroundColor: Colors.white,
      // Sticky cart bar shows in EVERY store as soon as the cart has items, so
      // adding a product always surfaces the checkout bar. When the cart is
      // empty, cover-header stores show nothing while the rest keep their
      // bottom navigation.
      bottomNavigationBar: GetBuilder<CartController>(
        builder: (cart) {
          if (cart.cartList.isNotEmpty) {
            return _StoreStickyCartBar(
                freeDelivery: _detail?.freeDelivery ?? widget.freeDelivery);
          }
          return widget.useCoverHeader
              ? const SizedBox.shrink()
              : const _StoreBottomNav();
        },
      ),
      body: Column(
        children: [
          _MarketTopHeader(
            title: title,
            storeId: widget.storeId,
            moduleId: effectiveModule,
          ),
          // The هايبر شله promo banner moved into the scrollable "عروض وخصومات"
          // section below (see the browse block), so only the notice strip stays
          // fixed here.
          if (!widget.useCoverHeader) const HomeTopNoticeStrip(),
          Expanded(child: scrollArea),
        ],
      ),
    );
  }
}
