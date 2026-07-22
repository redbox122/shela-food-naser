part of 'market_store_screen.dart';

// ─── Product options sheet (Screen 2) ────────────────────────────────────────

/// One selectable option inside a group (e.g. "ماك تشيكن", +2 ﷼).
class _OptItem {
  final String name;
  final double price;
  final double calories;

  /// Pre-selected when the sheet opens (DB `is_default`).
  final bool isDefault;

  /// Available to pick — a sold-out option is shown greyed and disabled
  /// (DB `is_available`, defaults to true when the field is absent).
  final bool available;

  const _OptItem({
    required this.name,
    this.price = 0,
    this.calories = 0,
    this.isDefault = false,
    this.available = true,
  });

  factory _OptItem.fromJson(Map<String, dynamic> j) => _OptItem(
        name: (j['name'] ?? '').toString(),
        price: double.tryParse('${j['price'] ?? 0}') ?? 0,
        calories: double.tryParse('${j['calories'] ?? 0}') ?? 0,
        isDefault: j['is_default'] == true || j['is_default'] == 1,
        available: j['is_available'] == null
            ? true
            : (j['is_available'] == true || j['is_available'] == 1),
      );
}

/// A normalized option group from the API's `option_groups`
/// ({name, type single|multi, required, min, max, options}).
class _OptGroup {
  final String name;
  final bool multi;
  final bool required;
  final int min;
  final int max;

  /// 'replace' → the chosen option IS the price (size tiers); 'add' → its price
  /// is added on top of the base (choices/add-ons).
  final bool replacePrice;
  final List<_OptItem> options;

  const _OptGroup({
    required this.name,
    required this.multi,
    required this.required,
    required this.min,
    required this.max,
    required this.replacePrice,
    required this.options,
  });

  factory _OptGroup.fromJson(Map<String, dynamic> j) {
    final opts = (j['options'] is List)
        ? (j['options'] as List)
            .whereType<Map>()
            .map((e) => _OptItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <_OptItem>[];
    return _OptGroup(
      name: (j['name'] ?? '').toString(),
      multi: (j['type'] ?? 'single').toString() == 'multi',
      required: j['required'] == true,
      min: int.tryParse('${j['min'] ?? 0}') ?? 0,
      max: int.tryParse('${j['max'] ?? 1}') ?? 1,
      replacePrice: (j['price_mode'] ?? 'add').toString() == 'replace',
      options: opts,
    );
  }
}

/// Opens the product options sheet. Falls back to a quick add when the item has
/// no options (resolved after the detail loads).
Future<void> showProductOptions({
  required int itemId,
  int? storeId,
  required int moduleId,
  String? name,
  String? image,
  double price = 0,
  // When true (restaurant meals), ALWAYS open the details/customization sheet
  // on tap — never quick-add — so the customer sees ingredients + options.
  bool alwaysShowSheet = false,
}) async {
  // Resolve the item's options FIRST. No required options → add straight to the
  // cart with NO sheet (fixes the janky half-loaded sheet). Otherwise open the
  // sheet as before, with the already-fetched data preloaded (no double fetch).
  final resolved = await _resolveItemOptions(itemId: itemId, moduleId: moduleId);
  if (!alwaysShowSheet && resolved != null && resolved.groups.isEmpty) {
    final double p = double.tryParse('${resolved.data['price'] ?? 0}') ?? 0;
    await _quickAddToCart(
      itemId: itemId,
      storeId: storeId,
      moduleId: resolved.module,
      price: p > 0 ? p : price,
    );
    return;
  }
  Get.bottomSheet(
    _ProductOptionsSheet(
      itemId: itemId,
      storeId: storeId,
      moduleId: moduleId,
      initialName: name,
      initialImage: image,
      initialPrice: price,
      preloadedData: resolved?.data,
      preloadedGroups: resolved?.groups,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

({List<_OptGroup> groups, Map<String, dynamic> data, int module})? _parseResolved(
    Response r, int module) {
  final body = r.body;
  if (body is Map && body['name'] != null && body['id'] != null) {
    final data = Map<String, dynamic>.from(body);
    final groups = (data['option_groups'] is List)
        ? (data['option_groups'] as List)
            .whereType<Map>()
            .map((e) => _OptGroup.fromJson(Map<String, dynamic>.from(e)))
            .where((g) => g.options.isNotEmpty)
            .toList()
        : <_OptGroup>[];
    return (groups: groups, data: data, module: module);
  }
  return null;
}

/// Headless resolve of an item's option groups, run BEFORE opening anything so
/// the caller can decide quick-add vs sheet. The v2 details endpoint is
/// MODULE-SCOPED and returns empty for items whose module differs from the
/// active one (e.g. a food meal while a grocery module is active — the food v1
/// endpoint also 403s), so we try WITHOUT a module id first (resolves any item
/// by id), then fall back to module-scoped candidates.
Future<({List<_OptGroup> groups, Map<String, dynamic> data, int module})?>
    _resolveItemOptions(
        {required int itemId, required int moduleId}) async {
  if (!Get.isRegistered<ApiClient>()) return null;
  final api = Get.find<ApiClient>();
  const String uri = '/api/v2/items/details/';
  try {
    final r = await api.getData(
      '$uri$itemId',
      headers: {AppConstants.localizationKey: AppConstants.currentLanguageCode},
      useEtag: false,
      omitModuleId: true,
    );
    final res = _parseResolved(r, moduleId);
    if (res != null) return res;
  } catch (_) {}
  try {
    for (final mod in _moduleCandidatesFor(moduleId)) {
      final r = await api.getData(
        '$uri$itemId',
        headers: {
          AppConstants.localizationKey: AppConstants.currentLanguageCode,
          AppConstants.moduleId: mod.toString(),
        },
        useEtag: false,
      );
      final res = _parseResolved(r, mod);
      if (res != null) return res;
    }
  } catch (_) {}
  return null;
}

/// Top-level twin of the sheet's _moduleCandidates (same order: given → food →
/// ecommerce → all) — used by the headless resolve.
List<int> _moduleCandidatesFor(int moduleId) {
  final out = <int>[];
  void add(int? m) {
    if (m != null && m > 0 && !out.contains(m)) out.add(m);
  }

  add(moduleId);
  if (Get.isRegistered<SplashController>()) {
    final modules = Get.find<SplashController>().moduleList ?? const [];
    for (final m in modules) {
      if ((m.moduleType ?? '').toLowerCase() == 'food') add(m.id);
    }
    for (final m in modules) {
      if ((m.moduleType ?? '').toLowerCase() == 'ecommerce') add(m.id);
    }
    for (final m in modules) {
      add(m.id);
    }
  }
  if (out.isEmpty) out.add(moduleId);
  return out;
}

/// Guests need a server-assigned `guest_id` before the cart accepts items
/// (otherwise the v2 cart API 422s with `guest_id_required`). Create one on the
/// fly when missing — no-op for logged-in users and guests who already have one.
Future<void> _ensureGuestSession() async {
  if (AuthHelper.isLoggedIn()) return;
  if (AuthHelper.getGuestId().isNotEmpty) return;
  if (!Get.isRegistered<AuthController>()) return;
  await Get.find<AuthController>().guestLogin();
}

/// Add an item that has NO required options straight to the cart — no sheet.
/// Mirrors the sheet's _add() minus variations; reuses the shared clear-cart
/// confirm + "added" toast.
Future<void> _quickAddToCart({
  required int itemId,
  int? storeId,
  required int moduleId,
  required double price,
}) async {
  if (!Get.isRegistered<CartController>()) return;
  await _ensureGuestSession();
  final cartController = Get.find<CartController>();
  if (cartController.existAnotherStoreItem(storeId, moduleId)) {
    if (!await _confirmClearCart()) return;
    await cartController.clearCartList();
  }
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
    itemId,
    null,
    price.toString(),
    '',
    const [],
    const [],
    1,
    const [],
    const [],
    const [],
    'Item',
    itemType: 'Item',
    storeId: storeId,
  );
  try {
    bool ok = await cartController.addToCartOnline(cart);
    if (!ok && cartController.lastAddToCartErrorCode == 'different_store') {
      if (!await _confirmClearCart()) return;
      await cartController.clearCartList();
      ok = await cartController.addToCartOnline(cart);
    }
    ok
        ? _showAddedToCartToast()
        : showCustomSnackBar('failed_to_add_to_cart'.tr, isError: true);
  } catch (e) {
    showCustomSnackBar(e.toString(), isError: true);
  }
}

class _ProductOptionsSheet extends StatefulWidget {
  final int itemId;
  final int? storeId;
  final int moduleId;
  final String? initialName;
  final String? initialImage;
  final double initialPrice;

  /// Pre-fetched detail + groups from [_resolveItemOptions] → the sheet skips
  /// its own network fetch (no double request). Null → fetch as before.
  final Map<String, dynamic>? preloadedData;
  final List<_OptGroup>? preloadedGroups;

  const _ProductOptionsSheet({
    required this.itemId,
    required this.storeId,
    required this.moduleId,
    this.initialName,
    this.initialImage,
    this.initialPrice = 0,
    this.preloadedData,
    this.preloadedGroups,
  });

  @override
  State<_ProductOptionsSheet> createState() => _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends State<_ProductOptionsSheet> {
  bool _loading = true;
  String? _name;
  String? _description;
  String? _image;
  double _basePrice = 0;
  List<_OptGroup> _groups = const [];

  /// Per-group selected option indices (a Set so single + multi share the model).
  late List<Set<int>> _selected;

  /// Groups flagged invalid after a failed add attempt (highlighted red).
  final Set<int> _invalid = {};

  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
    _image = widget.initialImage;
    _basePrice = widget.initialPrice;
    _selected = [];
    if (widget.preloadedData != null && widget.preloadedGroups != null) {
      // Already resolved by the caller — populate directly, no network fetch.
      _applyDetail(widget.preloadedData!, widget.preloadedGroups!);
    } else {
      _fetch();
    }
  }

  /// Candidate modules to try (the item-details index is module-scoped and the
  /// passed module can be wrong): the given one, then food, then ecommerce,
  /// then every loaded module — stopping at the first that resolves the item.
  List<int> _moduleCandidates() {
    final out = <int>[];
    void add(int? m) {
      if (m != null && m > 0 && !out.contains(m)) out.add(m);
    }

    add(widget.moduleId);
    if (Get.isRegistered<SplashController>()) {
      final modules = Get.find<SplashController>().moduleList ?? const [];
      for (final m in modules) {
        if ((m.moduleType ?? '').toLowerCase() == 'food') add(m.id);
      }
      for (final m in modules) {
        if ((m.moduleType ?? '').toLowerCase() == 'ecommerce') add(m.id);
      }
      for (final m in modules) {
        add(m.id);
      }
    }
    if (out.isEmpty) out.add(widget.moduleId);
    return out;
  }

  Future<void> _fetch() async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      Map<String, dynamic>? m;
      for (final mod in _moduleCandidates()) {
        final r = await Get.find<ApiClient>().getData(
          '/api/v2/items/details/${widget.itemId}',
          headers: {
            AppConstants.localizationKey: AppConstants.currentLanguageCode,
            AppConstants.moduleId: mod.toString(),
          },
          useEtag: false,
        );
        final body = r.body;
        if (body is Map && body['name'] != null && body['id'] != null) {
          m = Map<String, dynamic>.from(body);
          break;
        }
      }
      if (m != null) {
        final data = m;
        final groups = (data['option_groups'] is List)
            ? (data['option_groups'] as List)
                .whereType<Map>()
                .map((e) => _OptGroup.fromJson(Map<String, dynamic>.from(e)))
                .where((g) => g.options.isNotEmpty)
                .toList()
            : <_OptGroup>[];
        if (mounted) setState(() => _applyDetail(data, groups));
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Populate the sheet from a resolved detail payload + parsed groups. Shared by
  /// the network [_fetch] and the preloaded path (initState) so both behave
  /// identically. Call inside setState (or before first build in initState).
  void _applyDetail(Map<String, dynamic> data, List<_OptGroup> groups) {
    _name = (data['name'] ?? _name)?.toString();
    _description = data['description']?.toString();
    _image = (data['image_full_url'] ?? _image)?.toString();
    _basePrice = double.tryParse('${data['price'] ?? _basePrice}') ?? _basePrice;
    _groups = groups;
    // Pre-select options flagged `is_default`, capped at the group's max; then,
    // for a required single group with no default, fall back to its first
    // available option so the sheet opens valid.
    _selected = List.generate(groups.length, (i) {
      final g = groups[i];
      final defaults = <int>{};
      for (int oi = 0; oi < g.options.length; oi++) {
        final o = g.options[oi];
        if (!o.isDefault || !o.available) continue;
        if (g.multi) {
          if (g.max > 0 && defaults.length >= g.max) break;
          defaults.add(oi);
        } else {
          defaults
            ..clear()
            ..add(oi);
          break; // single keeps exactly one
        }
      }
      if (defaults.isEmpty && !g.multi && g.required) {
        final first = g.options.indexWhere((o) => o.available);
        if (first >= 0) defaults.add(first);
      }
      return defaults;
    });
    _loading = false;
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void _toggle(int gi, int oi) {
    final g = _groups[gi];
    if (!g.options[oi].available) return; // sold-out option is not selectable
    setState(() {
      final sel = _selected[gi];
      if (g.multi) {
        if (sel.contains(oi)) {
          sel.remove(oi);
        } else {
          if (g.max > 0 && sel.length >= g.max) return; // respect max
          sel.add(oi);
        }
      } else {
        sel
          ..clear()
          ..add(oi);
      }
      _invalid.remove(gi);
    });
  }

  /// Required groups that don't meet their minimum selection.
  List<int> get _missing {
    final out = <int>[];
    for (int i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      final needed = g.required ? (g.min < 1 ? 1 : g.min) : 0;
      if (needed > 0 && _selected[i].length < needed) out.add(i);
    }
    return out;
  }

  double get _unitPrice {
    double base = _basePrice;
    double extra = 0;
    for (int i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      for (final oi in _selected[i]) {
        if (g.replacePrice) {
          base = g.options[oi].price;
        } else {
          extra += g.options[oi].price;
        }
      }
    }
    return base + extra;
  }

  Future<void> _add() async {
    final miss = _missing;
    if (miss.isNotEmpty) {
      setState(() => _invalid
        ..clear()
        ..addAll(miss));
      showCustomSnackBar('يرجى اختيار الخيارات المطلوبة', isError: true);
      return;
    }
    if (!Get.isRegistered<CartController>()) return;
    await _ensureGuestSession();
    final cartController = Get.find<CartController>();

    // Build the selected option groups as cart variations so the merchant sees
    // exactly what the customer chose.
    final List<OrderVariation> variations = [];
    for (int i = 0; i < _groups.length; i++) {
      if (_selected[i].isEmpty) continue;
      final g = _groups[i];
      variations.add(OrderVariation(
        name: g.name,
        values: OrderVariationValue(
          options: _selected[i]
              .map((oi) => VariationOption(
                    label: g.options[oi].name,
                    optionPrice: g.options[oi].price,
                  ))
              .toList(),
        ),
      ));
    }

    // The cart holds one store/module at a time — confirm clearing if needed.
    if (cartController.existAnotherStoreItem(widget.storeId, widget.moduleId)) {
      final bool confirmed = await _confirmClearCart();
      if (!confirmed) return;
      await cartController.clearCartList();
    }
    // Align the active + cache module with the item's module (cart keys on it).
    if (Get.isRegistered<SplashController>()) {
      final sc = Get.find<SplashController>();
      for (final m in sc.moduleList ?? const []) {
        if (m.id == widget.moduleId) {
          if (sc.module?.id != widget.moduleId) {
            await sc.setModuleHeaderOnly(m);
          }
          await sc.setCacheModuleOnly(m);
          break;
        }
      }
    }

    final cart = OnlineCart(
      null,
      widget.itemId,
      null,
      _unitPrice.toString(),
      '',
      const [],
      variations.isEmpty ? const [] : variations,
      _qty,
      const [],
      const [],
      const [],
      'Item',
      itemType: 'Item',
      storeId: widget.storeId,
    );

    try {
      bool ok = await cartController.addToCartOnline(cart);
      if (!ok && cartController.lastAddToCartErrorCode == 'different_store') {
        final bool confirmed = await _confirmClearCart();
        if (!confirmed) return;
        await cartController.clearCartList();
        ok = await cartController.addToCartOnline(cart);
      }
      if (!ok) {
        // Keep the sheet open so the user sees it didn't add (e.g. on a
        // network failure) instead of a silent close + toast.
        showCustomSnackBar('failed_to_add_to_cart'.tr, isError: true);
      } else {
        Get.back<void>();
        _showAddedToCartToast();
      }
    } catch (e) {
      showCustomSnackBar(e.toString(), isError: true);
    }
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(color: Color(0xFF30913F)),
            )
          else
            Flexible(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _hero(),
                  if ((_description ?? '').trim().isNotEmpty) _descBlock(),
                  for (int i = 0; i < _groups.length; i++) _groupBlock(i),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          if (!_loading) _bottomBar(),
        ],
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Row(
          children: [
            InkWell(
              onTap: () => Get.back<void>(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F2F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20),
              ),
            ),
            Expanded(
              child: Text(
                _name ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF121C19),
                ),
              ),
            ),
            const SizedBox(width: 34),
          ],
        ),
      );

  Widget _hero() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomImage(
                image: _image ?? '',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                placeholder: Images.placeholder,
              ),
            ),
          ],
        ),
      );

  Widget _descBlock() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          _description!.trim(),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF8A8F99),
          ),
        ),
      );

  Widget _groupBlock(int gi) {
    final g = _groups[gi];
    final bool invalid = _invalid.contains(gi);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      // Required groups get the light-yellow "must choose" background; optional
      // groups stay white — matches the reference McDonald's design.
      color: g.required ? const Color(0xFFFFFBE6) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group header: name + (required/optional tag) + choose-one/many hint.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                // "مطلوب" (orange + info icon) for required groups; "اختياري"
                // (gray) for optional groups.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: g.required
                        ? (invalid
                            ? const Color(0xFFFDE7E9)
                            : const Color(0xFFFFF3CD))
                        : const Color(0xFFF0F1F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (g.required) ...[
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: invalid
                              ? const Color(0xFFE23B4E)
                              : const Color(0xFFE8912A),
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        g.required ? 'مطلوب' : 'اختياري',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: g.required
                              ? (invalid
                                  ? const Color(0xFFE23B4E)
                                  : const Color(0xFFE8912A))
                              : const Color(0xFF717885),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        g.name,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: invalid
                              ? const Color(0xFFE23B4E)
                              : const Color(0xFF121C19),
                        ),
                      ),
                      Text(
                        g.multi
                            ? (g.max > 0 ? 'حتى ${g.max}' : 'اختياري')
                            : 'اختر 1',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: Color(0xFFB0B4BB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (int oi = 0; oi < g.options.length; oi++) _optionRow(gi, oi),
        ],
      ),
    );
  }

  Widget _optionRow(int gi, int oi) {
    final g = _groups[gi];
    final o = g.options[oi];
    final bool on = _selected[gi].contains(oi);
    // Disabled when the option is sold out, or when an unselected option would
    // exceed a multi group's max (the user must deselect another first).
    final bool atMax =
        g.multi && g.max > 0 && !on && _selected[gi].length >= g.max;
    final bool disabled = !o.available || atMax;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: disabled ? null : () => _toggle(gi, oi),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Selector (left): radio for single, checkbox for multi.
              _selector(on: on, multi: g.multi),
              const SizedBox(width: 12),
              if (o.price > 0)
                Text(
                  '+ ${_fmt(o.price)}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF30913F),
                  ),
                ),
              const Spacer(),
              Expanded(
                flex: 5,
                child: Text(
                  o.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF121C19),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selector({required bool on, required bool multi}) {
    const Color active = Color(0xFF30913F);
    if (multi) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: on ? active : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: on ? active : const Color(0xFFC9CDD3), width: 2),
        ),
        child: on
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : null,
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: on ? active : const Color(0xFFC9CDD3), width: 2),
      ),
      child: on
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: active, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }

  Widget _bottomBar() {
    final total = _unitPrice * _qty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            // Add button with the live total.
            Expanded(
              child: Material(
                color: const Color(0xFF30913F),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _add,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_fmt(total)} ﷼',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'إضافة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Quantity stepper.
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _stepBtn(Icons.add, () => setState(() => _qty++)),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$_qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _stepBtn(Icons.remove,
                      () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 20, color: const Color(0xFF121C19)),
        ),
      );
}
