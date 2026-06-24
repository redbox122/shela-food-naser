part of 'market_store_screen.dart';

// ─── Categories grid ─────────────────────────────────────────────────────────

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
