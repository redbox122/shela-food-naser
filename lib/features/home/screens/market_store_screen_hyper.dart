part of 'market_store_screen.dart';

// ─── Hyper Shela browse block (isHyperStorefront only) ────────────────────────
//
// Visual design ported from the OLD app's `shop_home_screen` (الأقسام grid →
// العلامات التجارية circles → عروض وخصومات) and painted OVER the NEW app's own
// data: categories come from `_categories`/`/api/v2/stores/{id}/categories`,
// brand circles from `/api/v2/stores`, and offers from [MarketBannerSection]
// (`/api/v1/banners`). No business logic or API is copied from the old app —
// only the look. Everything here is scoped to this store library, so nothing
// outside the هايبر شله storefront is affected.

/// Persistent, prominent search bar for the storefront: a tappable pill that
/// opens the scoped product search (this store's items only). Mirrors the
/// always-visible search bar shoppers expect on a large market (e.g. panda).
class _HyperSearchBar extends StatelessWidget {
  final int? storeId;
  final int moduleId;
  const _HyperSearchBar({this.storeId, this.moduleId = _marketModuleId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeExtraSmall,
      ),
      child: GestureDetector(
        onTap: () => Get.to<void>(() => HomeSearchScreen(
              storeId: storeId,
              moduleId: moduleId,
            )),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1E8E3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 22, color: Color(0xFF2E9E4F)),
              const SizedBox(width: 10),
              Text(
                'ابحث عن منتج (مثل: سكر، حليب، بيض)…',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Color(0xFF8A938E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header row: bold localized title (RTL/LTR follows the active
/// language automatically).
class _HyperSectionHeader extends StatelessWidget {
  final String title;
  const _HyperSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.4,
                color: Color(0xFF121C19),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal carousel of the store's pre-designed cards (one image each),
/// with left/right arrow navigation and NO section title. Used for the promo
/// ("القسم رابع") and discount ("القسم خامس") card sets. Tap targets get wired to
/// the real collections once the storefront data is in place.
class _HyperCardCarousel extends StatefulWidget {
  final String assetPrefix; // e.g. 'assets/image/hyper_promos/promo_'
  final int count;
  final double aspectRatio; // card width / height

  /// Optional per-card destinations. When catIds[i] is a non-null category id,
  /// tapping card i opens that category's products. Cards with a null id (or
  /// when catIds is null) stay non-interactive images.
  final List<String?>? catIds;
  final int? storeId;
  final int moduleId;
  final String? storeCover;

  /// When true, tapping a card opens the department showing only discounted
  /// products (used by the discount ("القسم خامس") card set).
  final bool discountedOnly;

  /// Optional per-card brand destinations. When brandTargets[i] is set, tapping
  /// card i opens that brand's products screen (used by the brand ("القسم
  /// السادس") card set). Takes precedence over catIds for that card.
  final List<({int id, String name})?>? brandTargets;

  const _HyperCardCarousel({
    required this.assetPrefix,
    required this.count,
    required this.aspectRatio,
    this.catIds,
    this.storeId,
    this.moduleId = _marketModuleId,
    this.storeCover,
    this.discountedOnly = false,
    this.brandTargets,
  });

  static const double _cardHeight = 236;

  @override
  State<_HyperCardCarousel> createState() => _HyperCardCarouselState();
}

class _HyperCardCarouselState extends State<_HyperCardCarousel> {
  final ScrollController _sc = ScrollController();

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_sc.hasClients) return;
    final double target = (_sc.offset + delta)
        .clamp(_sc.position.minScrollExtent, _sc.position.maxScrollExtent);
    _sc.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final double cardW = _HyperCardCarousel._cardHeight * widget.aspectRatio;
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: SizedBox(
        height: _HyperCardCarousel._cardHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ListView.separated(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              itemCount: widget.count,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final String n = (index + 1).toString().padLeft(2, '0');
                final Widget card = ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: widget.aspectRatio,
                    child: Image.asset(
                      '${widget.assetPrefix}$n.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                );
                // Brand cards take precedence: open the brand's products screen.
                final brand = (widget.brandTargets != null &&
                        index < widget.brandTargets!.length)
                    ? widget.brandTargets![index]
                    : null;
                if (brand != null) {
                  return GestureDetector(
                    onTap: () => Get.toNamed(
                        RouteHelper.getBrandsItemScreen(brand.id, brand.name)),
                    child: card,
                  );
                }
                final String? catId = (widget.catIds != null &&
                        index < widget.catIds!.length)
                    ? widget.catIds![index]
                    : null;
                if (catId == null) return card;
                return GestureDetector(
                  onTap: () => Get.to<void>(
                    () => MarketOffersScreen(
                      title: '',
                      storeId: widget.storeId,
                      moduleId: widget.moduleId,
                      categoryId: catId,
                      storeCover: widget.storeCover,
                      minimalHeader: true,
                      discountedOnly: widget.discountedOnly,
                    ),
                  ),
                  child: card,
                );
              },
            ),
            Positioned(
                left: 2,
                child: _arrow(Icons.chevron_left, () => _scrollBy(-cardW * 2))),
            Positioned(
                right: 2,
                child: _arrow(Icons.chevron_right, () => _scrollBy(cardW * 2))),
          ],
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 22, color: const Color(0xFF2E9E4F)),
        ),
      ),
    );
  }
}

/// "اخترناها لك" — the store's pre-designed curated-pick cards (green cards with
/// a name + product photos baked in), shown as a horizontal rail. Tap targets
/// get wired to the real collections once the storefront data is in place.
class _HyperPicksRail extends StatelessWidget {
  final int? storeId;
  final int moduleId;
  final String? storeCover;
  const _HyperPicksRail({
    this.storeId,
    this.moduleId = _marketModuleId,
    this.storeCover,
  });

  // 5 designed cards. catId set = tap opens that (sub)category; null = the
  // curated filters (الأعلى مبيعاً / وصل حديثاً / الجمعات) are wired later.
  static const List<({String asset, String? catId, String title})> _cards = [
    (asset: 'pick_01', catId: '59659', title: 'خالية من اللاكتوز'),
    (asset: 'pick_02', catId: '59686', title: 'الأعلى مبيعاً'),
    (asset: 'pick_03', catId: '59719', title: 'وصل حديثاً'),
    (asset: 'pick_04', catId: '59746', title: 'الجمعات'),
    (asset: 'pick_05', catId: '59656', title: 'خالية من الجلوتين'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HyperSectionHeader(title: 'picked_for_you'.tr),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            itemCount: _cards.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: Dimensions.paddingSizeSmall),
            itemBuilder: (_, index) {
              final card = _cards[index];
              final Widget tile = ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 297 / 267,
                  child: Image.asset(
                    'assets/image/hyper_picks/${card.asset}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              );
              if (card.catId == null) return tile;
              return GestureDetector(
                onTap: () => Get.to<void>(
                  () => MarketOffersScreen(
                    title: card.title,
                    storeId: storeId,
                    moduleId: moduleId,
                    categoryId: card.catId,
                    storeCover: storeCover,
                    minimalHeader: true,
                  ),
                ),
                child: tile,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "تسوق حسب الفئة" — the store's pre-designed category cards (one image per
/// category, with the name + product photos baked in), shown as two rows that
/// scroll horizontally (panda.sa layout). Tap targets get wired to the real
/// categories once the storefront data is in place.
class _HyperDesignedCategoriesGrid extends StatelessWidget {
  final int? storeId;
  final int moduleId;
  final String? storeCover;
  const _HyperDesignedCategoriesGrid({
    this.storeId,
    this.moduleId = _marketModuleId,
    this.storeCover,
  });

  static const double _cardW = 118;
  static const double _cardH = 118;

  // Designed cards wired to their هايبر شله department ids. "جاهز للأكل"
  // (cat_06) and "مياه" (cat_10) are intentionally left out — no matching
  // department yet (their products are coming later).
  static const List<({String asset, String catId, String title})> _cards = [
    (asset: 'cat_01', catId: '59601', title: 'العناية الشخصية'),
    (asset: 'cat_02', catId: '59616', title: 'مستلزمات الطبخ'),
    (asset: 'cat_03', catId: '59609', title: 'العناية بالطفل'),
    (asset: 'cat_04', catId: '59662', title: 'المجمدات'),
    (asset: 'cat_05', catId: '59588', title: 'منتجات طازجة'),
    (asset: 'cat_07', catId: '59631', title: 'العناية بالمنزل'),
    (asset: 'cat_08', catId: '59626', title: 'الأطعمة الأساسية'),
    // NOTE: the source images cat_09..cat_15 are mirror-swapped vs their file
    // names (cat_09 actually shows الجمال, cat_15 shows الإلكترونيات, etc.), so
    // each entry uses the asset whose PICTURE matches its department.
    (asset: 'cat_15', catId: '59576', title: 'الإلكترونيات'),
    (asset: 'cat_13', catId: '59670', title: 'وجبات خفيفة'),
    (asset: 'cat_12', catId: '59596', title: 'العناية بالحيوانات الأليفة'),
    (asset: 'cat_11', catId: '59648', title: 'المخبوزات'),
    (asset: 'cat_10', catId: '59581', title: 'المشروبات'),
    (asset: 'cat_14', catId: '59684', title: 'مياه'),
    (asset: 'cat_09', catId: '59601', title: 'الجمال'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardH * 2 + 10,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // two rows (cross axis is vertical when scrolling →)
          mainAxisExtent: _cardW,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return GestureDetector(
            onTap: () => Get.to<void>(
              () => MarketOffersScreen(
                title: card.title,
                storeId: storeId,
                moduleId: moduleId,
                categoryId: card.catId,
                storeCover: storeCover,
                minimalHeader: true,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/image/hyper_categories/${card.asset}.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
