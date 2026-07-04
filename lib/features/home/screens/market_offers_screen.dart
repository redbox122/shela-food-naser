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

enum _ViewMode { grid, list }
enum _SortOrder { none, nameAsc, nameDesc, popular }

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

// ─── Filter / view widgets ────────────────────────────────────────────────────

/// Row shown above the tabs bar: product count (right) + view toggles + filter
/// button (left, RTL).
class _OfferControlRow extends StatelessWidget {
  final int count;
  final _ViewMode viewMode;
  final bool hasFilter;
  final void Function(_ViewMode) onViewMode;
  final VoidCallback onFilter;

  const _OfferControlRow({
    required this.count,
    required this.viewMode,
    required this.hasFilter,
    required this.onViewMode,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          // Count label (rightmost in RTL → first child).
          Text(
            '$count منتجات',
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: Color(0xFF717885),
            ),
          ),
          const Spacer(),
          // Grid toggle.
          _iconBtn(
              Icons.grid_view_rounded, viewMode == _ViewMode.grid,
              () => onViewMode(_ViewMode.grid)),
          const SizedBox(width: 6),
          // List toggle.
          _iconBtn(
              Icons.view_agenda_outlined, viewMode == _ViewMode.list,
              () => onViewMode(_ViewMode.list)),
          const SizedBox(width: 6),
          // Filter button (leftmost in RTL → last child).
          GestureDetector(
            onTap: onFilter,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: hasFilter
                    ? const Color(0xFF1F7A35)
                    : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 18,
                color: hasFilter ? Colors.white : const Color(0xFF717885),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEBFEEB) : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? const Color(0xFF1F7A35) : const Color(0xFF717885),
        ),
      ),
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _OfferFilterSheet extends StatefulWidget {
  final _SortOrder sortOrder;
  final (double, double)? priceRange;
  final String? catFilter;
  final List<SubCat> subCats;
  final void Function(_SortOrder, (double, double)?, String?) onApply;

  const _OfferFilterSheet({
    required this.sortOrder,
    required this.priceRange,
    required this.catFilter,
    required this.subCats,
    required this.onApply,
  });

  @override
  State<_OfferFilterSheet> createState() => _OfferFilterSheetState();
}

class _OfferFilterSheetState extends State<_OfferFilterSheet> {
  late _SortOrder _sort;
  late (double, double)? _price;
  late String? _cat;

  static const _priceRanges = <(double, double, String)>[
    (0, 10, '0 - 10'),
    (10, 20, '10 - 20'),
    (20, 40, '20 - 40'),
    (40, 70, '40 - 70'),
    (70, 100, '70 - 100'),
    (100, 150, '100 - 150'),
    (150, 200, '150 - 200'),
    (200, 300, '200 - 300'),
    (300, 500, '300 - 500'),
    (500, 700, '500 - 700'),
    (700, 1000, '700 - 1000'),
  ];

  @override
  void initState() {
    super.initState();
    _sort = widget.sortOrder;
    _price = widget.priceRange;
    _cat = widget.catFilter;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle.
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back<void>(),
                  child: const Icon(Icons.close,
                      size: 22, color: Color(0xFF717885)),
                ),
                const Spacer(),
                Text(
                  'pay_filter'.tr,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF121C19),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 22),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F3)),
          // Scrollable options.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section(
                    'pay_sort_by'.tr,
                    Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          'تنازلي من (ي - أ)',
                          _sort == _SortOrder.nameDesc,
                          () => setState(() => _sort = _sort == _SortOrder.nameDesc
                              ? _SortOrder.none
                              : _SortOrder.nameDesc),
                        ),
                        _chip(
                          'تصاعدي من (أ - ي)',
                          _sort == _SortOrder.nameAsc,
                          () => setState(() => _sort = _sort == _SortOrder.nameAsc
                              ? _SortOrder.none
                              : _SortOrder.nameAsc),
                        ),
                        _chip(
                          'شائع',
                          _sort == _SortOrder.popular,
                          () => setState(() => _sort = _sort == _SortOrder.popular
                              ? _SortOrder.none
                              : _SortOrder.popular),
                        ),
                      ],
                    ),
                  ),
                  if (widget.subCats.length > 1) ...[
                    const SizedBox(height: 20),
                    _section(
                      'pay_products'.tr,
                      Wrap(
                        textDirection: TextDirection.rtl,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip('جميع المنتجات', _cat == null,
                              () => setState(() => _cat = null)),
                          ...widget.subCats.map((s) => _chip(
                                s.name,
                                _cat == s.id,
                                () => setState(
                                    () => _cat = _cat == s.id ? null : s.id),
                              )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _section(
                    'pay_price_range'.tr,
                    Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('الجميع', _price == null,
                            () => setState(() => _price = null)),
                        ..._priceRanges.map((r) => _chip(
                              r.$3,
                              _price != null &&
                                  _price!.$1 == r.$1 &&
                                  _price!.$2 == r.$2,
                              () => setState(() => _price = (_price != null &&
                                      _price!.$1 == r.$1 &&
                                      _price!.$2 == r.$2)
                                  ? null
                                  : (r.$1, r.$2)),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Apply button.
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_sort, _price, _cat);
                        Get.back<void>();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F7A35),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'pay_done'.tr,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Reset button.
                  TextButton(
                    onPressed: () => setState(() {
                      _sort = _SortOrder.none;
                      _price = null;
                      _cat = null;
                    }),
                    child: Text(
                      'pay_reset'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF717885),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget content) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF121C19),
            ),
          ),
          const SizedBox(height: 10),
          content,
        ],
      );

  Widget _chip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F7A35) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? const Color(0xFF1F7A35)
                  : const Color(0xFFE0E1E3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: active ? Colors.white : const Color(0xFF717885),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Filter / view state ──────────────────────────────────────────────────
  _ViewMode _viewMode = _ViewMode.grid;
  _SortOrder _sortOrder = _SortOrder.none;
  (double, double)? _priceRange;
  String? _catFilter;

  /// One GlobalKey per *displayed* (post-filter) section, rebuilt whenever the
  /// filter changes. Passed to both the tabs bar and the body so tap-to-scroll
  /// and Scrollable.ensureVisible stay in sync.
  List<GlobalKey> _displayKeys = const [];

  // ── Computed ─────────────────────────────────────────────────────────────

  List<SubCat> get _displaySubs {
    List<SubCat> result = _catFilter != null
        ? _subs.where((s) => s.id == _catFilter).toList()
        : List<SubCat>.from(_subs);
    return result.map((sub) {
      List<OfferProduct> products = sub.products;
      if (_priceRange != null) {
        final (mn, mx) = _priceRange!;
        products =
            products.where((p) => p.shownPrice >= mn && p.shownPrice <= mx).toList();
      }
      if (_sortOrder == _SortOrder.nameAsc) {
        products = [...products]
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      } else if (_sortOrder == _SortOrder.nameDesc) {
        products = [...products]
          ..sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
      }
      return SubCat(
          id: sub.id,
          name: sub.name,
          products: products,
          total: sub.total,
          hasMore: sub.hasMore);
    }).where((s) => s.products.isNotEmpty).toList();
  }

  bool get _hasFilter =>
      _sortOrder != _SortOrder.none || _priceRange != null || _catFilter != null;

  int get _displayCount =>
      _displaySubs.fold(0, (sum, s) => sum + s.products.length);

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
    _displayKeys = List.from(_sectionKeys);
    _selectedTab = 0;
    _loadingDetail = false;
    // Reset filter when a new category loads.
    _sortOrder = _SortOrder.none;
    _priceRange = null;
    _catFilter = null;
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
    final ctx = (i >= 0 && i < _displayKeys.length)
        ? _displayKeys[i].currentContext
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

  void _openFilter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfferFilterSheet(
        sortOrder: _sortOrder,
        priceRange: _priceRange,
        catFilter: _catFilter,
        subCats: _subs,
        onApply: (sort, price, cat) {
          if (!mounted) return;
          setState(() {
            _sortOrder = sort;
            _priceRange = price;
            _catFilter = cat;
            _selectedTab = 0;
            // Rebuild display keys for the new filtered set. _displaySubs
            // reads the just-updated filter fields so the count is correct.
            _displayKeys = List.generate(_displaySubs.length, (_) => GlobalKey());
          });
        },
      ),
    );
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
      value: SystemUiOverlayStyle(
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
                // Count + view toggle + filter button row.
                if (!_loadingDetail && _subs.isNotEmpty) ...[
                  _OfferControlRow(
                    count: _displayCount,
                    viewMode: _viewMode,
                    hasFilter: _hasFilter,
                    onViewMode: (v) => setState(() => _viewMode = v),
                    onFilter: _openFilter,
                  ),
                  // Sub-category tabs (show only the displayed/filtered tabs).
                  if (_displaySubs.isNotEmpty)
                    MarketOffersTabsBar(
                      labels: _displaySubs.map((s) => s.name).toList(),
                      selectedTab: _selectedTab
                          .clamp(0, (_displaySubs.length - 1).clamp(0, 9999)),
                      accent: const Color(0xFF1F7A35),
                      accentPale: _accentPale,
                      onTabTap: _onTabTap,
                    ),
                ],
                Expanded(
                  child: MarketOffersBody(
                    loading: _loadingDetail,
                    subs: _displaySubs,
                    sectionKeys: _displayKeys,
                    scrollController: _scroll,
                    accent: _accent,
                    storeId: widget.storeId,
                    moduleId: widget.moduleId,
                    isListView: _viewMode == _ViewMode.list,
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
