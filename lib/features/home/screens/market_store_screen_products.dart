// ignore_for_file: unused_element_parameter, unused_element
part of 'market_store_screen.dart';

// ─── Product sections ────────────────────────────────────────────────────────

/// Maps the store screen's [_Product]s to the offers screen's [OfferProduct]
/// shape, so an already-loaded featured section can seed the branded screen as a
/// fallback when its `/categories/offers` fetch comes back empty (cross-module
/// featured stores have no market "offers" category).
List<OfferProduct> _toOfferProducts(List<_Product> products) => products
    .map((p) => OfferProduct(
          id: p.id,
          name: p.name,
          image: p.image,
          price: p.originalPrice > 0 ? p.originalPrice : p.price,
          discountedPrice: p.discountedPrice,
        ))
    .toList();

/// Grey "تطلع على المزيد" pill shown at the top-left of a section header.
class _SeeMorePill extends StatelessWidget {
  final VoidCallback onTap;
  const _SeeMorePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F1F3),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // Text 71×14 + 6px padding ≈ 83 × 26.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Text(
            'see_more'.tr,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.4,
              color: Color(0xFF717885),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final String title;
  final List<_Product> products;
  final int? storeId;
  final int moduleId;

  /// Category id for the "see more" stacked screen (null → see-all grid).
  final String? categoryId;

  /// Store name + logo for the "see more" header.
  final String? storeName;
  final String? storeLogo;
  final String? storeCover;
  const _ProductSection(
      {required this.title,
      required this.products,
      this.storeId,
      this.moduleId = _marketModuleId,
      this.categoryId,
      this.storeName,
      this.storeLogo,
      this.storeCover});

  /// "See more" / logo opens the branded offers screen (cover + logo + name
  /// header + sub-category strip only) — distinct from a category tile tap,
  /// which opens the two-level categories + sub-categories browser.
  void _openOffers() {
    Get.to<void>(
      () => MarketOffersScreen(
        title: title,
        storeId: storeId,
        moduleId: moduleId,
        categoryId: categoryId,
        storeName: storeName,
        storeLogo: storeLogo,
        storeCover: storeCover,
        brandedHeader: true,
        presetProducts: _toOfferProducts(products),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    // Clean section: a green title header (+ "عرض المزيد"), then the products as
    // a 3-column grid (matching the category screen design).
    return Padding(
      padding: const EdgeInsets.only(
        top: 4,
        bottom: Dimensions.paddingSizeSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault, 8, Dimensions.paddingSizeDefault, 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _openOffers,
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.2,
                        color: Color(0xFF30913F),
                      ),
                    ),
                  ),
                ),
                _SeeMorePill(onTap: _openOffers),
              ],
            ),
          ),
          _ProductRail(
            products: products,
            storeId: storeId,
            moduleId: moduleId,
            onViewMore: _openOffers,
          ),
        ],
      ),
    );
  }
}

/// Self-loading rail for one store category, rendered in the same green-header
/// [_ProductSection] style. Fetches the category's products scoped to the store
/// so every category shows as its own section.
class _CategoryRail extends StatefulWidget {
  final int storeId;
  final int moduleId;
  final _Category category;
  final String? storeName;
  final String? storeLogo;
  final String? storeCover;
  const _CategoryRail({
    required this.storeId,
    required this.moduleId,
    required this.category,
    this.storeName,
    this.storeLogo,
    this.storeCover,
  });

  @override
  State<_CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<_CategoryRail> {
  List<_Product>? _products;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  /// Fetches this category's items scoped to [moduleId] (the items index is
  /// module-scoped). Returns an empty list on any failure.
  Future<List<_Product>> _fetchWithModule(int moduleId) async {
    try {
      final r = await Get.find<ApiClient>().getData(
        '/api/v1/categories/items/${widget.category.id}'
        '?store_id=${widget.storeId}&offset=1&limit=10&type=all',
        headers: {AppConstants.moduleId: moduleId.toString()},
        useEtag: false,
      );
      final body = r.body;
      final list = body is Map ? body['products'] : null;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => _Product.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> _fetch() async {
    List<_Product> result = const [];
    if (Get.isRegistered<ApiClient>()) {
      // The items index is module-scoped, and the module passed in can be wrong
      // (e.g. a store opened while another module was active). Try the store's
      // module first, then food, then ecommerce, then every loaded module —
      // stopping at the first that returns items — so products always resolve.
      final List<int> candidates = [];
      void add(int? m) {
        if (m != null && m > 1 && !candidates.contains(m)) candidates.add(m);
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
      if (candidates.isEmpty) candidates.add(widget.moduleId);

      for (final m in candidates) {
        result = await _fetchWithModule(m);
        if (result.isNotEmpty) break;
        if (!mounted) return;
      }
    }
    if (mounted) setState(() => _products = result);
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    if (products == null) {
      return const SizedBox(height: Dimensions.paddingSizeSmall);
    }
    if (products.isEmpty) return const SizedBox.shrink();
    return _ProductSection(
      title: widget.category.name ?? '',
      products: products,
      storeId: widget.storeId,
      moduleId: widget.moduleId,
      categoryId: widget.category.rawId,
      storeName: widget.storeName,
      storeLogo: widget.storeLogo,
      storeCover: widget.storeCover,
    );
  }
}

/// Featured section: a coloured header band with the store logo + slogan, then
/// the product rail.
class _FeaturedSectionView extends StatefulWidget {
  final _FeaturedSection section;
  const _FeaturedSectionView({required this.section});

  @override
  State<_FeaturedSectionView> createState() => _FeaturedSectionViewState();
}

class _FeaturedSectionViewState extends State<_FeaturedSectionView> {
  /// Green gradient used until the logo's palette resolves (or if it can't).
  static const Color _fallbackTop = Color(0xFF057835);
  static const Color _fallbackBottom = Color(0xFFEBFEEB);
  static const Color _fallbackBorder = Color(0xFFCDEBD6);
  static const Color _fallbackLogoBg = Color(0xFF1F7A35);

  /// Memoize the accent per logo URL so re-scrolling doesn't recompute it.
  static final Map<String, Color> _accentCache = {};

  /// CDN requires a User-Agent (see [CustomImage]); reuse it so the palette
  /// reads the same bytes as the rendered logo.
  static const Map<String, String> _cdnHeaders = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// Accent colour extracted from the logo; null → use the green fallback.
  Color? _accent;

  @override
  void initState() {
    super.initState();
    _resolveAccent();
  }

  @override
  void didUpdateWidget(_FeaturedSectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.logo != widget.section.logo) {
      _accent = null;
      _resolveAccent();
    }
  }

  Future<void> _resolveAccent() async {
    final url = widget.section.logo;
    if (url == null || url.isEmpty) return;

    final cached = _accentCache[url];
    if (cached != null) {
      setState(() => _accent = cached);
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url, headers: _cdnHeaders),
        size: const Size(120, 120),
        maximumColorCount: 16,
      );
      final color = palette.vibrantColor?.color ??
          palette.darkVibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.mutedColor?.color ??
          palette.darkMutedColor?.color ??
          // Last resort: the most-populated swatch in the logo, so any colour
          // beats falling back to the default green.
          _mostPopulated(palette);
      if (color == null || !mounted) return;
      _accentCache[url] = color;
      setState(() => _accent = color);
    } catch (_) {
      // Keep the green fallback on any failure (e.g. the logo couldn't be
      // fetched/decoded by the palette pipeline).
    }
  }

  /// The colour of the most-populated swatch in [palette] (null when empty).
  Color? _mostPopulated(PaletteGenerator palette) {
    if (palette.paletteColors.isEmpty) return null;
    final sorted = [...palette.paletteColors]
      ..sort((a, b) => b.population - a.population);
    return sorted.first.color;
  }

  /// Darken a colour just enough that white text stays readable on top of it.
  Color _readableDark(Color c) {
    final hsl = HSLColor.fromColor(c);
    final l = hsl.lightness > 0.45 ? 0.40 : hsl.lightness;
    return hsl
        .withLightness(l)
        .withSaturation(hsl.saturation < 0.35 ? 0.35 : hsl.saturation)
        .toColor();
  }

  Color get _topColor =>
      _accent == null ? _fallbackTop : _readableDark(_accent!);
  Color get _bottomColor => _accent == null
      ? _fallbackBottom
      : Color.lerp(_readableDark(_accent!), Colors.white, 0.88)!;
  Color get _borderColor => _accent == null
      ? _fallbackBorder
      : Color.lerp(_readableDark(_accent!), Colors.white, 0.7)!;
  Color get _logoBg =>
      _accent == null ? _fallbackLogoBg : _readableDark(_accent!);

  /// "See more" / logo opens the branded offers screen (cover + logo + name
  /// header + sub-category strip only) for this featured store — distinct from a
  /// category tile tap, which opens the two-level categories browser.
  void _openOffers() {
    final section = widget.section;
    Get.to<void>(
      () => MarketOffersScreen(
        title: section.slogan ?? '',
        storeId: section.storeId,
        moduleId: section.moduleId ?? _marketModuleId,
        categoryId: 'offers',
        storeName: section.slogan,
        storeLogo: section.logo,
        storeCover: section.cover,
        brandedHeader: true,
        presetProducts: _toOfferProducts(section.products),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    if (section.products.isEmpty) return const SizedBox.shrink();
    // Clean section header: slogan (in the logo's accent colour) + a small store
    // logo, then the products as a 3-column grid below on white.
    final Color accent =
        _accent == null ? _fallbackTop : _readableDark(_accent!);
    return Padding(
      padding: const EdgeInsets.only(
        top: 4,
        bottom: Dimensions.paddingSizeSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault, 8, Dimensions.paddingSizeDefault, 10),
            child: GestureDetector(
              onTap: _openOffers,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section.slogan ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.2,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _logoBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CustomImage(
                      image: section.logo ?? '',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      placeholder: Images.placeholder,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ProductRail(
            products: section.products,
            storeId: section.storeId,
            moduleId: section.moduleId ?? _marketModuleId,
            onViewMore: _openOffers,
          ),
        ],
      ),
    );
  }
}

class _ProductRail extends StatelessWidget {
  final List<_Product> products;
  final int? storeId;

  /// Module the products belong to (featured sections may be cross-module).
  final int moduleId;

  /// When set, the rail shows at most [_previewLimit] products and appends a
  /// trailing "عرض المزيد" tile that opens the full list.
  final VoidCallback? onViewMore;

  const _ProductRail({
    required this.products,
    this.storeId,
    this.moduleId = _marketModuleId,
    this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    // Products as full-width rows (image + name + description + order count +
    // price). A capped section previews the first rows then a "عرض المزيد" pill
    // opens the full list.
    const int preview = 6;
    final bool cap = onViewMore != null && products.length > preview;
    final int shown = cap ? preview : products.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < shown; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              thickness: 1,
              indent: Dimensions.paddingSizeDefault,
              endIndent: Dimensions.paddingSizeDefault,
              color: Color(0xFFF0F1F3),
            ),
          _ListProductCard(
              product: products[i], storeId: storeId, moduleId: moduleId),
        ],
        if (cap)
          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 6,
                Dimensions.paddingSizeDefault, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SeeMorePill(onTap: onViewMore!),
            ),
          ),
      ],
    );
  }
}

/// Trailing "عرض المزيد" tile at the end of a product rail; opens the full list
/// once the rail's 5-product preview is capped.
class _ViewMoreTile extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewMoreTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusDefault);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFEBFEEB),
          borderRadius: radius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vertical (rotated) label.
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                'see_more'.tr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFF1F7A35),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Icon(Icons.arrow_downward,
                size: 16, color: Color(0xFF1F7A35)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final int? storeId;
  final int moduleId;
  const _ProductCard({
    required this.product,
    this.storeId,
    this.moduleId = _marketModuleId,
  });

  static const double _imageHeight = 62;

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    // Outer Stack so the "+" control can straddle the image's bottom edge and
    // still receive taps. (Clip.none only affects painting — a button placed
    // outside its parent's bounds gets no hit-test, so taps would fall through
    // to the card's open-product gesture instead of adding to the cart.)
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => MarketProductScreen.show(
            itemId: product.id ?? 0,
            storeId: storeId,
            moduleId: moduleId,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius,
              border: Border.all(color: const Color(0xFFEFEFF1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImage(
                  image: product.image ?? '',
                  width: double.infinity,
                  height: _imageHeight,
                  fit: BoxFit.cover,
                  placeholder: Images.placeholder,
                ),
                Expanded(
                  // Extra top padding clears the "+" button that overflows
                  // ~10px below the image, so it doesn't sit on top of the name.
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name ?? '',
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w500,
                            fontSize: 9,
                            height: 1.2,
                            color: Color(0xFF121C19),
                          ),
                        ),
                        const Spacer(),
                        // Price (struck original under the discounted price).
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            _price(product.shownPrice, bold: true),
                            if (product.hasDiscount)
                              _price(product.originalPrice, struck: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // "+" / qty stepper straddling the image's bottom-left. It lives in the
        // outer Stack (not the image) so the part overflowing below the image
        // stays tappable and adds to the cart instead of opening the product.
        Positioned(
          left: 5,
          top: _imageHeight - 16,
          child: _QtyAddControl(
            product: product,
            storeId: storeId,
            moduleId: moduleId,
          ),
        ),
      ],
    );
  }

  Widget _price(double value, {bool bold = false, bool struck = false}) {
    final color = struck ? const Color(0xFF9AA0A6) : const Color(0xFF121C19);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.sar,
            width: struck ? 8 : 10,
            height: struck ? 8 : 10,
            color: color,
            errorBuilder: (_, __, ___) => Text('﷼',
                style: robotoBold.copyWith(fontSize: 9, color: color)),
          ),
          const SizedBox(width: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: struck ? 9 : 11,
              decoration:
                  struck ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: const Color(0xFFE53935),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD1FDD2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.add, size: 18, color: Color(0xFF1F7A35)),
        ),
      ),
    );
  }
}

/// Add control for a product card: a green "+" circle that turns into a green
/// "- qty +" stepper once the item is in the cart. The add is silent (no toast);
/// this control reflects the count instead.
class _QtyAddControl extends StatelessWidget {
  final _Product product;
  final int? storeId;
  final int moduleId;
  const _QtyAddControl({
    required this.product,
    this.storeId,
    this.moduleId = _marketModuleId,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (_) {
        final int qty = _cartQty(product.id);
        if (qty == 0) {
          return _AddButton(
            onTap: () =>
                _addProductToCart(product, storeId, moduleId: moduleId),
          );
        }
        return Container(
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1F7A35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _step(Icons.remove, () => _decProductFromCart(product)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              _step(Icons.add,
                  () => _addProductToCart(product, storeId, moduleId: moduleId)),
            ],
          ),
        );
      },
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
