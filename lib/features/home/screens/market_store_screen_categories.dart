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

/// Single horizontal row of square category tiles. Entering a store shows the
/// categories neatly in one scrollable row (swipes left/right); the matching
/// products render in the sections below. Replaces the older 2-row grid +
/// "view more" so every category is reachable by scrolling the one row.
class _CategoriesGrid extends StatelessWidget {
  final List<_Category> categories;
  final int? storeId;
  final int moduleId;
  final String? storeCover;
  const _CategoriesGrid(
      {required this.categories,
      this.storeId,
      this.moduleId = _marketModuleId,
      this.storeCover});

  /// Square tile edge (= row height); name sits inside the tile.
  static const double _tileSize = 104;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: SizedBox(
        height: _tileSize,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => SizedBox(
            width: _tileSize,
            child: _CategoryTile(
              category: categories[i],
              index: i,
              storeId: storeId,
              moduleId: moduleId,
              storeCover: storeCover,
            ),
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
