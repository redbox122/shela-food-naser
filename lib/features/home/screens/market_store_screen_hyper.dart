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

/// Muted "اطّلع على المزيد" pill — the old `ExploreMoreButton` look.
class _HyperExploreChip extends StatelessWidget {
  final VoidCallback onTap;
  const _HyperExploreChip({required this.onTap});

  static const Color _bg = Color(0xFFF5F5F7); // background-card
  static const Color _fg = Color(0xFF545454); // text-disable

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              'see_more'.tr,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.4,
                color: _fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header row: bold title + optional "see more" chip. Localized title
/// (RTL/LTR follows the app's active language automatically).
class _HyperSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeMore;
  const _HyperSectionHeader({required this.title, this.onSeeMore});

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
          if (onSeeMore != null) _HyperExploreChip(onTap: onSeeMore!),
        ],
      ),
    );
  }
}

/// Lightweight brand model built from a `/api/v1/brands` row — the REAL product
/// brands (صادق / جودي / نادك / المراعي…), same source the app's `BrandsController`
/// uses. Mirrors `BrandModel`'s image handling: the backend now returns a full
/// `image_full_url`; a relative `image` is prefixed with `/storage/brand/`.
class _HyperBrand {
  final int? id;
  final String? name;
  final String? image;

  _HyperBrand({this.id, this.name, this.image});

  factory _HyperBrand.fromBrand(Map<String, dynamic> j) {
    String? img = (j['image_full_url'] ?? j['image'])?.toString();
    if (img != null &&
        img.isNotEmpty &&
        !img.startsWith('http://') &&
        !img.startsWith('https://')) {
      final clean = img.startsWith('/') ? img.substring(1) : img;
      img = '${AppConstants.baseUrl}/storage/brand/$clean';
    }
    return _HyperBrand(
      id: int.tryParse('${j['id']}'),
      name: j['name']?.toString(),
      image: img,
    );
  }
}

/// "العلامات التجارية" rail: a row of circular brand logos (old-app look: 80px
/// circle with a soft primary shadow). Collapsed = horizontal row; tapping the
/// header chip expands it into a wrapped grid in place. Data = this module's
/// own stores (`/api/v2/stores`).
class _HyperBrandsRail extends StatefulWidget {
  final int moduleId;
  const _HyperBrandsRail({required this.moduleId});

  static const double diameter = 80;

  @override
  State<_HyperBrandsRail> createState() => _HyperBrandsRailState();
}

class _HyperBrandsRailState extends State<_HyperBrandsRail> {
  List<_HyperBrand> _items = const [];
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final response = await Get.find<ApiClient>().getData(
        AppConstants.brandListUri, // /api/v1/brands (real product brands)
        headers: {
          AppConstants.localizationKey: 'ar',
          AppConstants.moduleId: widget.moduleId.toString(),
        },
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      // /api/v1/brands returns a bare list; tolerate {brands}/{data} wrappers.
      final List raw = body is List
          ? body
          : (body is Map && body['brands'] is List)
              ? body['brands'] as List
              : (body is Map && body['data'] is List)
                  ? body['data'] as List
                  : const [];
      setState(() {
        _items = raw
            .whereType<Map>()
            .map((e) => _HyperBrand.fromBrand(Map<String, dynamic>.from(e)))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(_HyperBrand b) {
    if (b.id == null) return;
    // Opens the brand's items screen (same destination as the app's brands rail).
    Get.toNamed<void>(RouteHelper.getBrandsItemScreen(b.id!, b.name ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    // No skeleton noise: while loading (or when empty) the rail stays hidden and
    // the categories/offers around it still render.
    if (_loading || _items.isEmpty) return const SizedBox.shrink();

    final Widget rail = _expanded
        ? Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: Wrap(
              spacing: Dimensions.paddingSizeDefault,
              runSpacing: Dimensions.paddingSizeDefault,
              children: [
                for (final b in _items)
                  _HyperBrandCircle(brand: b, onTap: () => _open(b)),
              ],
            ),
          )
        : SizedBox(
            height: _HyperBrandsRail.diameter + 6,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: Dimensions.paddingSizeDefault),
              itemBuilder: (_, i) =>
                  _HyperBrandCircle(brand: _items[i], onTap: () => _open(_items[i])),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HyperSectionHeader(
          title: 'brands'.tr,
          onSeeMore: _items.length > 5
              ? () => setState(() => _expanded = !_expanded)
              : null,
        ),
        rail,
      ],
    );
  }
}

/// 80px circular brand logo: white fill, soft primary shadow, `ClipOval`. Ported
/// from the old `CircularRingAvatar` (unselected state).
class _HyperBrandCircle extends StatelessWidget {
  final _HyperBrand brand;
  final VoidCallback onTap;
  const _HyperBrandCircle({required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const double d = _HyperBrandsRail.diameter;
    return InkWell(
      borderRadius: BorderRadius.circular(d / 2),
      onTap: onTap,
      child: Container(
        width: d,
        height: d,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.cardColor,
          border: Border.all(color: theme.cardColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: ColoredBox(
            color: Colors.white,
            child: CustomImage(
              image: brand.image ?? '',
              width: d,
              height: d,
              fit: BoxFit.contain,
              placeholder: Images.placeholder,
            ),
          ),
        ),
      ),
    );
  }
}

/// "الأقسام" rail — the OLD shop_home look transferred verbatim: a horizontally
/// scrolling grid of TWO rows, each tile a coloured-background card with the
/// category name (green) directly above its product image, centred and compact.
/// Data + tap target are the NEW app's own (this store's categories →
/// [MarketOffersScreen]); only the visual design comes from the old app.
class _HyperCategoriesRail extends StatelessWidget {
  final List<_Category> categories;
  final int? storeId;
  final int moduleId;
  final String? storeCover;
  const _HyperCategoriesRail({
    required this.categories,
    this.storeId,
    this.moduleId = _marketModuleId,
    this.storeCover,
  });

  // Old-app "isHyper" tile metrics (category_view.dart): 112px square tile,
  // 56×72 product image, 13px name.
  static const double _tileSize = 112;
  static const double _imageHeight = 56;
  static const double _imageWidth = 72;

  @override
  Widget build(BuildContext context) {
    final List<_Category> visible = categories.take(12).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      // Two rows tall (old design), the rest scroll in horizontally.
      height: _tileSize * 2 + Dimensions.paddingSizeSmall,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: _tileSize,
          mainAxisSpacing: Dimensions.paddingSizeSmall,
          crossAxisSpacing: Dimensions.paddingSizeSmall,
        ),
        itemCount: visible.length,
        itemBuilder: (context, index) => _HyperCategoryTile(
          category: visible[index],
          index: index,
          storeId: storeId,
          moduleId: moduleId,
          storeCover: storeCover,
          imageHeight: _imageHeight,
          imageWidth: _imageWidth,
        ),
      ),
    );
  }
}

/// A single "الأقسام" card in the old-app compact style: coloured background,
/// green name centred at the top, product image right below it.
class _HyperCategoryTile extends StatelessWidget {
  final _Category category;
  final int index;
  final int? storeId;
  final int moduleId;
  final String? storeCover;
  final double imageHeight;
  final double imageWidth;
  const _HyperCategoryTile({
    required this.category,
    required this.index,
    required this.imageHeight,
    required this.imageWidth,
    this.storeId,
    this.moduleId = _marketModuleId,
    this.storeCover,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDiscount =
        category.isDiscount || category.name == 'Best Offers';
    final String displayName =
        isDiscount ? 'best_offers'.tr : (category.name ?? '');
    final String bg = _categoryBgForIndex(index);
    final String imageUrl = category.image ?? '';
    return GestureDetector(
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: AssetImage(bg),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.0,
                color: Color(0xFF30913F),
              ),
            ),
            const SizedBox(height: 3),
            (imageUrl.isEmpty && isDiscount)
                ? Image.asset(
                    Images.filter_offers_active,
                    height: imageHeight,
                    width: imageWidth,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                    ),
                  )
                : CustomImage(
                    image: imageUrl,
                    height: imageHeight,
                    width: imageWidth,
                    fit: BoxFit.contain,
                    placeholder: Images.placeholder,
                  ),
          ],
        ),
      ),
    );
  }
}
