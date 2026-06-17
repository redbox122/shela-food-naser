import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// Active/selected pill colours (light green bg + green fg).
const Color _activeBg = Color(0xFFE7F7EA);
const Color _activeFg = Color(0xFF1F7A35);

/// Default (idle) pill colours (light grey bg + dark fg, no visible border).
const Color _idleBg = Color(0xFFF6F5F8);
const Color _idleBorder = Color(0xFFF6F5F8);
const Color _idleFg = Color(0xFF121C19);

/// Lightweight store-category option for the dropdown.
class _Cat {
  final int? id;
  final String? name;
  _Cat({this.id, this.name});
  factory _Cat.fromJson(Map<String, dynamic> j) => _Cat(
        id: int.tryParse('${j['id']}'),
        name: j['name']?.toString(),
      );
}

/// 🎨 REDESIGN (Market): horizontal filter chips shown above the stores list.
///
/// Two chip kinds:
///  - dropdown chips (store category / sort) — trailing chevron, open an
///    anchored panel below the bar.
///  - toggle chips (offers / top-rated / free delivery / 30-min / open now)
///    that switch to the active green pill when selected.
///
/// Toggle selection is reported via [onChanged]; the chosen store category via
/// [onCategoryChanged].
class MarketStoreFilters extends StatefulWidget {
  final int? moduleId;

  /// Selected category from the shared source (top rail / this dropdown).
  final int? selectedCategoryId;
  final ValueChanged<Set<String>>? onChanged;
  final ValueChanged<int?>? onCategoryChanged;

  const MarketStoreFilters({
    super.key,
    this.moduleId,
    this.selectedCategoryId,
    this.onChanged,
    this.onCategoryChanged,
  });

  @override
  State<MarketStoreFilters> createState() => _MarketStoreFiltersState();
}

class _MarketStoreFiltersState extends State<MarketStoreFilters> {
  final Set<String> _active = <String>{};

  // Store-category bottom-sheet state.
  List<_Cat> _categories = const [];
  bool _categoriesLoaded = false;
  bool _categoryOpen = false;
  Future<void>? _categoriesFuture;

  /// Selection is owned by the parent; read it from the widget.
  int? get _selectedCategoryId => widget.selectedCategoryId;

  /// Resolved name for the selected category (once categories are loaded).
  String? get _selectedCategoryName {
    final id = _selectedCategoryId;
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Load categories up front so the chip can show the selected name even
    // when the choice came from the top categories rail.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCategories());
  }

  void _toggle(String key) {
    setState(() {
      _active.contains(key) ? _active.remove(key) : _active.add(key);
    });
    widget.onChanged?.call(Set.unmodifiable(_active));
  }

  /// Loads the categories once; concurrent callers share the in-flight future.
  Future<void> _ensureCategories() {
    if (_categoriesLoaded) return Future<void>.value();
    return _categoriesFuture ??= _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if (!Get.isRegistered<ApiClient>()) return;
    try {
      final response = await Get.find<ApiClient>().getData(
        '/api/v2/categories',
        headers: {
          AppConstants.localizationKey: 'ar',
          if (widget.moduleId != null)
            AppConstants.moduleId: widget.moduleId.toString(),
        },
        useEtag: false,
      );
      final dynamic body = response.body;
      final List raw = body is List
          ? body
          : (body is Map && body['data'] is List)
              ? body['data'] as List
              : (body is Map && body['categories'] is List)
                  ? body['categories'] as List
                  : const [];
      _categories = raw
          .whereType<Map>()
          .map((e) => _Cat.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      _categories = const [];
    }
    _categoriesLoaded = true;
    // Rebuild the chip row so the selected category name can resolve.
    if (mounted) setState(() {});
  }

  /// Opens the store-category picker as a modal bottom sheet.
  Future<void> _openCategorySheet() async {
    setState(() => _categoryOpen = true);
    // Kick off the fetch; the sheet shows its own loading state meanwhile.
    final loading = _ensureCategories();
    if (!mounted) {
      _categoryOpen = false;
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _CategorySheet(
          loadingFuture: loading,
          categoriesLoaded: () => _categoriesLoaded,
          categories: () => _categories,
          selectedId: _selectedCategoryId,
          onSelect: _selectCategory,
        ),
      ),
    );
    if (mounted) setState(() => _categoryOpen = false);
  }

  void _selectCategory(int? id) {
    // Tapping the already-selected category clears it. Selection is owned by
    // the parent, so just report the new value and close the sheet.
    final bool clearing = id == _selectedCategoryId;
    widget.onCategoryChanged?.call(clearing ? null : id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        children: [
          _Chip(
            // Store-category: only the dropdown chevron (on the left), no
            // leading icon.
            label: (_selectedCategoryName?.isNotEmpty ?? false)
                ? _selectedCategoryName!
                : 'store_category'.tr,
            isDropdown: true,
            iconOnLeft: true,
            expanded: _categoryOpen,
            selected: _categoryOpen || _selectedCategoryId != null,
            activeBg: const Color(0xFFEBFEEB),
            onTap: _openCategorySheet,
          ),
          _Chip(
            label: 'qidha'.tr,
            iconIdle: Images.filter_qidha,
            iconActive: Images.filter_qidha_active,
            selected: _active.contains('qidha'),
            onTap: () => _toggle('qidha'),
          ),
          _Chip(
            label: 'offers'.tr,
            iconIdle: Images.filter_offers,
            iconActive: Images.filter_offers_active,
            selected: _active.contains('offers'),
            onTap: () => _toggle('offers'),
          ),
          _Chip(
            label: 'top_rated'.tr,
            iconIdle: Images.filter_star,
            iconActive: Images.filter_star_active,
            selected: _active.contains('top_rated'),
            onTap: () => _toggle('top_rated'),
          ),
          _Chip(
            label: 'free_delivery'.tr,
            iconIdle: Images.filter_car,
            iconActive: Images.filter_car_active,
            selected: _active.contains('free_delivery'),
            onTap: () => _toggle('free_delivery'),
          ),
          _Chip(
            label: 'within_30_minutes'.tr,
            iconIdle: Images.filter_time,
            iconActive: Images.filter_time_active,
            selected: _active.contains('within_30_minutes'),
            onTap: () => _toggle('within_30_minutes'),
          ),
          _Chip(
            label: 'open_now'.tr,
            iconIdle: Images.filter_cart,
            iconActive: Images.filter_cart_active,
            selected: _active.contains('open_now'),
            onTap: () => _toggle('open_now'),
          ),
        ],
      ),
    );
  }

}

/// Bottom sheet hosting the store-category single-select list. Rebuilds itself
/// once [loadingFuture] resolves so the spinner gives way to the list.
class _CategorySheet extends StatelessWidget {
  final Future<void> loadingFuture;
  final bool Function() categoriesLoaded;
  final List<_Cat> Function() categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  const _CategorySheet({
    required this.loadingFuture,
    required this.categoriesLoaded,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle.
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E1E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'store_category'.tr,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF121C19),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          size: 22, color: Color(0xFF717885)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F1F3)),
            // List (or spinner until loaded).
            Flexible(
              child: FutureBuilder<void>(
                future: loadingFuture,
                builder: (context, snapshot) {
                  final loaded = categoriesLoaded() ||
                      snapshot.connectionState == ConnectionState.done;
                  if (!loaded) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final cats = categories();
                  if (cats.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'no_data_found'.tr,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: Color(0xFF717885),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(top: 6, bottom: 6 + bottomInset),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F1F3),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (_, i) {
                      final cat = cats[i];
                      return _CategoryRow(
                        label: cat.name ?? '',
                        selected: cat.id == selectedId,
                        onTap: () => onSelect(cat.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        // Radio on the left, label on the right.
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  height: 1.2,
                  color: const Color(0xFF121C19),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-select radio indicator using the design's active/idle artwork.
class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      selected ? Images.radio_active : Images.radio_not_active,
      width: 20,
      height: 20,
      fit: BoxFit.contain,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  /// Optional image-asset icon pair (idle/active).
  final String? iconIdle;
  final String? iconActive;
  final bool selected;
  final bool isDropdown;
  final bool expanded;
  final bool iconOnLeft;
  final Color activeBg;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.onTap,
    this.iconIdle,
    this.iconActive,
    this.selected = false,
    this.isDropdown = false,
    this.expanded = false,
    this.iconOnLeft = false,
    this.activeBg = _activeBg,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? _activeFg : _idleFg;
    final radius = BorderRadius.circular(Dimensions.radiusExtraLarge);

    Widget? iconWidget;
    if (iconIdle != null) {
      iconWidget = Image.asset(
        selected ? (iconActive ?? iconIdle!) : iconIdle!,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    final Widget label0 = Text(
      label,
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w600,
        fontSize: 13,
        height: 1.2,
        color: fg,
      ),
    );
    final Widget? chevron = isDropdown
        ? Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 16,
            color: selected ? _activeFg : const Color(0xFF717885),
          )
        : null;

    // RTL row: the first child sits on the right. Default = icon on the right;
    // [iconOnLeft] (store-category) flips the icon + chevron to the left.
    final List<Widget> children = iconOnLeft
        ? [
            label0,
            if (iconWidget != null) ...[const SizedBox(width: 5), iconWidget],
            if (chevron != null) ...[const SizedBox(width: 3), chevron],
          ]
        : [
            if (iconWidget != null) ...[iconWidget, const SizedBox(width: 5)],
            label0,
            if (chevron != null) ...[const SizedBox(width: 3), chevron],
          ];

    return Padding(
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
      child: Material(
        color: selected ? activeBg : _idleBg,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? activeBg : _idleBorder,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
