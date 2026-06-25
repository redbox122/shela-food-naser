import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/home/screens/home_search_screen.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_body.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_branded_header.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_cart_search_bar.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_header.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_models.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_tabs_bar.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// 🎨 REDESIGN (Market): store category / "Best Offers" screen.
///
/// Opened from a store's category tile (or the Best Offers tile). Loads
/// `GET /api/v2/stores/{store_id}/categories/{category_id}?limit=20`, which
/// returns `sub_categories` — each a second-bar tab carrying its own embedded
/// products (first page) plus `total_products`/`has_more`. Normal categories
/// and Best Offers share the same structure; only `is_discount_category` differs.
///
/// This screen owns the data + accent logic; the visual pieces live under
/// `widgets/market/offers/` (header, tabs bar, body, product card, models).
class MarketOffersScreen extends StatefulWidget {
  final String title;
  final int moduleId;

  /// Store the category belongs to (required for the store-scoped endpoints).
  final int? storeId;

  /// Category id within the store: a numeric id (as a string) or "offers".
  final String? categoryId;

  /// Store name + logo shown in the header (e.g. "الوليمة" / "سلوجان الشركة").
  final String? storeName;
  final String? storeLogo;

  /// Store cover image shown behind the header band (matches the design).
  final String? storeCover;

  /// When true the screen is opened from a store/section "see more" or logo tap:
  /// it shows a branded cover + logo + name header and ONLY the sub-category
  /// strip (no categories top bar). When false (a category tile tap) it shows
  /// the two-level categories + sub-categories browser.
  final bool brandedHeader;

  /// Products the caller already loaded (e.g. a featured-store section). Used as
  /// a fallback when the store-category fetch returns nothing: a cross-module
  /// featured store (a restaurant opened via "منتجات من متجر آخر") has no market
  /// "offers" category, so `/categories/offers` comes back empty even though the
  /// caller already holds the products to show.
  final List<OfferProduct> presetProducts;

  const MarketOffersScreen({
    super.key,
    this.title = '',
    this.moduleId = 3,
    this.storeId,
    this.categoryId,
    this.storeName,
    this.storeLogo,
    this.storeCover,
    this.brandedHeader = false,
    this.presetProducts = const [],
  });

  @override
  State<MarketOffersScreen> createState() => _MarketOffersScreenState();
}

class _MarketOffersScreenState extends State<MarketOffersScreen> {
  final ScrollController _scroll = ScrollController();

  // Two-level navigation: the green top bar lists the store's categories; the
  // tapped one's sub_categories become the white second bar AND the stacked
  // titled sections in the body. The second bar scrolls the body to a section.
  List<SubCat> _subs = const [];

  /// One GlobalKey per sub_category section, so the second-bar tabs can scroll
  /// the body to the matching section.
  List<GlobalKey> _sectionKeys = const [];
  int _selectedTab = 0;
  bool _loadingDetail = true;

  /// Top-bar store categories and the index of the selected (tapped) one.
  List<StoreCat> _cats = const [];
  int _selectedCat = 0;

  /// Second-bar labels: one per sub_category.
  List<String> get _tabLabels => _subs.map((s) => s.name).toList();

  /// Theme accent derived from the store logo (palette_generator); the brand's
  /// green band, tabs, pills, buttons and section titles all tint to it.
  Color _accent = const Color(0xFF1F7A35);

  /// Memoize the accent per logo URL so re-opening doesn't recompute it.
  static final Map<String, Color> _accentCache = {};

  /// CDN requires a User-Agent (see [CustomImage]); reuse it so the palette
  /// reads the same bytes as the rendered logo.
  static const Map<String, String> _cdnHeaders = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// Pale accent for the selected pill fill.
  Color get _accentPale => Color.lerp(_accent, Colors.white, 0.88)!;

  @override
  void initState() {
    super.initState();
    _resolveAccent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _resolveAccent() async {
    final url = widget.storeLogo;
    if (url == null || url.isEmpty) return;

    final cached = _accentCache[url];
    if (cached != null) {
      setState(() => _accent = cached);
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url, headers: _cdnHeaders),
        size: const Size(80, 80),
        maximumColorCount: 8,
      );
      final raw = palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.darkVibrantColor?.color ??
          palette.mutedColor?.color;
      if (raw == null || !mounted) return;
      final color = _readableDark(raw);
      _accentCache[url] = color;
      setState(() => _accent = color);
    } catch (_) {
      // Keep the green fallback on any failure.
    }
  }

  /// Darken a colour just enough that white text stays readable on top of it.
  Color _readableDark(Color c) {
    final hsl = HSLColor.fromColor(c);
    final l = hsl.lightness > 0.45 ? 0.40 : hsl.lightness;
    return hsl
        .withLightness(l)
        .withSaturation(hsl.saturation < 0.35 ? 0.35 : hsl.saturation)
        .toColor();
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
    // The branded (store "see more") mode has no categories top bar, so it only
    // needs the selected category's sub_categories.
    if (widget.brandedHeader) {
      await _fetchDetail(_initialCatId);
      return;
    }
    await Future.wait([_fetchCategories(), _fetchDetail(_initialCatId)]);
  }

  /// Load the store's full category list for the green top bar and preselect the
  /// category the screen was opened on.
  Future<void> _fetchCategories() async {
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
          : (body is Map && body['data'] is List)
              ? body['data'] as List
              : (body is Map && body['categories'] is List)
                  ? body['categories'] as List
                  : const [];
      final cats = raw
          .whereType<Map>()
          .map((e) => StoreCat.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      int idx = cats.indexWhere((c) => c.id == _initialCatId);
      if (idx < 0 && _initialCatId == 'offers') {
        idx = cats.indexWhere((c) => c.isDiscount);
      }
      setState(() {
        _cats = cats;
        _selectedCat = idx < 0 ? 0 : idx;
      });
    } catch (_) {
      // Top bar is optional; without it the screen still shows the second bar.
    }
  }

  /// Load one category's sub_categories (each carries its embedded products).
  /// One synthetic section wrapping the caller-supplied [presetProducts], used
  /// when the store-category fetch yields nothing (e.g. a cross-module featured
  /// store with no market "offers" category).
  List<SubCat> _presetSubs() => widget.presetProducts.isEmpty
      ? const []
      : [
          SubCat(
            id: 'all',
            name: widget.title,
            products: widget.presetProducts,
          ),
        ];

  void _applySubs(List<SubCat> subs) {
    _subs = subs;
    _sectionKeys = List.generate(subs.length, (_) => GlobalKey());
    _selectedTab = 0;
    _loadingDetail = false;
  }

  Future<void> _fetchDetail(String catId) async {
    final api = _api;
    if (api == null || widget.storeId == null) {
      if (mounted) setState(() => _applySubs(_presetSubs()));
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
          .map((e) => SubCat.fromJson(Map<String, dynamic>.from(e)))
          .where((s) => s.products.isNotEmpty)
          .toList();
      // Fall back to the caller's products when the category has nothing.
      setState(() => _applySubs(subs.isNotEmpty ? subs : _presetSubs()));
    } catch (_) {
      if (mounted) setState(() => _applySubs(_presetSubs()));
    }
  }

  /// Tapping a sub_category tab scrolls the body to its titled section.
  void _onTabTap(int i) {
    setState(() => _selectedTab = i);
    final ctx = (i >= 0 && i < _sectionKeys.length)
        ? _sectionKeys[i].currentContext
        : null;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    } else if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  /// Tapping a top-bar category loads its sub_categories (Best Offers uses the
  /// "offers" id; every other category uses its own id).
  void _onCatTap(int i) {
    if (i == _selectedCat) return;
    setState(() => _selectedCat = i);
    final c = _cats[i];
    _fetchDetail(c.isDiscount ? 'offers' : c.id);
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
        // Branded store "see more" → clean white background (no grey). The
        // category browser keeps the subtle grey to separate its sections.
        backgroundColor:
            widget.brandedHeader ? Colors.white : const Color(0xFFF5F6F8),
        body: Stack(
          children: [
            Column(
              children: [
                // Branded (store "see more"/logo) → cover + logo + name header,
                // no categories top bar. Otherwise → solid accent band with the
                // store-categories top bar.
                if (widget.brandedHeader)
                  MarketOffersBrandedHeader(
                    accent: _accent,
                    cover: widget.storeCover,
                    logo: widget.storeLogo,
                    name: widget.storeName ?? widget.title,
                    slogan: widget.title,
                    onBack: () => Get.back<void>(),
                    onSearch: () => Get.to<void>(() => HomeSearchScreen(
                        storeId: widget.storeId, moduleId: widget.moduleId)),
                  )
                else
                  MarketOffersHeader(
                    accent: _accent,
                    cats: _cats,
                    selectedCat: _selectedCat,
                    onBack: () => Get.back<void>(),
                    onCatTap: _onCatTap,
                  ),
                // Single filter row: "كل المنتجات" + sub_category pills.
                if (!_loadingDetail && _subs.isNotEmpty)
                  MarketOffersTabsBar(
                    labels: _tabLabels,
                    selectedTab: _selectedTab,
                    // Fixed brand green for the selected pill's text — the
                    // category chips are not tinted by the store logo.
                    accent: const Color(0xFF1F7A35),
                    accentPale: _accentPale,
                    onTabTap: _onTabTap,
                  ),
                Expanded(
                  child: MarketOffersBody(
                    loading: _loadingDetail,
                    subs: _subs,
                    sectionKeys: _sectionKeys,
                    scrollController: _scroll,
                    accent: _accent,
                    storeId: widget.storeId,
                    moduleId: widget.moduleId,
                  ),
                ),
              ],
            ),
            // Floating cart half-pill, flush to the screen's right edge — cart
            // only (no search; the header already carries search).
            Positioned(
              right: 0,
              bottom: 120,
              child: CartFab(
                accent: _accent,
                showSearch: false,
                onSearch: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
