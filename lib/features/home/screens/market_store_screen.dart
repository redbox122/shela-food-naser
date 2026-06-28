// Kept-but-unused helper tiles (_ViewMoreTile / _SeeAllProductsScreen) retain
// their params for later reuse.
// ignore_for_file: unused_element_parameter, unused_element
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

  /// Key gives access to NestedScrollView's inner controller after build.
  final GlobalKey<NestedScrollViewState> _nestedKey = GlobalKey();

  /// One GlobalKey per category — used for scroll-to-section and scroll-spy.
  List<GlobalKey> _categoryKeys = [];

  /// Inner scroll controller cached so we can attach/detach the scroll-spy.
  ScrollController? _innerController;

  static const double _tabBarHeight = 46;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _innerController?.removeListener(_onInnerScroll);
    super.dispose();
  }

  void _attachScrollListener() {
    final inner = _nestedKey.currentState?.innerController;
    if (inner == null || inner == _innerController) return;
    _innerController?.removeListener(_onInnerScroll);
    _innerController = inner;
    _innerController!.addListener(_onInnerScroll);
  }

  void _onInnerScroll() {
    if (_categoryKeys.isEmpty) return;
    final inner = _innerController;
    if (inner == null || !inner.hasClients) return;
    final scrollBox = inner.position.context.notificationContext
        ?.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;
    int newActive = 0;
    for (int i = 0; i < _categoryKeys.length; i++) {
      final box =
          _categoryKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final y = inner.offset +
          box.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      if (y <= inner.offset + 48) {
        newActive = i;
      } else {
        break;
      }
    }
    if (newActive != _activeTab) setState(() => _activeTab = newActive);
  }

  void _selectTab(int i) {
    setState(() => _activeTab = i);
    if (i >= _categoryKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inner = _nestedKey.currentState?.innerController;
      if (inner == null || !inner.hasClients) return;
      final box =
          _categoryKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final scrollBox = inner.position.context.notificationContext
          ?.findRenderObject() as RenderBox?;
      if (scrollBox == null) return;
      final localY = box.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      final target =
          (inner.offset + localY).clamp(0.0, inner.position.maxScrollExtent);
      inner.animateTo(target,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    });
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
      final List rawCats = catBody is List
          ? catBody
          : (catBody is Map && catBody['data'] is List)
              ? catBody['data'] as List
              : (catBody is Map && catBody['categories'] is List)
                  ? catBody['categories'] as List
                  : const [];
      final List<_Category> parsed = rawCats
          .whereType<Map>()
          .map((e) => _Category.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _detail = detailBody is Map
            ? _StoreDetail.fromJson(Map<String, dynamic>.from(detailBody))
            : null;
        _categories = parsed;
        _categoryKeys = List.generate(parsed.length, (_) => GlobalKey());
        _storeModuleId = storeModule;
        _loading = false;
      });
      // Attach scroll-spy once NestedScrollView has built its inner controller.
      WidgetsBinding.instance.addPostFrameCallback((_) => _attachScrollListener());
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final cats = _resolvedCategories;
    final int sel = cats.isEmpty ? 0 : _activeTab.clamp(0, cats.length - 1);
    final int effectiveModule = _storeModuleId ?? widget.moduleId;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      bottomNavigationBar:
          widget.useCoverHeader ? null : const _StoreBottomNav(),
      body: Stack(
        children: [
          NestedScrollView(
            key: _nestedKey,
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (ctx, _) => _buildHeaderSlivers(
                d, cats, sel, effectiveModule),
            body: _buildBody(d, cats, sel, effectiveModule),
          ),
          if (widget.useCoverHeader)
            const Align(
              alignment: Alignment.centerRight,
              child: _StoreCartFab(),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildHeaderSlivers(
      _StoreDetail? d, List<_Category> cats, int sel, int effectiveModule) {
    return [
      if (widget.useCoverHeader)
        SliverToBoxAdapter(
          child: _StoreHeader(
            name: d?.name ?? widget.name,
            logo: d?.logo ?? widget.logo,
            cover: d?.cover ?? widget.cover,
            description: d?.description,
            rating: d?.rating ?? widget.rating,
            freeDelivery: d?.freeDelivery ?? widget.freeDelivery,
            deliveryTime: d?.deliveryTime ?? widget.deliveryTime,
            distance: (d?.distance != null && d!.distance! > 0)
                ? d.distance
                : (widget.distance > 0 ? widget.distance : null),
            storeId: widget.storeId,
            moduleId: effectiveModule,
          ),
        )
      else ...[
        SliverToBoxAdapter(
          child: _MarketTopHeader(
            title: widget.isHyperStorefront
                ? 'hyper_market_shella'.tr
                : (d?.name ?? widget.name ?? ''),
            storeId: widget.storeId,
            moduleId: effectiveModule,
          ),
        ),
        const SliverToBoxAdapter(child: HomeTopNoticeStrip()),
      ],
      if (widget.isHyperStorefront)
        SliverToBoxAdapter(
          child: MarketBannerSection(moduleId: widget.moduleId),
        ),
      if (!_loading && d != null) ...[
        if (cats.isNotEmpty && widget.isHyperStorefront)
          SliverToBoxAdapter(
            child: _CategoriesGrid(
              categories: cats,
              storeId: widget.storeId,
              moduleId: effectiveModule,
              storeCover: d.cover ?? widget.cover,
            ),
          ),
        // Pinned tab bar for non-hyper stores. NestedScrollView guarantees
        // the outer scroll can always travel the full header height, so the
        // tab bar reliably pins at the top even with a short product list.
        if (cats.isNotEmpty && !widget.isHyperStorefront)
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryTabsDelegate(
              categories: cats,
              activeIndex: sel,
              height: _tabBarHeight,
              onTap: _selectTab,
            ),
          ),
      ],
    ];
  }

  Widget _buildBody(
      _StoreDetail? d, List<_Category> cats, int sel, int effectiveModule) {
    if (_loading) {
      return const SingleChildScrollView(child: _BodySkeleton());
    }
    if (d == null) return const SizedBox.shrink();

    // Hyper market: all categories stacked (scrolled inside the body).
    if (widget.isHyperStorefront) {
      return CustomScrollView(
        slivers: [
          ...cats.map((cat) => SliverToBoxAdapter(
                child: _CategoryRail(
                  storeId: widget.storeId ?? 0,
                  moduleId: effectiveModule,
                  category: cat,
                  storeName: d.name ?? widget.name,
                  storeLogo: d.logo ?? widget.logo,
                  storeCover: d.cover ?? widget.cover,
                ),
              )),
          const SliverToBoxAdapter(
              child: SizedBox(height: Dimensions.paddingSizeLarge)),
        ],
      );
    }

    // Non-hyper: all categories stacked for continuous scroll.
    // GlobalKey on each SliverToBoxAdapter lets _selectTab scroll to the
    // right section and _onInnerScroll drive the active tab highlight.
    if (cats.isNotEmpty) {
      return CustomScrollView(
        slivers: [
          ...List.generate(cats.length, (i) => SliverToBoxAdapter(
            key: i < _categoryKeys.length ? _categoryKeys[i] : null,
            child: _CategoryRail(
              storeId: widget.storeId ?? 0,
              moduleId: effectiveModule,
              category: cats[i],
              storeName: d.name ?? widget.name,
              storeLogo: d.logo ?? widget.logo,
              storeCover: d.cover ?? widget.cover,
              hideSeeMore: true,
            ),
          )),
          const SliverToBoxAdapter(
              child: SizedBox(height: Dimensions.paddingSizeLarge)),
        ],
      );
    }

    // Fallback: no categories list — show the single embedded section.
    if (d.categoryProducts.isNotEmpty) {
      return SingleChildScrollView(
        child: _ProductSection(
          title: d.categoryName ?? '',
          products: d.categoryProducts,
          storeId: widget.storeId,
          moduleId: widget.moduleId,
          categoryId: d.categoryId,
          storeName: d.name ?? widget.name,
          storeLogo: d.logo ?? widget.logo,
          storeCover: d.cover ?? widget.cover,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
