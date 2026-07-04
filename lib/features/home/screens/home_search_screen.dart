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
import 'package:sixam_mart/features/search/utils/search_text_utils.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/features/home/widgets/home_services_grid.dart';
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
  // Stores (e.g. restaurants) whose NAME matches the query — shown above the
  // product results so searching a restaurant name surfaces the restaurant.
  List<BrandModel> _storeMatches = const [];
  bool _searchLoading = false;
  // Results tab: 0 = all, 1 = stores, 2 = products.
  int _resultTab = 0;
  // normalized-store-name → all branches with delivery/distance info.
  Map<String, List<_BranchInfo>> _branchGroups = {};
  // store-id → logo URL (from /api/v2/stores).
  Map<int, String> _storeLogoById = {};
  // normalized-store-name → logo URL (from /api/v2/stores).
  // More reliable than ID lookup because store IDs can differ across APIs.
  Map<String, String> _storeLogoByName = {};
  // IDs already fetched via on-demand enrichment (avoids duplicate API calls).
  final Set<int> _logoFetchAttempted = {};

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
    // Don't hit the server for a single character (too broad / irrelevant);
    // local suggestions still render via the isNotEmpty branch in build().
    if (text.length < 2) {
      if (_showResults) setState(() => _showResults = false);
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
        // HOME lens (no explicit module, not inside a store): search EVERY
        // section so a term like "أرز" surfaces food rice from grocery AND rice
        // dishes from restaurants — not just the last-opened module. The
        // ApiClient injects a default module header, so we request each module
        // explicitly and merge. Scoped searches keep the single-module behaviour.
        final bool crossModule =
            widget.moduleId == null && widget.storeId == null;
        final int? currentModuleId = Get.isRegistered<SplashController>()
            ? Get.find<SplashController>().module?.id
            : null;
        final List<int?> searchModuleIds = crossModule
            ? _allModuleIds()
            : <int?>[widget.moduleId ?? currentModuleId];

        // Fire every module's request in parallel to keep the search snappy.
        final List<List> pages = await Future.wait(
          searchModuleIds.map((int? smid) async {
            try {
              final r = await Get.find<ApiClient>().getData(
                '/api/v1/items/search?name=${Uri.encodeQueryComponent(_serverQuery(text))}'
                '&offset=1&limit=50'
                '${storeScoped ? '&store_id=${widget.storeId}' : ''}'
                '${smid != null ? '&module_id=$smid' : ''}',
                headers: smid != null
                    ? {AppConstants.moduleId: smid.toString()}
                    : null,
                useEtag: false,
              );
              final body = r.body;
              final list = body is Map ? body['products'] : null;
              return list is List ? list.whereType<Map>().toList() : const [];
            } catch (_) {
              return const [];
            }
          }),
        );
        final List<_SearchProduct> merged = [];
        final Set<int> seenItemKeys = {};
        for (final List page in pages) {
          for (final e in page.whereType<Map>()) {
            final p = _SearchProduct.fromJson(Map<String, dynamic>.from(e));
            final int key = p.id ?? Object.hash(p.name, p.storeId);
            if (seenItemKeys.add(key)) merged.add(p);
          }
        }
        results = merged;
        // RULE #1 defence-in-depth: never trust the backend's scoping alone.
        if (storeScoped) {
          // Store search: drop any product that isn't from this store.
          results = results
              .where((p) => p.storeId == null || p.storeId == widget.storeId)
              .toList();
        } else if (!crossModule) {
          // Single-section search: keep only products whose module matches the
          // current section (lenient: unknown module_type kept). Cross-module
          // (home-lens) search intentionally keeps every section's results.
          final String? sectionType = _sectionModuleType();
          if (sectionType != null && sectionType.isNotEmpty) {
            results = results
                .where((p) =>
                    (p.moduleType ?? '').isEmpty ||
                    p.moduleType!.toLowerCase() == sectionType)
                .toList();
          }
        }
      }
    } catch (_) {}
    // Relevance ranking: an exact name, then a name that STARTS with the query,
    // then the earliest in-name match — so "نوتيلا" surfaces the chocolate
    // before furniture that merely carries "نوتيلا" as a colour mid-name.
    // Dedup key: strips the leading "ال" article + normalizes, so "الأرز",
    // "أرز" and "رز" all reduce to the same core ("ارز") for filtering/ranking.
    final String q = arabicDedupKey(text);
    // RELEVANCE FILTER: the backend also matches on description / store name and
    // even mid-word substrings, so it returns products unrelated to the typed
    // word (e.g. "رز" surfacing "بامبرز" / "هيرز"). Keep only products where a
    // WORD in the (normalized) name starts with the query — with a leading-alef
    // strip so "رز" still matches "أرز"/"ارز". Store-name matches still appear in
    // the store section below.
    if (q.length >= 2) {
      results = results
          .where((p) => _nameMatchesQuery(p.name ?? '', q))
          .toList();
    }
    int rank(_SearchProduct p) {
      final n = _normCore(p.name ?? '');
      if (n == q) return 0;
      if (n.startsWith(q)) return 1;
      final i = n.indexOf(q);
      return i < 0 ? 1000000 : 100 + i;
    }

    // Food first, tools second — then by name relevance within each group.
    int foodFirst(_SearchProduct p) => _isKitchenTool(p.name ?? '') ? 1 : 0;
    results = [...results]..sort((a, b) {
      final int t = foodFirst(a).compareTo(foodFirst(b));
      if (t != 0) return t;
      return rank(a).compareTo(rank(b));
    });
    // Stores whose name matches the query (restaurants etc.) — name-start first.
    // Primary: pre-fetched _brands list.
    final List<BrandModel> storeMatches = _brands
        .where((b) => _normCore(b.name ?? '').contains(q))
        .toList()
      ..sort((a, b) {
        final an = _normCore(a.name ?? '');
        final bn = _normCore(b.name ?? '');
        return (an.startsWith(q) ? 0 : 1).compareTo(bn.startsWith(q) ? 0 : 1);
      });
    // Secondary: stores in the product results whose name matches the query but
    // aren't in the pre-fetched list (e.g. stores beyond the 50-store limit or
    // without a logo). This ensures the "store first" rule applies to every keyword.
    final Set<int?> matchedStoreIds = storeMatches.map((s) => s.id).toSet();
    final Set<int?> seenFromResults = {};
    for (final p in results) {
      if (seenFromResults.contains(p.storeId) ||
          matchedStoreIds.contains(p.storeId)) {
        continue;
      }
      seenFromResults.add(p.storeId);
      if (_normCore(p.storeName ?? '').contains(q)) {
        storeMatches.add(BrandModel(
          id: p.storeId,
          name: p.storeName,
          imageFullUrl: _resolvedLogo(p.storeId, p.storeName, p.storeLogo),
        ));
        matchedStoreIds.add(p.storeId);
      }
    }
    if (!mounted) return;
    // Drop stale responses if the query changed while we were waiting.
    if (_controller.text.trim() != text) return;
    setState(() {
      _results = results;
      _storeMatches = storeMatches;
      _searchLoading = false;
      _resultTab = 0;
    });
    // Kick off on-demand logo enrichment for stores not in the pre-fetched list.
    _enrichMissingStoreLogos();
  }

  /// Resolves the logo URL for a store.
  /// Priority: product-API logo → name lookup → ID lookup.
  /// Name lookup is most reliable because store IDs can differ across APIs.
  String? _resolvedLogo(int? storeId, String? storeName, String? productLogo) {
    if ((productLogo ?? '').isNotEmpty) return productLogo;
    if ((storeName ?? '').isNotEmpty) {
      final byName = _storeLogoByName[_normCore(storeName!)];
      if ((byName ?? '').isNotEmpty) return byName;
    }
    if (storeId != null) return _storeLogoById[storeId];
    return null;
  }

  /// Normalizes a raw logo path to a full URL.
  String? _toLogoUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${AppConstants.baseUrl}$raw';
    return '${AppConstants.storageBaseUrl}/$raw';
  }

  /// On-demand enrichment: for every store in the current results that has no
  /// logo in our caches, fetch its full detail from the backend and cache it.
  /// This covers stores not in the pre-fetched /api/v2/stores list.
  Future<void> _enrichMissingStoreLogos() async {
    if (!mounted || !Get.isRegistered<ApiClient>()) return;
    final int? mid = _sectionModuleId();
    final api = Get.find<ApiClient>();

    // Collect IDs that still have no logo and haven't been attempted before.
    final Set<int> toFetch = {};
    for (final p in _results) {
      final int? id = p.storeId;
      if (id == null || _logoFetchAttempted.contains(id)) continue;
      final bool hasLogo = _storeLogoById.containsKey(id) ||
          _storeLogoByName.containsKey(_normCore(p.storeName ?? ''));
      if (!hasLogo) toFetch.add(id);
    }
    if (toFetch.isEmpty) return;

    // Mark attempted before async work so parallel calls don't double-fetch.
    _logoFetchAttempted.addAll(toFetch);

    bool anyUpdated = false;
    for (final storeId in toFetch) {
      try {
        final r = await api.getData(
          '${AppConstants.storeDetailsUri}$storeId',
          headers: mid != null ? {AppConstants.moduleId: mid.toString()} : null,
          useEtag: false,
        );
        final dynamic body = r.body;
        final dynamic store =
            body is Map ? (body['store'] ?? body['data'] ?? body) : null;
        if (store is! Map) continue;
        final String rawLogo = (store['logo_full_url']?.toString() ?? '').isNotEmpty
            ? store['logo_full_url'].toString()
            : store['logo']?.toString() ?? '';
        final String? logo = _toLogoUrl(rawLogo);
        if ((logo ?? '').isEmpty) continue;
        _storeLogoById[storeId] = logo!;
        final String name = store['name']?.toString() ?? '';
        if (name.isNotEmpty) _storeLogoByName[_normCore(name)] = logo;
        anyUpdated = true;
      } catch (_) {}
    }

    if (mounted && anyUpdated) setState(() {});
  }

  /// A fetched section store whose name equals [name] (for chip taps).
  BrandModel? _storeByName(String name) {
    final n = _normCore(name);
    for (final b in _brands) {
      if (_normCore(b.name ?? '') == n) return b;
    }
    return null;
  }

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

  /// The CURRENT section's module id (rule #1): the one passed in, else the
  /// live selected module. Used to scope discovery + pick the fallback list.
  int? _sectionModuleId() =>
      widget.moduleId ??
      (Get.isRegistered<SplashController>()
          ? Get.find<SplashController>().module?.id
          : null);

  /// All available module ids (restaurants/cafes/grocery/pharmacy …) used to
  /// pull a variety of stores for the HOME-lens discovery rails. Falls back to
  /// the current section when the module list isn't available.
  List<int?> _allModuleIds() {
    if (Get.isRegistered<SplashController>()) {
      final modules = Get.find<SplashController>().moduleList;
      if (modules != null && modules.isNotEmpty) {
        final List<int?> ids = <int?>[];
        for (final m in modules) {
          if (m.id != null && !ids.contains(m.id)) ids.add(m.id);
        }
        if (ids.isNotEmpty) return ids;
      }
    }
    return <int?>[_sectionModuleId()];
  }

  /// The current section's module type (e.g. 'pharmacy', 'food', 'ecommerce').
  String? _sectionModuleType() {
    final int? id = _sectionModuleId();
    if (id == null || !Get.isRegistered<SplashController>()) return null;
    for (final m in Get.find<SplashController>().moduleList ?? const []) {
      if (m.id == id) return (m.moduleType ?? '').toLowerCase();
    }
    return null;
  }

  // ── Arabic text normalization (delegates to the testable util) ────────────
  String _stripMarks(String s) => stripArabicMarks(s);
  String _normCore(String s) => normalizeArabic(s);

  /// Relevance test: true when a WORD in [name] starts with the query [normQ]
  /// (both compared via [arabicDedupKey], which strips the leading "ال" article
  /// and normalizes forms). So "رز"/"أرز"/"الأرز" all reduce to "ارز" and match
  /// "أرز تايلندي" — but NOT a mid-word substring like "بامبرز"/"هيرز".
  /// [normQ] must already be arabicDedupKey(query).
  bool _nameMatchesQuery(String name, String normQ) {
    for (final String w in name.split(RegExp(r'[\s\-/,،()\[\].]+'))) {
      if (w.trim().isEmpty) continue;
      if (arabicDedupKey(w).startsWith(normQ)) return true;
    }
    return false;
  }

  /// Backend query: strip marks (keep the hamza so LIKE still matches "أرز")
  /// then drop a leading "ال" article so "الأرز" returns products named "أرز".
  String _serverQuery(String s) {
    final String t = _stripMarks(s).trim();
    if (t.startsWith('ال') && (t.length - 2) >= 3) return t.substring(2);
    return t;
  }

  /// Kitchen-tool / kitchenware keywords (already normalized: ة→ه, hamza→ا) used
  /// to rank ACTUAL food above tools that merely carry the term (e.g. real rice
  /// above "ملعقة أرز" / "مصفاة أرز" when searching "أرز").
  static const List<String> _kitchenToolWords = <String>[
    'ملعقه', 'مصفاه', 'مضرب', 'قالب', 'طقم', 'سكين', 'مقلاه', 'طنجره',
    'صينيه', 'مبشره', 'خلاط', 'عصاره', 'غلايه', 'ماكينه', 'اناء', 'وعا',
    'شوكه', 'كباب', 'مبراه', 'قدح', 'كوب', 'حافظه', 'مغرفه', 'منخل',
  ];

  /// True when the product name looks like a kitchen tool/utensil rather than a
  /// food item (used only for ranking — never to hide results).
  bool _isKitchenTool(String name) {
    final String n = _normCore(name);
    for (final String w in _kitchenToolWords) {
      if (n.contains(w)) return true;
    }
    return false;
  }

  /// Words that must never appear as a suggestion (normalized before compare).
  /// Populate with the project's profanity/blocklist terms.
  static const Set<String> _termBlocklist = <String>{};

  /// Per-section fallback suggestions (rule #3) — NEVER food for other sections.
  /// Keys are matched as substrings of the module type.
  static const Map<String, List<String>> _moduleDefaultSuggestions = {
    'pharmac': ['مسكنات', 'فيتامينات', 'عناية بالبشرة', 'مكملات', 'شامبو'],
    'grocery': ['أرز', 'حليب', 'منظفات', 'عصائر', 'سكر'],
    'ecommerce': ['أرز', 'حليب', 'منظفات', 'عصائر', 'سكر'],
    'cafe': ['قهوة', 'لاتيه', 'شاي', 'عصير', 'حلى'],
    'coffee': ['قهوة', 'لاتيه', 'شاي', 'عصير', 'حلى'],
    'food': ['برجر', 'بيتزا', 'شاورما', 'دجاج', 'مشروبات'],
  };

  List<String> _fallbackSuggestions() {
    final String type = _sectionModuleType() ?? '';
    for (final entry in _moduleDefaultSuggestions.entries) {
      if (type.contains(entry.key)) return entry.value;
    }
    return const [];
  }

  /// Cleans raw "most searched" terms (rule #2 of this task): drop < 3 chars
  /// (kills "جب/سم/كب/بي"), drop blocklisted, de-dup by normalized key
  /// ("جبن" = "جُبن" = "الجبن"), cap at 10. Keeps the original display form of
  /// the first (highest-ranked) occurrence — the API list is hit-count desc.
  List<String> _cleanPopularTerms(Iterable<String> raw) =>
      cleanPopularTerms(raw, blocklist: _termBlocklist);

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
    // Look up distance (metres) from pre-fetched branch groups.
    final double dist =
        _branchGroups[_normCore(store.name ?? '')]?.first.distance ?? 0;
    await Get.to<void>(() => MarketStoreScreen(
          storeId: store.id,
          name: store.name,
          logo: store.imageFullUrl,
          moduleId: mid ?? 3,
          distance: dist,
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
      // Most-searched keywords: scoped only when opened inside a specific
      // section; on the HOME lens (no module) we fetch cross-module popular
      // terms. Over-fetch (20) because cleaning/de-dup trims to ≤10.
      final int? mid = widget.moduleId;
      final r = await api.getData(
        '/api/v2/search/popular?limit=20'
        '${mid != null ? '&module_id=$mid' : ''}',
        useEtag: false,
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          if (mid != null) AppConstants.moduleId: mid.toString(),
        },
      );
      final dynamic body = r.body;
      final dynamic list = body is Map ? body['data'] : body;
      if (mounted && list is List) {
        _mostSearched = _cleanPopularTerms(
            list.whereType<Map>().map((e) => (e['keyword'] ?? '').toString()));
      }
    } catch (_) {}
    // Rule #3: too few terms for this section → show its OWN default list,
    // never the food default. (Only in the non-store discovery path.)
    if (_mostSearched.isEmpty) {
      _mostSearched = _fallbackSuggestions();
    }

    try {
      // The rails ("أشهر المتاجر" / "الأكثر بحثاً"). When opened from the HOME
      // lens (no explicit module) we pull stores from EVERY section and merge
      // them so the rails show a variety across restaurants/cafes/grocery/
      // pharmacy — the ApiClient injects a default module header, so we must
      // request each module explicitly. When opened inside a section
      // (widget.moduleId set) we keep the single scoped fetch.
      final List<int?> railModuleIds = widget.moduleId != null
          ? <int?>[widget.moduleId]
          : _allModuleIds();
      final List<Map<String, dynamic>> storeList = [];
      final Set<int> seenStoreIds = {};
      final bool scoped = widget.moduleId != null;
      for (final int? rmid in railModuleIds) {
        try {
          final r = await api.getData(
            '/api/v2/stores?module_id=${rmid ?? ''}&limit=${scoped ? 500 : 40}&offset=0',
            useEtag: false,
            headers: rmid != null
                ? {AppConstants.moduleId: rmid.toString()}
                : null,
          );
          final dynamic body = r.body;
          final List raw = (body is Map && body['stores'] is List)
              ? body['stores'] as List
              : (body is List ? body : const []);
          for (final e in raw.whereType<Map>()) {
            final Map<String, dynamic> m = Map<String, dynamic>.from(e);
            final int? id = int.tryParse('${m['id']}');
            if (id == null || !seenStoreIds.add(id)) continue;
            storeList.add(m);
          }
        } catch (_) {}
      }
      if (mounted) {

        _brands = storeList
            // Rule #2: a store with no logo is hidden from "popular stores".
            .where((m) => (m['logo_full_url'] ?? m['logo'] ?? '')
                .toString()
                .trim()
                .isNotEmpty)
            .map((m) => BrandModel(
                  id: int.tryParse('${m['id']}'),
                  name: m['name']?.toString(),
                  imageFullUrl: (m['logo_full_url'] ?? m['logo']).toString(),
                ))
            .toList();

        // Build branch groups (same brand name = multiple branches).
        final Map<String, List<_BranchInfo>> groups = {};
        for (final m in storeList) {
          final int? id = int.tryParse('${m['id']}');
          if (id == null) continue;
          final String name = (m['name'] ?? '').toString();
          final String? logo =
              (m['logo_full_url'] ?? m['logo'])?.toString();
          final String? deliveryTime = m['delivery_time']?.toString();
          final dynamic distRaw = m['distance'] ?? m['distance_in_meters'];
          final double? dist =
              distRaw == null ? null : double.tryParse('$distRaw');
          final bool free = m['free_delivery'] == true;
          final branch = _BranchInfo(
            id: id,
            name: name,
            logo: logo,
            deliveryTime: deliveryTime,
            distance: dist,
            freeDelivery: free,
          );
          (groups[_normCore(name)] ??= []).add(branch);
        }
        for (final k in groups.keys) {
          groups[k]!.sort(
              (a, b) => (a.distance ?? 9999.0).compareTo(b.distance ?? 9999.0));
        }
        _branchGroups = groups;
        _storeLogoById = {
          for (final branches in groups.values)
            for (final br in branches)
              if ((br.logo ?? '').isNotEmpty) br.id: br.logo!,
        };
        // Name-based map from ALL fetched stores with full URL resolution.
        _storeLogoByName = {};
        for (final m in storeList) {
          final name = (m['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          String? logo = m['logo_full_url']?.toString();
          if ((logo ?? '').isEmpty) {
            final raw = (m['logo'] ?? '').toString().trim();
            if (raw.isNotEmpty) {
              if (raw.startsWith('http://') || raw.startsWith('https://')) {
                logo = raw;
              } else if (raw.startsWith('/')) {
                logo = '${AppConstants.baseUrl}$raw';
              } else {
                logo = '${AppConstants.storageBaseUrl}/$raw';
              }
            }
          }
          if ((logo ?? '').isNotEmpty) {
            _storeLogoByName[_normCore(name)] = logo!;
          }
        }

        // «الأكثر بحثًا» = this section's STORE names (e.g. restaurants), up to
        // 12 — tapping one opens that store, and a name search surfaces it.
        final List<String> storeNames = _brands
            .map((b) => (b.name ?? '').trim())
            .where((n) => n.isNotEmpty)
            .toList();
        if (storeNames.isNotEmpty) {
          _mostSearched =
              storeNames.length > 12 ? storeNames.sublist(0, 12) : storeNames;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingDiscovery = false);
  }

  void _search(String query) {
    final text = query.trim();
    if (text.isEmpty) return;
    if (_controller.text != text) _controller.text = text;
    FocusScope.of(context).unfocus();
    // Save the real (submitted) term to recent history — not live typing.
    if (Get.isRegistered<srch.SearchController>()) {
      final sc = Get.find<srch.SearchController>();
      sc.saveSearch(text);
      _recent = List<String>.from(sc.historyList);
    }
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
                  : _controller.text.trim().isNotEmpty
                      ? _buildSuggestions()
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
                              // Order: خدماتنا (all modules) → recent searches →
                              // most-searched (module-scoped) → popular stores.
                              // "خدماتنا" services grid — tapping a service (e.g.
                              // هايبر شله) opens its storefront. Global search only.
                              if (widget.storeId == null)
                                const HomeServicesGrid(),
                              _buildRecentSection(),
                              // Global discovery rails are hidden for store-scoped
                              // search (they list cross-store/restaurant content
                              // that is irrelevant inside a single store).
                              if (widget.storeId == null)
                                _buildMostSearchedSection(),
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
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2421),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'GO',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
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

  Widget _chip(String label,
      {bool highlight = false, VoidCallback? onTap, VoidCallback? onDelete}) {
    final Widget text = Text(
      label,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 1.4,
        color: highlight ? const Color(0xFF1F7A35) : _chipText,
      ),
    );
    return InkWell(
      onTap: onTap ?? () => _search(label),
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        padding: EdgeInsets.only(
            right: 14, left: onDelete != null ? 8 : 14, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFE7F7EA) : _chipBg,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: onDelete == null
            ? text
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  text,
                  const SizedBox(width: 6),
                  // Per-chip delete (×) for recent searches.
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(20),
                    child: Icon(Icons.close,
                        size: 15, color: _chipText.withValues(alpha: 0.55)),
                  ),
                ],
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

  // Removes a single recent-search term (× on the chip).
  void _removeRecent(String term) {
    if (!Get.isRegistered<srch.SearchController>()) return;
    final sc = Get.find<srch.SearchController>();
    final int idx = sc.historyList.indexOf(term);
    if (idx >= 0) sc.removeHistory(idx);
    setState(() => _recent = List<String>.from(sc.historyList));
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
          children: _recent.reversed
              .map((term) => _chip(term, onDelete: () => _removeRecent(term)))
              .toList(),
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
                      // Store names open the store directly; otherwise search.
                      final BrandModel? store = _storeByName(k);
                      if (store != null) {
                        _openBrand(store);
                      } else {
                        setState(() => _selectedKeyword = k);
                        _search(k);
                      }
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── Suggestions (shown while debounce is running / before first search) ──

  Widget _buildSuggestions() {
    final String q = _normCore(_controller.text.trim());
    // (text, optional brand): brand present → open store directly; null → search.
    final List<(String, BrandModel?)> prefix = [];
    final List<(String, BrandModel?)> mid = [];
    final Set<String> seen = {};

    void add(String text, BrandModel? brand) {
      final norm = _normCore(text);
      if (text.isEmpty || !seen.add(norm)) return;
      final item = (text, brand);
      if (norm.startsWith(q)) {
        prefix.add(item);
      } else if (norm.contains(q)) {
        mid.add(item);
      }
    }

    // Priority: recent → stores → popular terms.
    for (final r in _recent.reversed) { add(r, null); }
    for (final b in _brands) { add(b.name ?? '', b); }
    for (final t in _mostSearched) { add(t, null); }

    final limited = [...prefix, ...mid].take(10).toList();

    if (limited.isEmpty) {
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: limited.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        indent: 20,
        endIndent: 20,
        color: Color(0xFFF2F2F4),
      ),
      itemBuilder: (_, i) {
        final (text, brand) = limited[i];
        final logo = brand?.imageFullUrl;
        return InkWell(
          onTap: brand != null ? () => _openBrand(brand) : () => _search(text),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault, vertical: 10),
            child: Row(
              children: [
                // Leading: store logo or search icon.
                if ((logo ?? '').isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomImage(
                      image: logo!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(Icons.search, size: 18, color: Color(0xFF9AA0A6)),
                const Spacer(),
                // Text with the matched prefix highlighted in green.
                Flexible(child: _highlightPrefix(text, q)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Renders [text] with the leading [normQ]-length portion highlighted green.
  Widget _highlightPrefix(String text, String normQ) {
    if (normQ.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: _chipText,
        ),
      );
    }
    final norm = _normCore(text);
    final bool isPrefix = norm.startsWith(normQ);
    // Approximate highlight length: use the raw query length as a char count.
    final int hl =
        isPrefix ? _controller.text.trim().length.clamp(0, text.length) : 0;
    if (hl == 0) {
      return Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: _chipText,
        ),
      );
    }
    return RichText(
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, hl),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF31A342),
            ),
          ),
          TextSpan(
            text: text.substring(hl),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: _chipText,
            ),
          ),
        ],
      ),
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
    if (_results.isEmpty && _storeMatches.isEmpty) {
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

    // Result tabs: الكل / متاجر / منتجات.
    // Tab 3 = "عروض": only discounted products, no store cards.
    final bool isOffersTab = _resultTab == 3;
    final List<_SearchProduct> productList = isOffersTab
        ? _results.where((p) => p.discount > 0).toList()
        : _results;
    final bool showProducts = _resultTab != 1 && productList.isNotEmpty;

    // Group products by store.
    final Map<int?, List<_SearchProduct>> groups = {};
    for (final p in productList) {
      (groups[p.storeId] ??= <_SearchProduct>[]).add(p);
    }

    // Sort groups: stores whose NAME contains the query appear before stores
    // where only a product name matched (e.g. "البيك" store before سويت هوم
    // whose product "سينابون البيكان" merely contains "البيك" as a substring).
    final String q = _normCore(_controller.text.trim());
    final List<MapEntry<int?, List<_SearchProduct>>> sortedGroups =
        groups.entries.toList()
          ..sort((a, b) {
            final an = _normCore(a.value.first.storeName ?? '');
            final bn = _normCore(b.value.first.storeName ?? '');
            // Exact store-name match → 0, starts-with → 1, contains → 2, no match → 3
            int score(String name) {
              if (name == q) return 0;
              if (name.startsWith(q)) return 1;
              if (name.contains(q)) return 2;
              return 3;
            }

            return score(an).compareTo(score(bn));
          });

    // Stores for the "متاجر" tab: name-matched stores PLUS every store that has
    // a matching product — so searching "دجاج" surfaces the restaurants (and
    // other sections) that serve it, not just هايبر. De-duped by store id.
    // On "الكل" we keep only the name-matched stores (the rest already appear as
    // product-group headers) to avoid showing each store twice.
    final List<BrandModel> allStoresWithMatch = [..._storeMatches];
    final Set<int?> shownStoreIds = _storeMatches.map((s) => s.id).toSet();
    for (final entry in sortedGroups) {
      final _SearchProduct first = entry.value.first;
      if (first.storeId != null && !shownStoreIds.contains(first.storeId)) {
        shownStoreIds.add(first.storeId);
        allStoresWithMatch.add(BrandModel(
          id: first.storeId,
          name: first.storeName,
          imageFullUrl:
              _resolvedLogo(first.storeId, first.storeName, first.storeLogo),
        ));
      }
    }
    final List<BrandModel> storesToShow =
        _resultTab == 1 ? allStoresWithMatch : _storeMatches;
    final bool showStores =
        _resultTab != 2 && !isOffersTab && storesToShow.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
      ),
      children: [
        _buildResultTabs(),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        // Matching stores (restaurants) first — tap to open the store.
        if (showStores) for (final s in storesToShow) _storeMatchCard(s),
        if (showProducts)
          for (final entry in sortedGroups) _storeGroup(entry.value),
        if (!showStores && !showProducts)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Text('no_data_found'.tr,
                  style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: _chipText)),
            ),
          ),
      ],
    );
  }

  /// Segmented tabs above the results: الكل / متاجر / منتجات / عروض.
  Widget _buildResultTabs() {
    final bool isArabic = Get.locale?.languageCode == 'ar';
    final labels = isArabic
        ? ['الكل', 'متاجر', 'منتجات', 'عروض']
        : ['All', 'Stores', 'Products', 'Offers'];
    // Horizontally scrollable so the 4 tabs never overflow on narrow screens.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final bool active = _resultTab == i;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => setState(() => _resultTab = i),
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).primaryColor
                      : const Color(0xFFF1F2F4),
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: active ? Colors.white : _chipText,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// A tappable row for a store whose name matched the query (opens the store).
  Widget _storeMatchCard(BrandModel store) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openBrand(store),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E8EC)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImage(
                  image: store.imageFullUrl ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  store.name ?? '',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _chipText,
                  ),
                ),
              ),
              const Icon(Icons.chevron_left,
                  size: 20, color: Color(0xFF9AA0A6)),
            ],
          ),
        ),
      ),
    );
  }

  /// A store header + a 3-column grid of its matched products, in one card.
  Widget _storeGroup(List<_SearchProduct> items) {
    final _SearchProduct first = items.first;
    final String name = first.storeName ?? '';
    final double? rating = first.avgRating;
    final String? deliveryTime = first.deliveryTime;
    final int? storeId = first.storeId;
    // Nearest branch distance from pre-fetched store list (sorted closest first).
    final List<_BranchInfo> branches = _branchGroups[_normCore(name)] ?? [];
    final double? distance = branches.isNotEmpty ? branches.first.distance : null;

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
            logo: _resolvedLogo(storeId, name, first.storeLogo),
            name: name,
            description: null,
            rating: rating,
            deliveryTime: deliveryTime,
            freeDelivery: first.freeDelivery,
            distance: distance,
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
          _buildBranchesButton(first.storeName ?? ''),
        ],
      ),
    );
  }

  Widget _buildBranchesButton(String storeName) {
    final List<_BranchInfo> branches =
        _branchGroups[_normCore(storeName)] ?? [];
    if (branches.length <= 1) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: Dimensions.paddingSizeSmall),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F4)),
        InkWell(
          onTap: () => _showBranchesModal(branches, storeName),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chevron_left,
                    size: 18, color: Color(0xFF31A342)),
                const SizedBox(width: 4),
                Text(
                  'عرض جميع الفروع ${branches.length}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF31A342),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBranchesModal(List<_BranchInfo> branches, String storeName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(Icons.close, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      '${branches.length} فرع',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: _titleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F4)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    color: Color(0xFFF2F2F4),
                  ),
                  itemBuilder: (_, i) => _branchCard(branches[i], ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _branchCard(_BranchInfo branch, BuildContext sheetCtx) {
    return InkWell(
      onTap: () {
        Navigator.of(sheetCtx).pop();
        Get.toNamed(RouteHelper.getStoreRoute(id: branch.id, page: 'store'));
      },
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomImage(
                image: branch.logo ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    branch.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (branch.freeDelivery)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F7EA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'توصيل مجاني',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF31A342),
                            ),
                          ),
                        ),
                      if ((branch.deliveryTime ?? '').isNotEmpty)
                        _infoPill(
                          image: Images.time_v2,
                          fallbackIcon: Icons.access_time,
                          label: branch.deliveryTime!,
                        ),
                      if (branch.distance != null && branch.distance! > 0)
                        _infoPill(
                          image: Images.distance,
                          fallbackIcon: Icons.near_me_outlined,
                          label: branch.distance! < 1000
                              ? '${branch.distance!.round()} م'
                              : '${(branch.distance! / 1000).toStringAsFixed(1)} كم',
                        ),
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

  Widget _storeHeader({
    required int? storeId,
    required String? logo,
    required String name,
    required String? description,
    required double? rating,
    required String? deliveryTime,
    required bool freeDelivery,
    double? distance,
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
                    // Distance pill (green, same style as rating).
                    if (distance != null && distance > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF31A342),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              distance < 1000
                                  ? '${distance.round()} م'
                                  : '${(distance / 1000).toStringAsFixed(1)} كم',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                height: 1,
                                color: Colors.white,
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

/// Lightweight store/branch info used for the "عرض جميع الفروع" bottom-sheet.
class _BranchInfo {
  final int id;
  final String name;
  final String? logo;
  final String? deliveryTime;
  final double? distance;
  final bool freeDelivery;

  const _BranchInfo({
    required this.id,
    required this.name,
    this.logo,
    this.deliveryTime,
    this.distance,
    this.freeDelivery = false,
  });
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

  static String? _resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    // Absolute path (e.g. /storage/store/logo.jpg) — prepend domain only.
    if (raw.startsWith('/')) return '${AppConstants.baseUrl}$raw';
    // Relative path (e.g. store/logo.jpg) — prepend storage base.
    return '${AppConstants.storageBaseUrl}/$raw';
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  static int? _toInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());

  factory _SearchProduct.fromJson(Map<String, dynamic> j) {
    return _SearchProduct(
      id: _toInt(j['id']),
      name: j['name']?.toString(),
      imageUrl:
          _resolveUrl((j['image_full_url'] ?? j['image'])?.toString()),
      price: _toDouble(j['price']),
      discount: _toDouble(j['discount']),
      discountType: j['discount_type']?.toString(),
      storeId: _toInt(j['store_id']),
      storeName: j['store_name']?.toString(),
      storeLogo: _resolveUrl(
          (j['store_logo_full_url'] ?? j['store_logo_url'] ?? j['store_logo'])
              ?.toString()),
      moduleType: j['module_type']?.toString(),
      deliveryTime: j['delivery_time']?.toString(),
      avgRating: j['avg_rating'] == null ? null : _toDouble(j['avg_rating']),
      freeDelivery: j['free_delivery'] == true,
    );
  }
}
