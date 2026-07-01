import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/core/cache/simple_json_cache.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN (Market): horizontal categories rail.
///
/// Wired to `GET /api/v2/categories`, scoped to the market (grocery) module via
/// the moduleId header. Each card shows the category image with its name.
class MarketCategoriesSection extends StatefulWidget {
  final int? moduleId;

  /// Currently selected category id (drives the active card state).
  final int? selectedId;

  /// Called when a card is tapped (passes null to clear when re-tapped).
  final ValueChanged<int?>? onSelect;

  /// When true, the categories render as a single horizontal row of fixed
  /// 90×90 tiles (used by أسواق الحي) instead of the 4-column grid (used by the
  /// market screen).
  final bool singleRow;

  const MarketCategoriesSection({
    super.key,
    this.moduleId,
    this.selectedId,
    this.onSelect,
    this.singleRow = false,
  });

  @override
  State<MarketCategoriesSection> createState() =>
      _MarketCategoriesSectionState();
}

/// Lightweight model for a row of the `/categories` response.
class _Cat {
  final int? id;
  final String? name;
  final String? image;

  _Cat({this.id, this.name, this.image});

  factory _Cat.fromJson(Map<String, dynamic> j) => _Cat(
        id: int.tryParse('${j['id']}'),
        name: j['name']?.toString(),
        // Tolerant: v2 *_full_url, else legacy image.
        image: (j['image_full_url'] ?? j['image'])?.toString(),
      );
}

class _MarketCategoriesSectionState extends State<MarketCategoriesSection> {
  List<_Cat> _items = const [];
  bool _loading = true;

  /// Collapsed: 7 categories + a "view more" tile (8). Expanded: all of them.
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  String get _cacheKey => 'mcat_${widget.moduleId}';

  List<_Cat> _parse(dynamic body) {
    final List raw = body is List
        ? body
        : (body is Map && body['data'] is List)
            ? body['data'] as List
            : (body is Map && body['categories'] is List)
                ? body['categories'] as List
                : const [];
    return raw
        .whereType<Map>()
        .map((e) => _Cat.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _fetch() async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // Instant paint from cache, then revalidate.
    final cached = SimpleJsonCache.read(_cacheKey);
    if (cached != null) {
      final items = _parse(cached);
      if (mounted && items.isNotEmpty) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    }
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
      if (!mounted) return;
      final dynamic body = response.body;
      final items = _parse(body);
      setState(() {
        if (items.isNotEmpty) _items = items;
        _loading = false;
      });
      SimpleJsonCache.write(_cacheKey, body);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Show this many categories before the "view more" tile (= 8 cells total).
  static const int _previewCount = 7;

  static const SliverGridDelegateWithFixedCrossAxisCount _gridDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    if (!_loading && _items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: _loading
          ? _buildSkeleton(context)
          : (widget.singleRow ? _buildRow() : _buildGrid()),
    );
  }

  /// Fixed tile size for the single-row layout (أسواق الحي).
  static const double _rowTileSize = 90;

  /// Single horizontal row of fixed 90×90 tiles. No "view more" tile — the row
  /// just scrolls.
  Widget _buildRow() {
    return SizedBox(
      height: _rowTileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = _items[i];
          final bool selected = cat.id != null && cat.id == widget.selectedId;
          return SizedBox(
            width: _rowTileSize,
            child: _CategoryCard(
              cat: cat,
              selected: selected,
              centerLabel: true,
              onTap: () => widget.onSelect?.call(selected ? null : cat.id),
            ),
          );
        },
      ),
    );
  }

  /// 4-column grid: up to 7 categories + an 8th "عرض المزيد" tile that expands
  /// the grid to show every category.
  Widget _buildGrid() {
    final bool hasMore = _items.length > _previewCount;
    final bool collapsed = hasMore && !_expanded;
    final List<_Cat> shown =
        collapsed ? _items.take(_previewCount).toList() : _items;
    final int itemCount = shown.length + (collapsed ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: itemCount,
      gridDelegate: _gridDelegate,
      itemBuilder: (_, i) {
        if (collapsed && i == shown.length) {
          return _ViewMoreCard(onTap: () => setState(() => _expanded = true));
        }
        final cat = shown[i];
        final bool selected = cat.id != null && cat.id == widget.selectedId;
        return _CategoryCard(
          cat: cat,
          selected: selected,
          onTap: () => widget.onSelect?.call(selected ? null : cat.id),
        );
      },
    );
  }

  /// Skeleton bones rendered from the real [_CategoryCard] layout with dummy
  /// data, so it matches the live tiles exactly.
  Widget _buildSkeleton(BuildContext context) {
    final _Cat dummy = _Cat(id: 0, name: 'تصنيف', image: '');
    final Widget content = widget.singleRow
        ? SizedBox(
            height: _rowTileSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => SizedBox(
                width: _rowTileSize,
                child: _CategoryCard(
                    cat: dummy,
                    selected: false,
                    centerLabel: true,
                    onTap: () {}),
              ),
            ),
          )
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            itemCount: 8,
            gridDelegate: _gridDelegate,
            itemBuilder: (_, __) =>
                _CategoryCard(cat: dummy, selected: false, onTap: () {}),
          );
    return Skeletonizer(child: content);
  }
}

class _CategoryCard extends StatelessWidget {
  final _Cat cat;
  final bool selected;
  final VoidCallback onTap;

  /// When true, the name is centered at the top (single-row layout) instead of
  /// right-aligned (grid layout).
  final bool centerLabel;

  const _CategoryCard({
    required this.cat,
    required this.selected,
    required this.onTap,
    this.centerLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          // Active state: EBFEEB tint only (no border).
          color: selected ? const Color(0xFFEBFEEB) : null,
          image: selected
              ? null
              : const DecorationImage(
                  image: AssetImage(Images.background_category),
                  fit: BoxFit.cover,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Product image at the bottom (over the green diagonal).
            Positioned(
              left: 6,
              right: 6,
              bottom: 4,
              child: CustomImage(
                image: cat.image ?? '',
                width: double.infinity,
                height: 40,
                fit: BoxFit.contain,
                placeholder: Images.placeholder,
              ),
            ),
            // Category name at the top — centered (single-row) or right-aligned
            // (grid, RTL).
            Positioned(
              top: 6,
              right: centerLabel ? 4 : 6,
              left: centerLabel ? 4 : 1,
              child: Text(
                cat.name ?? '',
                textAlign: centerLabel ? TextAlign.center : TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                  color: Color(0xFF237D2E), // hsba(127,72%,49%,1)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "عرض المزيد" tile (the 8th cell) — expands the grid to all categories.
class _ViewMoreCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewMoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          image: const DecorationImage(
            image: AssetImage(Images.background_category),
            fit: BoxFit.cover,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'see_more'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.2,
                color: Color(0xFF237D2E),
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_back, size: 16, color: Color(0xFF237D2E)),
          ],
        ),
      ),
    );
  }
}
