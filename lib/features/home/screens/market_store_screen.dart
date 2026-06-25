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
    this.isHyperStorefront = false,
    this.useCoverHeader = false,
  });

  @override
  State<MarketStoreScreen> createState() => _MarketStoreScreenState();
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class _MarketStoreScreenState extends State<MarketStoreScreen> {
  _StoreDetail? _detail;

  /// The store's REAL module id (from /stores/details), used to fetch its items
  /// so they resolve regardless of which module was active when it was opened.
  int? _storeModuleId;

  /// Full category list from `/stores/{id}/categories` (falls back to the
  /// subset embedded in the main detail response).
  List<_Category> _categories = const [];
  bool _loading = true;

  /// Drives the sticky category tab bar: the selected tab shows that category's
  /// products below. A controller is kept so selecting a tab can snap the menu
  /// back to the top.
  final ScrollController _scrollController = ScrollController();
  int _activeTab = 0;

  /// Height of the pinned category tab bar.
  static const double _tabBarHeight = 46;

  List<_Category> get _resolvedCategories {
    final base =
        _categories.isNotEmpty ? _categories : (_detail?.categories ?? const []);
    // The backend now also returns the special "أفضل العروض" (id=offers,
    // is_discount_category) category in the list. The app already surfaces
    // offers on its own, so drop it here to avoid a duplicate grid tile.
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
    _scrollController.dispose();
    super.dispose();
  }

  /// Selects a category tab → shows that category's products below the pinned
  /// tabs.
  void _selectTab(int i) {
    if (i != _activeTab) setState(() => _activeTab = i);
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
      // Fetch the page detail, the full category list, and the store's real
      // module id together. /stores/details carries module_id (the v2 detail
      // does not), so items resolve no matter which module was active.
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
      setState(() {
        _detail = detailBody is Map
            ? _StoreDetail.fromJson(Map<String, dynamic>.from(detailBody))
            : null;
        _categories = rawCats
            .whereType<Map>()
            .map((e) => _Category.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _storeModuleId = storeModule;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final cats = _resolvedCategories;
    // Selected category index (clamped so it stays valid if the list shrinks).
    final int sel = cats.isEmpty ? 0 : _activeTab.clamp(0, cats.length - 1);
    // Prefer the store's real module (from /stores/details) for item fetches.
    final int effectiveModule = _storeModuleId ?? widget.moduleId;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      // أسواق الحي stores have no bottom nav (matches the design); other
      // stores keep it.
      bottomNavigationBar:
          widget.useCoverHeader ? null : const _StoreBottomNav(),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
          // أسواق الحي stores: cover-image header (cover + icons + delivery +
          // rating + name + description), no address notice strip.
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
                storeId: widget.storeId,
                moduleId: effectiveModule,
              ),
            )
          else ...[
            // Banner-style header: fixed "هايبر ماركت شله" title only for the
            // hyper storefront; every other store shows its real name.
            SliverToBoxAdapter(
              child: _MarketTopHeader(
                title: widget.isHyperStorefront
                    ? 'hyper_market_shella'.tr
                    : (d?.name ?? widget.name ?? ''),
                // Scope in-store search to this store's products only.
                storeId: widget.storeId,
                moduleId: widget.moduleId,
              ),
            ),
            const SliverToBoxAdapter(child: HomeTopNoticeStrip()),
          ],
          // Promotional banner belongs to the hyper storefront only.
          if (widget.isHyperStorefront)
            SliverToBoxAdapter(
              child: MarketBannerSection(moduleId: widget.moduleId),
            ),

          if (_loading)
            const SliverToBoxAdapter(child: _BodySkeleton())
          else if (d != null) ...[
            // Sticky category tab bar: pins under the header; tapping a tab
            // selects that category and shows its products below.
            if (cats.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryTabsDelegate(
                  categories: cats,
                  activeIndex: sel,
                  height: _tabBarHeight,
                  onTap: _selectTab,
                ),
              ),

            // Only the selected category's products are shown — navigate between
            // sections via the tabs. Keyed by category id so switching tabs
            // reloads that category's items. Falls back to the single inline
            // category section when the category list is empty.
            // Hyper market: browse every category section (scroll through the
            // whole store). Other stores: one category at a time via the tabs.
            if (cats.isNotEmpty && widget.isHyperStorefront)
              ...List.generate(
                cats.length,
                (i) => SliverToBoxAdapter(
                  child: _CategoryRail(
                    storeId: widget.storeId ?? 0,
                    moduleId: effectiveModule,
                    category: cats[i],
                    storeName: d.name ?? widget.name,
                    storeLogo: d.logo ?? widget.logo,
                    storeCover: d.cover ?? widget.cover,
                  ),
                ),
              )
            else if (cats.isNotEmpty)
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: ValueKey(cats[sel].rawId),
                  child: _CategoryRail(
                    storeId: widget.storeId ?? 0,
                    moduleId: effectiveModule,
                    category: cats[sel],
                    storeName: d.name ?? widget.name,
                    storeLogo: d.logo ?? widget.logo,
                    storeCover: d.cover ?? widget.cover,
                  ),
                ),
              )
            else if (d.categoryProducts.isNotEmpty)
              SliverToBoxAdapter(
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
              ),

            // "عروض مختارة لك" / "منتجات مقترحة لك" (cross-store featured
            // sections) removed per request.
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: Dimensions.paddingSizeLarge),
          ),
        ],
          ),
          // Floating cart tab (right edge), shown once the cart has items —
          // أسواق الحي stores only (they have no bottom nav).
          if (widget.useCoverHeader)
            const Align(
              alignment: Alignment.centerRight,
              child: _StoreCartFab(),
            ),
        ],
      ),
    );
  }
}
