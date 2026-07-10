part of 'market_store_screen.dart';

// ─── Sticky category tab bar (SliverPersistentHeader) ─────────────────────────

/// Pinned horizontal tab bar used inside the store's CustomScrollView.
/// - Sticks below the market top header once the user starts scrolling.
/// - Tabs are scrollable left/right (right-to-left in Arabic).
/// - ☰ button lives at the PHYSICAL RIGHT edge of the bar and opens a
///   "قائمة الأصناف" bottom sheet with the full category list.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<_Category> categories;
  final int activeIndex;
  final ScrollController tabScrollCtrl;
  final void Function(int) onTap;

  _TabBarDelegate({
    required this.categories,
    required this.activeIndex,
    required this.tabScrollCtrl,
    required this.onTap,
  });

  static const double _height = 48.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.activeIndex != activeIndex ||
      old.categories.length != categories.length;

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategorySheet(
        categories: categories,
        activeIndex: activeIndex,
        onTap: (i) {
          Navigator.pop(context);
          onTap(i);
        },
      ),
    );
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.white,
      elevation: shrinkOffset > 0 ? 2 : 0,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Tabs list — leaves 44 px on the physical right for ☰.
                Positioned.fill(
                  right: 44,
                  child: ListView.separated(
                    controller: tabScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    // In Arabic RTL, ListView reverses automatically so that
                    // the first category appears on the right.
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) {
                      final bool active = i == activeIndex;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  categories[i].name ?? '—',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14,
                                    color: active
                                        ? const Color(0xFF121C19)
                                        : const Color(0xFF8A8F99),
                                  ),
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 3,
                              width: active ? 26 : 0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF30913F),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // ☰ button — physically anchored to the right edge.
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 44,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showSheet(context),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(
                              color: Color(0xFFEEEFF2), width: 1),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.menu_rounded,
                            size: 22, color: Color(0xFF30913F)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom divider line.
          Container(height: 1, color: const Color(0xFFEEEFF2)),
        ],
      ),
    );
  }
}

// ─── Category bottom sheet ────────────────────────────────────────────────────

class _CategorySheet extends StatelessWidget {
  final List<_Category> categories;
  final int activeIndex;
  final void Function(int) onTap;

  const _CategorySheet({
    required this.categories,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          // Drag handle.
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE0E6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title row.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_rounded,
                    size: 20, color: Color(0xFF30913F)),
                const SizedBox(width: 8),
                const Text(
                  'قائمة الأصناف',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF121C19),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEFF2)),
          // Category list.
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              itemCount: categories.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF5F6F7)),
              itemBuilder: (_, i) {
                final bool active = i == activeIndex;
                return InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            categories[i].name ?? '—',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 15,
                              color: active
                                  ? const Color(0xFF30913F)
                                  : const Color(0xFF121C19),
                            ),
                          ),
                        ),
                        if (active)
                          const Icon(Icons.check_rounded,
                              size: 18, color: Color(0xFF30913F)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}


/// Only 4 tile backgrounds, assigned by column so the top and bottom tile of a
/// column share one: col 0 → back_1, col 1 → back_2, col 2 → back_5, col 3 →
/// back_6 (then it repeats). In the 2-row horizontal grid, column = index ~/ 2.
const List<String> _categoryColumnBackgrounds = [
  'assets/image/back_1.png',
  'assets/image/back_2.png',
  'assets/image/back_5.png',
  'assets/image/back_6.png',
];

String _categoryBgForIndex(int index) => _categoryColumnBackgrounds[
    (index ~/ 2) % _categoryColumnBackgrounds.length];

class _CategoriesGrid extends StatefulWidget {
  final List<_Category> categories;
  final int? storeId;
  final int moduleId;
  final String? storeCover;
  const _CategoriesGrid(
      {required this.categories,
      this.storeId,
      this.moduleId = _marketModuleId,
      this.storeCover});

  /// Collapsed preview shows this many categories + a "view more" tile (= 8).
  static const int _previewCount = 7;

  @override
  State<_CategoriesGrid> createState() => _CategoriesGridState();
}

class _CategoriesGridState extends State<_CategoriesGrid> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cats = widget.categories;

    // Expanded: full vertical 3-column grid (all categories).
    if (_expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          itemCount: cats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (_, i) => _CategoryTile(
            category: cats[i],
            index: i,
            storeId: widget.storeId,
            moduleId: widget.moduleId,
            storeCover: widget.storeCover,
          ),
        ),
      );
    }

    // Collapsed: two fixed rows scrolling horizontally; 7 cats + view-more.
    final bool hasMore = cats.length > _CategoriesGrid._previewCount;
    final int previewLen =
        hasMore ? _CategoriesGrid._previewCount : cats.length;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: SizedBox(
        height: 220,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          itemCount: previewLen + (hasMore ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (_, i) {
            if (hasMore && i == previewLen) {
              return _ViewMoreCategoryTile(
                index: previewLen,
                onTap: () => setState(() => _expanded = true),
              );
            }
            return _CategoryTile(
              category: cats[i],
              index: i,
              storeId: widget.storeId,
              moduleId: widget.moduleId,
              storeCover: widget.storeCover,
            );
          },
        ),
      ),
    );
  }
}

/// Category-tile-sized "اطّلع على المزيد" tile that expands the grid.
/// Uses the same back_N artwork as the surrounding category tiles.
class _ViewMoreCategoryTile extends StatelessWidget {
  final VoidCallback onTap;
  final int index;
  const _ViewMoreCategoryTile({required this.onTap, required this.index});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    final String bg = _categoryBgForIndex(index);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            image: DecorationImage(
              image: AssetImage(bg),
              fit: BoxFit.cover,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'see_more'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                  color: Color(0xFF1F7A35),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(Icons.arrow_back, size: 18, color: Color(0xFF1F7A35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final int index;
  final int? storeId;
  final int moduleId;
  final String? storeCover;
  const _CategoryTile(
      {required this.category,
      required this.index,
      this.storeId,
      this.moduleId = _marketModuleId,
      this.storeCover});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    final String bg = _categoryBgForIndex(index);
    // The backend's special discount category comes back as "Best Offers" (in
    // English, no image). Localize its label and use an offers icon fallback.
    final bool isDiscount =
        category.isDiscount || category.name == 'Best Offers';
    final String displayName =
        isDiscount ? 'best_offers'.tr : (category.name ?? '');
    final String imageUrl = category.image ?? '';
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.to<void>(
          () => MarketOffersScreen(
            title: displayName,
            storeId: storeId,
            moduleId: moduleId,
            categoryId: category.rawId,
            storeCover: storeCover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            image: DecorationImage(
              image: AssetImage(bg),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Category product image (68×68) centered at the bottom. The
              // discount category has no image → fall back to an offers icon.
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Center(
                  child: (imageUrl.isEmpty && isDiscount)
                      ? Image.asset(
                          Images.filter_offers_active,
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 68,
                            height: 68,
                          ),
                        )
                      : CustomImage(
                          image: imageUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                          placeholder: Images.placeholder,
                        ),
                ),
              ),
              // Name at the top, centered.
              Positioned(
                top: 8,
                right: 6,
                left: 6,
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.0,
                    color: Color(0xFF30913F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category chips removed (redundant circular strip; the category grid
// above already covers category navigation). ────────────────────────────────
