import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/search/controllers/search_controller.dart'
    as srch;
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: full-screen search landing.
///
/// Shows recent searches, the most-searched keywords, and popular brands —
/// matching the Figma design. The "most searched" and "brands" rails are
/// module-scoped on the backend, so they're fetched against the food module
/// (the richest) to stay populated regardless of the active module.
class HomeSearchScreen extends StatefulWidget {
  /// When set, the search (and filtering) is scoped to this store's products
  /// only — used when opening search from inside a store (e.g. هايبر شلة).
  final int? storeId;

  /// Module used for the request header when store-scoped. Falls back to the
  /// currently selected module, then the food module, when null.
  final int? moduleId;

  const HomeSearchScreen({super.key, this.storeId, this.moduleId});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  List<String> _recent = const [];
  List<String> _mostSearched = const [];
  List<BrandModel> _brands = const [];

  // When true, the body shows search results instead of the discovery landing.
  bool _showResults = false;
  // While true, the most-searched / brands rails show a shimmer skeleton.
  bool _loadingDiscovery = true;
  // The most-searched keyword the user picked (shown highlighted in green).
  String? _selectedKeyword;
  // Debounce for live (as-you-type) search.
  Timer? _debounce;
  // Cross-module product search results + loading state.
  List<_SearchProduct> _results = const [];
  bool _searchLoading = false;

  static const Color _titleColor = Color(0xFF121C19);
  static const Color _chipBg = Color(0xFFF2F2F4);
  static const Color _chipText = Color(0xFF121C19);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<srch.SearchController>()) {
        final sc = Get.find<srch.SearchController>();
        sc.getHistoryList();
        _recent = List<String>.from(sc.historyList);
        if (mounted) setState(() {});
      }
      _fetchModuleScoped();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Live search: filter as the user types (debounced), no Enter needed.
  void _onChanged(String v) {
    _debounce?.cancel();
    final text = v.trim();
    if (text.isEmpty) {
      setState(() {
        _showResults = false;
        _selectedKeyword = null;
      });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _runSearch(text));
  }

  /// Cross-module product search via `/api/v1/items/search` (no module_id ⇒
  /// results from every module), grouped by store in the UI.
  Future<void> _runSearch(String text) async {
    if (!mounted) return;
    setState(() {
      _showResults = true;
      _searchLoading = true;
    });
    List<_SearchProduct> results = const [];
    try {
      if (Get.isRegistered<ApiClient>()) {
        // The backend scopes search by the moduleId header (and by store_id when
        // provided). moduleId=0 is rejected by the secure client (403), so we
        // always send a valid module. When opened from inside a store we scope
        // to that store's products via store_id; otherwise we fall back to the
        // (food-module) cross-module behaviour.
        final bool storeScoped = widget.storeId != null;
        final int? currentModuleId = Get.isRegistered<SplashController>()
            ? Get.find<SplashController>().module?.id
            : null;
        final int? foodId = _moduleIdByType('food');
        // Resolve a VALID search module: the live selected module is null in the
        // multi-module home, and the hyper store passes a legacy moduleId (1)
        // that the search index rejects. The market storefronts are ecommerce,
        // so fall back to the ecommerce module — store_id does the real scoping.
        final int? ecommerceId = _moduleIdByType('ecommerce');
        // Scope to the context module so an in-restaurants search stays within
        // restaurants (and their products); store_id narrows it further.
        final int? scopeModuleId = storeScoped
            ? (ecommerceId ?? currentModuleId ?? widget.moduleId ?? foodId)
            : (widget.moduleId ?? currentModuleId ?? foodId);
        final r = await Get.find<ApiClient>().getData(
          '/api/v1/items/search?name=${Uri.encodeQueryComponent(text)}'
          '&offset=1&limit=50'
          '${storeScoped ? '&store_id=${widget.storeId}' : ''}'
          '${scopeModuleId != null ? '&module_id=$scopeModuleId' : ''}',
          headers: scopeModuleId != null
              ? {AppConstants.moduleId: scopeModuleId.toString()}
              : null,
          useEtag: false,
        );
        final body = r.body;
        final list = body is Map ? body['products'] : null;
        if (list is List) {
          results = list
              .whereType<Map>()
              .map((e) => _SearchProduct.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    // Relevance ranking: an exact name, then a name that STARTS with the query,
    // then the earliest in-name match — so "نوتيلا" surfaces the chocolate
    // before furniture that merely carries "نوتيلا" as a colour mid-name.
    final String q = text.toLowerCase().trim();
    int rank(_SearchProduct p) {
      final n = (p.name ?? '').toLowerCase();
      if (n == q) return 0;
      if (n.startsWith(q)) return 1;
      final i = n.indexOf(q);
      return i < 0 ? 1000000 : 100 + i;
    }

    results = [...results]..sort((a, b) => rank(a).compareTo(rank(b)));
    if (!mounted) return;
    // Drop stale responses if the query changed while we were waiting.
    if (_controller.text.trim() != text) return;
    setState(() {
      _results = results;
      _searchLoading = false;
    });
  }

  /// Resolves a module id by its type (e.g. 'food', 'ecommerce').
  int? _moduleIdByType(String type) => _moduleByType(type)?.id;

  /// Resolves a module by its type (e.g. 'food', 'ecommerce').
  ModuleModel? _moduleByType(String type) {
    if (!Get.isRegistered<SplashController>()) return null;
    final modules = Get.find<SplashController>().moduleList;
    if (modules == null) return null;
    for (final m in modules) {
      if ((m.moduleType ?? '').toLowerCase() == type) {
        return m;
      }
    }
    return null;
  }

  /// Switches to the product's module (so its details/cart load in the right
  /// context) then opens the item details screen.
  Future<void> _openItem(_SearchProduct item) async {
    final String type = (item.moduleType ?? '').toLowerCase();
    final module = _moduleByType(type);
    if (module != null && Get.isRegistered<SplashController>()) {
      final sc = Get.find<SplashController>();
      if (sc.module?.id != module.id) {
        // Header-only switch → instant nav; the details screen shows its own
        // loading while fetching (no heavy home reload before navigation).
        await sc.setModuleHeaderOnly(module);
      }
    }
    await Get.toNamed(
        RouteHelper.getItemDetailsRoute(item.id, type == AppConstants.food));
  }

  /// The rail now holds stores; open the tapped store's storefront (the
  /// redesigned [MarketStoreScreen]).
  Future<void> _openBrand(BrandModel store) async {
    if (store.id == null) return;
    final int? mid = widget.moduleId ??
        (Get.isRegistered<SplashController>()
            ? Get.find<SplashController>().module?.id
            : null);
    await Get.to<void>(() => MarketStoreScreen(
          storeId: store.id,
          name: store.name,
          logo: store.imageFullUrl,
          moduleId: mid ?? 3,
          useCoverHeader: true,
        ));
  }

  Future<void> _fetchModuleScoped() async {
    // In-store search: show THIS store's category names as quick keywords and
    // no store rail (e.g. searching inside هايبر شله lists its sections).
    if (widget.storeId != null) {
      try {
        if (Get.isRegistered<ApiClient>()) {
          final r = await Get.find<ApiClient>().getData(
            '/api/v2/stores/${widget.storeId}/categories',
            headers: widget.moduleId != null
                ? {AppConstants.moduleId: widget.moduleId.toString()}
                : null,
            useEtag: false,
          );
          final dynamic body = r.body;
          final List raw = body is List
              ? body
              : (body is Map && body['categories'] is List)
                  ? body['categories'] as List
                  : (body is Map && body['data'] is List)
                      ? body['data'] as List
                      : const [];
          if (mounted) {
            _mostSearched = raw
                .whereType<Map>()
                .map((e) => (e['name'] ?? '').toString())
                .where((n) => n.isNotEmpty)
                .toList();
          }
        }
      } catch (_) {}
      if (mounted) setState(() => _loadingDiscovery = false);
      return;
    }
    if (!Get.isRegistered<ApiClient>()) return;
    final api = Get.find<ApiClient>();

    try {
      // Most-searched keywords, ranked by how often users searched them.
      final r = await api.getData(
        '/api/v2/search/popular?limit=10',
        useEtag: false,
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      );
      final dynamic body = r.body;
      final dynamic list = body is Map ? body['data'] : body;
      if (mounted && list is List) {
        _mostSearched = list
            .whereType<Map>()
            .map((e) => (e['keyword'] ?? '').toString())
            .where((k) => k.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    try {
      // The rail shows this context's STORES (e.g. restaurants) — not
      // cross-module brands — scoped to the screen's module. Each chip opens
      // that store. Reuses [BrandModel] purely as a {id, name, image} holder.
      final int? railModuleId = widget.moduleId ??
          (Get.isRegistered<SplashController>()
              ? Get.find<SplashController>().module?.id
              : null) ??
          _moduleIdByType('food');
      final r = await api.getData(
        '/api/v2/stores?module_id=${railModuleId ?? ''}&limit=20&offset=0',
        useEtag: false,
        headers: railModuleId != null
            ? {AppConstants.moduleId: railModuleId.toString()}
            : null,
      );
      final dynamic body = r.body;
      final List raw = (body is Map && body['stores'] is List)
          ? body['stores'] as List
          : (body is List ? body : const []);
      if (mounted) {
        _brands = raw.whereType<Map>().map((e) {
          final m = Map<String, dynamic>.from(e);
          return BrandModel(
            id: int.tryParse('${m['id']}'),
            name: m['name']?.toString(),
            imageFullUrl: (m['logo_full_url'] ?? m['logo'])?.toString(),
          );
        }).toList();
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingDiscovery = false);
  }

  void _search(String query) {
    final text = query.trim();
    if (text.isEmpty) return;
    if (_controller.text != text) _controller.text = text;
    FocusScope.of(context).unfocus();
    _runSearch(text);
  }

  /// Leaves results back to the discovery landing (or closes the screen).
  void _onLeading() {
    if (_showResults) {
      _controller.clear();
      setState(() => _showResults = false);
    } else {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(context),
            Expanded(
              child: _showResults
                  ? _buildResults()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeSmall,
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRecentSection(),
                          // Global discovery rails are hidden for store-scoped
                          // search (they list cross-store/restaurant content
                          // that is irrelevant inside a single store).
                          if (widget.storeId == null) _buildMostSearchedSection(),
                          if (widget.storeId == null) _buildBrandsSection(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeExtraSmall,
        Dimensions.paddingSizeSmall,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _onLeading,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_ios, size: 28),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _chipBg,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                autofocus: true,
                textAlign: TextAlign.right,
                onSubmitted: _search,
                onChanged: _onChanged,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'search_hint'.tr,
                  hintStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Image.asset(
                      Images.search_v2,
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.search, size: 22),
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : InkWell(
                          onTap: () {
                            _controller.clear();
                            setState(() {
                              _showResults = false;
                              _selectedKeyword = null;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 20,
                          ),
                        ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(
        top: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeSmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.4,
                color: _titleColor,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _chip(String label, {bool highlight = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _search(label),
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFE7F7EA) : _chipBg,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.4,
            color: highlight ? const Color(0xFF1F7A35) : _chipText,
          ),
        ),
      ),
    );
  }

  void _clearRecent() {
    if (Get.isRegistered<srch.SearchController>()) {
      Get.find<srch.SearchController>().clearSearchHistory();
    }
    setState(() => _recent = const []);
  }

  Widget _buildRecentSection() {
    if (_recent.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          'recent_searches'.tr,
          trailing: InkWell(
            onTap: _clearRecent,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(Images.trash, width: 16, height: 16)),
          ),
        ),
        Wrap(
          spacing: Dimensions.paddingSizeSmall,
          runSpacing: Dimensions.paddingSizeSmall,
          alignment: WrapAlignment.start,
          children: _recent.reversed.map(_chip).toList(),
        ),
      ],
    );
  }

  Widget _shimmer(Widget child) {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      highlightColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
      child: child,
    );
  }

  Widget _skeletonBox(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _skeletonChipsSection(String title) {
    const widths = <double>[60, 80, 50, 90, 70, 65];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(title),
        _shimmer(
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            alignment: WrapAlignment.start,
            children: [
              for (final w in widths)
                _skeletonBox(w, 32, Dimensions.radiusLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _skeletonBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('أشهر المتاجر'),
        _shimmer(
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeDefault,
            alignment: WrapAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 10; i++) _skeletonBox(56, 56, 3.24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMostSearchedSection() {
    if (_loadingDiscovery) {
      return _skeletonChipsSection('most_searched'.tr);
    }
    if (_mostSearched.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('most_searched'.tr),
        Wrap(
          spacing: Dimensions.paddingSizeSmall,
          runSpacing: Dimensions.paddingSizeSmall,
          alignment: WrapAlignment.start,
          // Green only on the keyword the user picked.
          children: _mostSearched
              .map((k) => _chip(
                    k,
                    highlight: k == _selectedKeyword,
                    onTap: () {
                      setState(() => _selectedKeyword = k);
                      _search(k);
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── Results ────────────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_searchLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'no_data_found'.tr,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: _chipText,
          ),
        ),
      );
    }

    // Group the matched products by their store, preserving order.
    final Map<int?, List<_SearchProduct>> groups = {};
    for (final p in _results) {
      (groups[p.storeId] ??= <_SearchProduct>[]).add(p);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
      ),
      children: [
        for (final entry in groups.entries) _storeGroup(entry.value),
      ],
    );
  }

  /// A store header + a 3-column grid of its matched products, in one card.
  Widget _storeGroup(List<_SearchProduct> items) {
    final _SearchProduct first = items.first;
    final String name = first.storeName ?? '';
    final double? rating = first.avgRating;
    final String? deliveryTime = first.deliveryTime;
    final int? storeId = first.storeId;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _storeHeader(
            storeId: storeId,
            logo: first.storeLogo,
            name: name,
            description: null,
            rating: rating,
            deliveryTime: deliveryTime,
            freeDelivery: first.freeDelivery,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: Dimensions.paddingSizeSmall,
              crossAxisSpacing: Dimensions.paddingSizeSmall,
              // Card ratio 104 × 130 from the design.
              childAspectRatio: 104 / 130,
            ),
            itemBuilder: (_, i) => _productCard(items[i]),
          ),
        ],
      ),
    );
  }

  Widget _storeHeader({
    required int? storeId,
    required String? logo,
    required String name,
    required String? description,
    required double? rating,
    required String? deliveryTime,
    required bool freeDelivery,
  }) {
    return InkWell(
      onTap: storeId == null
          ? null
          : () => Get.toNamed(
              RouteHelper.getStoreRoute(id: storeId, page: 'store')),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo on the right (start), name beside it.
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: CustomImage(
              image: logo ?? '',
              width: 46,
              height: 46,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _titleColor,
                  ),
                ),
                if ((description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Rating pill (green) — corners rounded top-right & bottom-left.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF31A342),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            Images.star_v2,
                            width: 11,
                            height: 11,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.star,
                                size: 11,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              (rating ?? 0).toStringAsFixed(1),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                height: 1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delivery — its own container.
                    _infoPill(
                      image: freeDelivery
                          ? Images.freeDelivery
                          : Images.fastDelivery,
                      fallbackIcon: Icons.local_shipping_outlined,
                      label: freeDelivery
                          ? 'free_delivery'.tr
                          : 'fast_delivery'.tr,
                    ),
                    // Estimated time — its own container.
                    if ((deliveryTime ?? '').isNotEmpty)
                      _infoPill(
                        image: Images.time_v2,
                        fallbackIcon: Icons.access_time,
                        label: deliveryTime!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A small grey pill with an icon + label (delivery / time).
  Widget _infoPill(
      {required String image,
      required String label,
      required IconData fallbackIcon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            image,
            width: 13,
            height: 13,
            color: _titleColor,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, size: 13, color: _titleColor),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1,
                color: _titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Price with the riyal (SAR) symbol image; [struck] renders the old price.
  Widget _priceWidget(double value, {bool struck = false}) {
    final Color color = struck ? Theme.of(context).hintColor : _titleColor;
    final double iconSize = struck ? 8 : 11;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.sar,
            width: iconSize,
            height: iconSize,
            color: color,
            errorBuilder: (_, __, ___) => Text(
              '﷼',
              style: TextStyle(fontSize: struck ? 8 : 10, color: color),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: struck ? FontWeight.w500 : FontWeight.w700,
              fontSize: struck ? 9 : 14,
              height: 1.2,
              decoration: struck ? TextDecoration.lineThrough : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(_SearchProduct item) {
    final double price = item.price;
    final double discount = item.discount;
    final bool hasDiscount = discount > 0;
    final double newPrice = PriceConverter.convertWithDiscount(
            price, discount, item.discountType) ??
        price;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openItem(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomImage(
                        image: item.imageUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 44,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFDCDC),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            item.discountType == 'percent'
                                ? '-${discount.toStringAsFixed(0)}%'
                                : '-${discount.toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.0,
                              color: Color(0xFFDB2525),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: .5,
                      left: 8,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1FDD2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            size: 22, color: Color(0xFF31A342)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        height: 1.4,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _priceWidget(newPrice),
                          if (hasDiscount) ...[
                            const SizedBox(width: 4),
                            _priceWidget(price, struck: true),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandsSection() {
    if (_loadingDiscovery) {
      return _skeletonBrandsSection();
    }
    if (_brands.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('أشهر المتاجر'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _brands.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: Dimensions.paddingSizeSmall,
            crossAxisSpacing: Dimensions.paddingSizeSmall,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, index) {
            final brand = _brands[index];
            return InkWell(
              onTap: () => _openBrand(brand),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: CustomImage(
                  image: brand.imageFullUrl ?? '',
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Lightweight product row from `/api/v1/items/search` (`products`).
class _SearchProduct {
  final int? id;
  final String? name;
  final String? imageUrl;
  final double price;
  final double discount;
  final String? discountType;
  final int? storeId;
  final String? storeName;
  final String? storeLogo;
  final String? moduleType;
  final String? deliveryTime;
  final double? avgRating;
  final bool freeDelivery;

  _SearchProduct({
    this.id,
    this.name,
    this.imageUrl,
    this.price = 0,
    this.discount = 0,
    this.discountType,
    this.storeId,
    this.storeName,
    this.storeLogo,
    this.moduleType,
    this.deliveryTime,
    this.avgRating,
    this.freeDelivery = false,
  });

  static double _toDouble(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  static int? _toInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());

  factory _SearchProduct.fromJson(Map<String, dynamic> j) {
    return _SearchProduct(
      id: _toInt(j['id']),
      name: j['name']?.toString(),
      imageUrl: (j['image_full_url'] ?? j['image'])?.toString(),
      price: _toDouble(j['price']),
      discount: _toDouble(j['discount']),
      discountType: j['discount_type']?.toString(),
      storeId: _toInt(j['store_id']),
      storeName: j['store_name']?.toString(),
      storeLogo: (j['store_logo'] ?? j['store_logo_full_url'])?.toString(),
      moduleType: j['module_type']?.toString(),
      deliveryTime: j['delivery_time']?.toString(),
      avgRating: j['avg_rating'] == null ? null : _toDouble(j['avg_rating']),
      freeDelivery: j['free_delivery'] == true,
    );
  }
}
