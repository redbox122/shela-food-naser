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
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_subcat_classifier.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_tabs_bar.dart';
import 'package:sixam_mart/util/app_constants.dart';

enum _ViewMode { grid, list }
enum _SortOrder { none, nameAsc, nameDesc, popular, priceAsc, priceDesc }

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

  /// When true, the categories top bar is replaced by a minimal accent band
  /// with only a back arrow (used by the هايبر شله designed category cards).
  final bool minimalHeader;

  /// Products the caller already loaded (e.g. a featured-store section). Used as
  /// a fallback when the store-category fetch returns nothing: a cross-module
  /// featured store (a restaurant opened via "منتجات من متجر آخر") has no market
  /// "offers" category, so `/categories/offers` comes back empty even though the
  /// caller already holds the products to show.
  final List<OfferProduct> presetProducts;

  /// When true, only products that carry a discount are shown (used by the
  /// هايبر شله discount banners — each opens its department's discounted items).
  final bool discountedOnly;

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
    this.minimalHeader = false,
    this.presetProducts = const [],
    this.discountedOnly = false,
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
  final String? brandFilter;

  /// Brands (name → count) extracted from the products currently in view.
  final List<MapEntry<String, int>> brands;
  final void Function(_SortOrder, (double, double)?, String?) onApply;

  const _OfferFilterSheet({
    required this.sortOrder,
    required this.priceRange,
    required this.brandFilter,
    required this.brands,
    required this.onApply,
  });

  @override
  State<_OfferFilterSheet> createState() => _OfferFilterSheetState();
}

class _OfferFilterSheetState extends State<_OfferFilterSheet> {
  late _SortOrder _sort;
  late (double, double)? _price;
  late String? _brand;

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
    _brand = widget.brandFilter;
  }

  void _toggleSort(_SortOrder o) =>
      setState(() => _sort = _sort == o ? _SortOrder.none : o);

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
                        // Price sort first — the most-used option.
                        _chip('الأقل سعراً', _sort == _SortOrder.priceAsc,
                            () => _toggleSort(_SortOrder.priceAsc)),
                        _chip('الأعلى سعراً', _sort == _SortOrder.priceDesc,
                            () => _toggleSort(_SortOrder.priceDesc)),
                        _chip('تصاعدي (أ - ي)', _sort == _SortOrder.nameAsc,
                            () => _toggleSort(_SortOrder.nameAsc)),
                        _chip('تنازلي (ي - أ)', _sort == _SortOrder.nameDesc,
                            () => _toggleSort(_SortOrder.nameDesc)),
                      ],
                    ),
                  ),
                  // Brand filter — brands extracted client-side from the
                  // products currently in view. Only shown when there are ≥2.
                  if (widget.brands.length > 1) ...[
                    const SizedBox(height: 20),
                    _section(
                      'العلامة التجارية',
                      Wrap(
                        textDirection: TextDirection.rtl,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip('كل العلامات', _brand == null,
                              () => setState(() => _brand = null)),
                          ...widget.brands.map((e) => _chip(
                                '${e.key} (${e.value})',
                                _brand == e.key,
                                () => setState(() =>
                                    _brand = _brand == e.key ? null : e.key),
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
                              ltr: true,
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
                        widget.onApply(_sort, _price, _brand);
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
                      _brand = null;
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
        // In the RTL sheet, start = right, so titles + chips align to the right.
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _chip(String label, bool active, VoidCallback onTap,
          {bool ltr = false}) =>
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
            // Numeric ranges ("40 - 70") stay LTR so RTL bidi doesn't flip them.
            textDirection: ltr ? TextDirection.ltr : null,
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

  /// Brand filter (client-side): products whose extracted brand equals this are
  /// kept. Null = all brands. Reset whenever the sub/child selection changes.
  String? _brandFilter;

  /// Name of the category whose products are currently in view — used to derive
  /// head-nouns for brand extraction. Updated when a sub tab is tapped.
  String _activeCatName = '';

  /// One GlobalKey per *displayed* (post-filter) section, rebuilt whenever the
  /// filter changes. Passed to both the tabs bar and the body so tap-to-scroll
  /// and Scrollable.ensureVisible stay in sync.
  List<GlobalKey> _displayKeys = const [];

  // ── Optional DEEPER level (panda-style) ──────────────────────────────────
  // When a tapped sub-category itself has real sub-categories in the backend,
  // they load here and render a SECOND filter bar (same design) directly under
  // the first, drilling the grid one level deeper. For today's flat Hyper data
  // (each category returns only itself) this stays empty and nothing changes —
  // the logic activates automatically the moment real sub-categories exist.
  List<SubCat> _childSubs = const [];
  int _childTab = 0;
  String? _childFilter; // selected child id (null = "الكل")

  /// Apply the active price-range + brand + sort to a set of sub-categories,
  /// dropping any that end up empty. Shared by [_displaySubs] and
  /// [_childDisplaySubs] so every filter is applied in exactly one place. All
  /// client-side — no extra API calls.
  List<SubCat> _applyPriceSort(List<SubCat> input) {
    final heads = SubCatClassifier.headNouns(_activeCatName);
    return input.map((sub) {
      List<OfferProduct> products = sub.products;
      if (_priceRange != null) {
        final (mn, mx) = _priceRange!;
        products = products
            .where((p) => p.shownPrice >= mn && p.shownPrice <= mx)
            .toList();
      }
      if (_brandFilter != null) {
        products = products
            .where((p) => SubCatClassifier.brandOf(p.name ?? '', heads) == _brandFilter)
            .toList();
      }
      switch (_sortOrder) {
        case _SortOrder.priceAsc:
          products = [...products]
            ..sort((a, b) => a.shownPrice.compareTo(b.shownPrice));
          break;
        case _SortOrder.priceDesc:
          products = [...products]
            ..sort((a, b) => b.shownPrice.compareTo(a.shownPrice));
          break;
        case _SortOrder.nameAsc:
          products = [...products]
            ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
          break;
        case _SortOrder.nameDesc:
          products = [...products]
            ..sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
          break;
        case _SortOrder.none:
        case _SortOrder.popular:
          break;
      }
      return SubCat(
          id: sub.id,
          name: sub.name,
          products: products,
          total: sub.total,
          hasMore: sub.hasMore);
    }).where((s) => s.products.isNotEmpty).toList();
  }

  /// Children of the drilled sub-category, filtered by [_childFilter].
  List<SubCat> get _childDisplaySubs {
    final base = _childFilter != null
        ? _childSubs.where((s) => s.id == _childFilter).toList()
        : List<SubCat>.from(_childSubs);
    return _applyPriceSort(base);
  }

  /// What the body actually renders: the deeper child level when drilled into a
  /// category that has real sub-categories, otherwise the normal display set.
  /// Identical to [_displaySubs] whenever no children are loaded (today's data),
  /// so the existing behaviour is unchanged.
  List<SubCat> get _effectiveDisplaySubs =>
      _childSubs.isNotEmpty ? _childDisplaySubs : _displaySubs;

  // ── Dynamic per-tab counts (panda-style "زيت زيتون (13)") ─────────────────

  /// Product count for one sub/group, reflecting the active price filter.
  /// Falls back to the API total_products (real total) when unfiltered so the
  /// main department tabs aren't undercounted by the first-page fetch; virtual
  /// (client-classified) groups carry total == products.length, so they're
  /// exact. Sort never changes counts.
  int _countOf(SubCat s) {
    if (_priceRange == null) {
      return s.total > 0 ? s.total : s.products.length;
    }
    final (mn, mx) = _priceRange!;
    return s.products
        .where((p) => p.shownPrice >= mn && p.shownPrice <= mx)
        .length;
  }

  /// Tab labels with a live count each: ['الكل (N)', 'اسم (n)', ...].
  List<String> _labelsWithCounts(List<SubCat> subs) {
    final total = subs.fold<int>(0, (a, s) => a + _countOf(s));
    return <String>[
      'الكل ($total)',
      for (final s in subs) '${s.name} (${_countOf(s)})',
    ];
  }

  // ── Computed ─────────────────────────────────────────────────────────────

  List<SubCat> get _displaySubs {
    final result = _catFilter != null
        ? _subs.where((s) => s.id == _catFilter).toList()
        : List<SubCat>.from(_subs);
    return _applyPriceSort(result);
  }

  bool get _hasFilter =>
      _sortOrder != _SortOrder.none ||
      _priceRange != null ||
      _catFilter != null ||
      _brandFilter != null;

  /// Products currently in view (selected sub/child), BEFORE the brand filter —
  /// the pool the brand chips are derived from so all brands stay selectable.
  List<OfferProduct> get _brandPool {
    final subs = _childSubs.isNotEmpty ? _childSubs : _subs;
    final Iterable<SubCat> sel = _childSubs.isNotEmpty
        ? (_childFilter != null
            ? subs.where((s) => s.id == _childFilter)
            : subs)
        : (_catFilter != null ? subs.where((s) => s.id == _catFilter) : subs);
    return sel.expand((s) => s.products).toList();
  }

  int get _displayCount =>
      _effectiveDisplaySubs.fold(0, (sum, s) => sum + s.products.length);

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
        AppConstants.localizationKey: AppConstants.currentLanguageCode,
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
    _brandFilter = null;
    _activeCatName = widget.title;
    // Drop any deeper (child) level from the previous category.
    _childSubs = const [];
    _childTab = 0;
    _childFilter = null;
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
        // The endpoint has no working offset pagination, but it DOES honor a
        // larger limit, so pull the whole category in one shot — the lazy
        // sliver body renders it without jank (was ?limit=20, capped at 20).
        '/api/v2/stores/${widget.storeId}/categories/$catId?limit=100',
        headers: _headers,
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = (body is Map && body['sub_categories'] is List)
          ? body['sub_categories'] as List
          : const [];
      var subs = raw
          .whereType<Map>()
          .map((e) => SubCat.fromJson(Map<String, dynamic>.from(e)))
          .where((s) => s.products.isNotEmpty)
          .toList();
      // Discount banners: keep only discounted products, drop empty sub-cats.
      if (widget.discountedOnly) {
        subs = subs
            .map((s) => SubCat(
                  id: s.id,
                  name: s.name,
                  products:
                      s.products.where((p) => p.hasDiscount).toList(),
                  total: s.total,
                  hasMore: s.hasMore,
                ))
            .where((s) => s.products.isNotEmpty)
            .toList();
      }
      // Fall back to the caller's products when the category has nothing.
      setState(() => _applySubs(subs.isNotEmpty ? subs : _presetSubs()));
    } catch (_) {
      if (mounted) setState(() => _applySubs(_presetSubs()));
    }
  }

  /// Tapping a sub_category tab scrolls the body to its titled section.
  void _onTabTap(int i) {
    // Panda-style sub-category FILTER: tab 0 = "الكل" (no filter, show every
    // sub-category); tabs 1..n filter the grid to that single sub-category.
    setState(() {
      _selectedTab = i;
      _catFilter =
          (i <= 0 || (i - 1) >= _subs.length) ? null : _subs[i - 1].id;
      // Track the active category name (for brand extraction) + reset the brand
      // filter since brands differ per sub.
      _activeCatName =
          (i <= 0 || (i - 1) >= _subs.length) ? widget.title : _subs[i - 1].name;
      _brandFilter = null;
      // Changing the top-level sub selection resets any deeper (child) level.
      _childSubs = const [];
      _childTab = 0;
      _childFilter = null;
      // Rebuild the section keys for the (now filtered) display set.
      _displayKeys = List.generate(_effectiveDisplaySubs.length, (_) => GlobalKey());
    });
    // If a real sub-category (not "الكل") was tapped, classify its products into
    // keyword groups and, if there are ≥2 clear groups, reveal the second bar.
    // No-op for homogeneous categories — the grid keeps showing the products.
    if (i > 0 && (i - 1) < _subs.length) {
      _maybeLoadChildren(_subs[i - 1].id, _subs[i - 1].name);
    }
    // Bring the filtered products into view from the top.
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  /// Panda-style deeper level — CLIENT-SIDE. Fetches the tapped category's full
  /// product list, then groups the products into virtual sub-categories by
  /// keyword (see [SubCatClassifier]). If ≥2 clear groups exist, they populate
  /// the second bar; a homogeneous category yields none, so [_childSubs] stays
  /// empty and the UI is unchanged.
  ///
  /// This depends on NO backend sub-categories — grouping happens in the app —
  /// so it survives the external daily category/product sync and needs no
  /// production writes.
  Future<void> _maybeLoadChildren(String subId, String subName) async {
    final api = _api;
    if (api == null || widget.storeId == null) return;
    try {
      final response = await api.getData(
        '/api/v2/stores/${widget.storeId}/categories/$subId?limit=100',
        headers: _headers,
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = (body is Map && body['sub_categories'] is List)
          ? body['sub_categories'] as List
          : const [];
      // Flatten every product the category returns (across any sub_categories).
      var products = <OfferProduct>[];
      for (final s in raw.whereType<Map>()) {
        final list = s['products'];
        if (list is List) {
          for (final p in list.whereType<Map>()) {
            products.add(OfferProduct.fromJson(Map<String, dynamic>.from(p)));
          }
        }
      }
      if (widget.discountedOnly) {
        products = products.where((p) => p.hasDiscount).toList();
      }
      final groups = SubCatClassifier.classify(subName, products);
      // Only apply if the tapped sub is still the selected one (guard against a
      // fast second tap).
      if (!mounted || _catFilter != subId) return;
      setState(() {
        _childSubs = groups;
        _childTab = 0;
        _childFilter = null;
        _displayKeys =
            List.generate(_effectiveDisplaySubs.length, (_) => GlobalKey());
      });
    } catch (_) {
      // Deeper level is optional; on failure keep the flat (current) view.
    }
  }

  /// Tapping a child tab (second bar): tab 0 = "الكل" (all children), 1..n
  /// filter the grid to that single child sub-category.
  void _onChildTabTap(int i) {
    setState(() {
      _childTab = i;
      _childFilter =
          (i <= 0 || (i - 1) >= _childSubs.length) ? null : _childSubs[i - 1].id;
      // Brands differ per child group, so reset the brand filter on switch.
      _brandFilter = null;
      _displayKeys =
          List.generate(_effectiveDisplaySubs.length, (_) => GlobalKey());
    });
    if (_scroll.hasClients) {
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
        brandFilter: _brandFilter,
        // Brands from the products currently in view (drilled group or dept).
        brands: SubCatClassifier.brands(_activeCatName, _brandPool),
        onApply: (sort, price, brand) {
          if (!mounted) return;
          setState(() {
            _sortOrder = sort;
            _priceRange = price;
            _brandFilter = brand;
            // Filters apply to whatever is CURRENTLY in view — the drill level
            // (sub/child selection) is preserved on purpose.
            _displayKeys =
                List.generate(_effectiveDisplaySubs.length, (_) => GlobalKey());
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
                if (widget.minimalHeader)
                  Container(
                    color: _accent,
                    child: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: InkResponse(
                          onTap: () => Get.back<void>(),
                          radius: 24,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back_ios,
                                size: 22, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (widget.brandedHeader)
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
                if (!_loadingDetail && _subs.isNotEmpty) ...[
                  // Sub-category filter bar sits DIRECTLY under the main-category
                  // header ("الزيت والسمن" → [الكل][زيت][سمن][زيت زيتون]), so the
                  // two category strips are adjacent. Panda layout.
                  // Always shows every sub-category plus an "الكل" tab; tapping a
                  // tab filters the grid below (see _onTabTap).
                  if (_subs.isNotEmpty)
                    MarketOffersTabsBar(
                      labels: _labelsWithCounts(_subs),
                      selectedTab: _selectedTab.clamp(0, _subs.length),
                      // Panda dark green for the selected sub-category pill.
                      // Was: Color(0xFF1F7A35)
                      accent: const Color(0xFF1B5E3F),
                      accentPale: _accentPale,
                      onTabTap: _onTabTap,
                    ),
                  // Deeper (panda-style) second filter bar — appears ONLY when
                  // the tapped sub-category has real sub-categories in the
                  // backend. Same design as the bar above. Empty today (flat
                  // data) → not rendered, so nothing changes until data exists.
                  if (_childSubs.isNotEmpty)
                    MarketOffersTabsBar(
                      labels: _labelsWithCounts(_childSubs),
                      selectedTab: _childTab.clamp(0, _childSubs.length),
                      accent: const Color(0xFF1B5E3F),
                      accentPale: _accentPale,
                      onTabTap: _onChildTabTap,
                    ),
                  // Count + view toggle + filter button row, below the sub bar.
                  _OfferControlRow(
                    count: _displayCount,
                    viewMode: _viewMode,
                    hasFilter: _hasFilter,
                    onViewMode: (v) => setState(() => _viewMode = v),
                    onFilter: _openFilter,
                  ),
                ],
                Expanded(
                  child: MarketOffersBody(
                    loading: _loadingDetail,
                    subs: _effectiveDisplaySubs,
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
            // Floating cart + search half-pill, flush to the screen's right edge.
            // Search is scoped to THIS store so shoppers can find a product
            // (e.g. "سكر") without leaving the category screen.
            Positioned(
              right: 0,
              bottom: 120,
              child: CartFab(
                accent: _accent,
                showSearch: true,
                onSearch: () => Get.to<void>(() => HomeSearchScreen(
                      storeId: widget.storeId,
                      moduleId: widget.moduleId,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
