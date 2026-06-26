import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/screens/home_search_screen.dart';
import 'package:sixam_mart/features/home/widgets/home_top_notice_strip.dart';
import 'package:sixam_mart/features/home/widgets/market/current_offers_repository.dart';
import 'package:sixam_mart/features/home/widgets/market/offers_filter_sheet.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 REDESIGN: "العروض الحالية" full screen — opened from the "عرض المزيد"
/// button on the home/market current-offers rail. Shows every offer as a wide
/// card, with a filter sheet (الشحن + فئة المتاجر) reachable from the header.
class CurrentOffersScreen extends StatefulWidget {
  /// Offers already loaded by the rail (passed through to avoid a refetch). When
  /// empty, the screen fetches them itself.
  final List<OfferItem> offers;

  /// Module used to scope the filter's store-category list (null = active).
  final int? moduleId;

  const CurrentOffersScreen({super.key, this.offers = const [], this.moduleId});

  @override
  State<CurrentOffersScreen> createState() => _CurrentOffersScreenState();
}

class _CurrentOffersScreenState extends State<CurrentOffersScreen> {
  late List<OfferItem> _offers = widget.offers;
  bool _loading = false;
  OffersFilter _filter = const OffersFilter();

  @override
  void initState() {
    super.initState();
    if (_offers.isEmpty) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    }
  }

  Future<void> _fetch() async {
    final all = await fetchCurrentOffers();
    if (!mounted) return;
    setState(() {
      _offers = all;
      _loading = false;
    });
  }

  /// Client-side filtering for the fields the offers payload carries today.
  ///
  /// The store-category filter only applies when the offers actually carry
  /// category ids — otherwise it's a no-op so a selection doesn't wipe the list
  /// (the payload doesn't always include category data).
  /// 🚧 TODO(endpoint): `fast_delivery` needs a per-offer delivery-speed flag,
  /// which the offers payload doesn't carry yet.
  List<OfferItem> get _visible {
    final int? catId = _filter.categoryId;
    final bool canFilterByCat =
        catId != null && _offers.any((o) => o.categoryIds.isNotEmpty);
    return _offers.where((o) {
      if (_filter.shipping == 'free_delivery' && !o.freeDelivery) {
        return false;
      }
      if (canFilterByCat && !o.categoryIds.contains(catId)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openFilter() async {
    final result = await showOffersFilterSheet(
      context,
      moduleId: widget.moduleId,
      initial: _filter,
    );
    if (result != null && mounted) setState(() => _filter = result);
  }

  bool get _hasFilter => _filter.shipping != null || _filter.categoryId != null;

  @override
  Widget build(BuildContext context) {
    final List<OfferItem> visible = _visible;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          _Header(onFilter: _openFilter, filterActive: _hasFilter),
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: HomeTopNoticeStrip()),
                if (_loading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    sliver: Skeletonizer.sliver(
                      child: SliverList.separated(
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(
                            height: Dimensions.paddingSizeDefault),
                        itemBuilder: (_, __) => _WideOfferCard(
                          offer: OfferItem(
                            storeName: 'اسم المتجر',
                            description: 'خصم 30% من قسم الخضروات',
                            storeLogo: '',
                            imageUrl: '',
                            originalPrice: 51.95,
                            discountedPrice: 31.95,
                            rating: 5.0,
                            freeDelivery: true,
                            deliveryTime: '20 دقيقة',
                          ),
                        ),
                      ),
                    ),
                  )
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
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
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                      itemBuilder: (_, i) => _WideOfferCard(offer: visible[i]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header: back chevron (RTL right), centered title, filter icon (RTL left).
class _Header extends StatelessWidget {
  final VoidCallback onFilter;
  final bool filterActive;

  const _Header({required this.onFilter, required this.filterActive});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Get.back<void>(),
              showBackground: false,
            ),
            Expanded(
              child: Text(
                'current_offers'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.2,
                  color: Color(0xFF121C19),
                ),
              ),
            ),
            // Filter button: candle-1 idle, candle-2 when a filter is applied.
            _CircleImageButton(
              asset: filterActive
                  ? Images.filterCandleActive
                  : Images.filterCandle,
              onTap: onFilter,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBackground;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: showBackground ? const Color(0xFFF4F5F7) : Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: const Color(0xFF121C19)),
        ),
      ),
    );
  }
}

/// Circular button whose glyph is an image asset (used for the filter button so
/// it can swap between the idle / applied artwork).
class _CircleImageButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;

  const _CircleImageButton({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F5F7),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            asset,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.tune,
              size: 22,
              color: Color(0xFF121C19),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wide offer card: full-width banner image with a rating badge, then store
/// name, offer description, delivery info and the (struck) price.
class _WideOfferCard extends StatelessWidget {
  final OfferItem offer;

  const _WideOfferCard({required this.offer});

  // Banner height + logo box (71.43 × 75.65) straddling the banner/footer edge
  // on the right. The card sizes to its content (no fixed height) so the footer
  // never overflows.
  static const double _imageHeight = 84;
  static const double _logoWidth = 71.43;
  static const double _logoHeight = 75.65;

  /// Zoom applied to the banner image inside its fixed-size box — enlarges the
  /// image (more zoomed-in) WITHOUT growing the box or the card. 1.0 = no zoom.
  static const double _imageZoom = 1.25;

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Discount line shown below the store name — never a price. Prefers a
  /// server-provided description (e.g. "خصم 30% من قسم الخضروات"); otherwise the
  /// percentage computed from the original vs. discounted price; otherwise the
  /// payload's discount_amount/type; otherwise the offer title.
  String _discountText() {
    final desc = (offer.description ?? '').trim();
    if (desc.isNotEmpty) return desc;
    if (offer.originalPrice > offer.discountedPrice &&
        offer.originalPrice > 0) {
      final pct = (((offer.originalPrice - offer.discountedPrice) /
                  offer.originalPrice) *
              100)
          .round();
      if (pct > 0) return '${'discount_label'.tr} $pct%';
    }
    if (offer.discountAmount > 0) {
      final suffix = offer.discountType == 'percent' ? '%' : '';
      return '${'discount_label'.tr} ${_fmt(offer.discountAmount)}$suffix';
    }
    final title = (offer.offerTitle ?? '').trim();
    return title.isNotEmpty ? title : 'special_offer'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final bool hasTime = offer.deliveryTime?.isNotEmpty ?? false;
    final bool hasDelivery = offer.freeDelivery || hasTime;
    final bool hasPrice = offer.discountedPrice > 0 || offer.originalPrice > 0;

    return InkWell(
      borderRadius: radius,
      onTap: () => showOfferDetailSheet(offer),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner with the rating badge (top-right).
                  Stack(
                    children: [
                      // Fixed-size box; the image is zoomed inside it and the
                      // overflow is clipped, so the box/card stays the same size.
                      SizedBox(
                        width: double.infinity,
                        height: _imageHeight,
                        child: ClipRect(
                          child: Transform.scale(
                            scale: _imageZoom,
                            child: CustomImage(
                              image: offer.imageUrl ?? '',
                              width: double.infinity,
                              height: _imageHeight,
                              fit: BoxFit.cover,
                              placeholder: Images.placeholder,
                            ),
                          ),
                        ),
                      ),
                      // Rating badge flush to the top-right corner, with a
                      // leaf-shaped radius (top-right + bottom-left rounded).
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _ratingBadge(),
                      ),
                      // Delivery info: free-delivery and time each in their OWN
                      // white pill (separate containers), at the bottom beside
                      // the store logo (which sits on the right).
                      if (hasDelivery)
                        Positioned(
                          right: _logoWidth + 16,
                          bottom: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (offer.freeDelivery)
                                _deliveryPill(_freeDeliveryChip(context)),
                              if (offer.freeDelivery && hasTime)
                                const SizedBox(width: 6),
                              if (hasTime) _deliveryPill(_timeChip(context)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Store text — padded clear of the logo box on the RIGHT.
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(10, 8, _logoWidth + 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          offer.storeName ?? '',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.4, // 140% (design)
                            color: Color(0xFF121C19),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Discount line below the name (design spec: Tajawal
                        // 700 / 14px / 140% / right; colour --Text-Headline
                        // hsba(162,37%,11%) ≈ #121C19).
                        Text(
                          _discountText(),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF121C19),
                          ),
                        ),
                        // Discounted price + original (struck) price (design).
                        if (hasPrice) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _priceRow(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Store logo box (71.43 × 75.65) straddling the banner/footer
              // boundary on the RIGHT.
              Positioned(
                right: 8,
                top: _imageHeight - 38,
                child: Container(
                  width: _logoWidth,
                  height: _logoHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomImage(
                    image: offer.storeLogo ?? '',
                    width: _logoWidth,
                    height: _logoHeight,
                    fit: BoxFit.cover,
                    placeholder: Images.placeholder,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratingBadge() {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xff9DFCA3),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            offer.rating.toStringAsFixed(1),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF121C19),
            ),
          ),
          const SizedBox(width: 2),
          Image.asset(
            Images.star_v2,
            width: 12,
            height: 12,
            errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 12),
          ),
        ],
      ),
    );
  }

  /// White rounded pill that wraps a single delivery chip.
  Widget _deliveryPill(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  /// "🚚 توصيل مجاني" chip.
  Widget _freeDeliveryChip(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          Images.truck_delivery_v2,
          width: 14,
          height: 14,
          errorBuilder: (_, __, ___) => Icon(
            Icons.delivery_dining,
            size: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          'free_delivery'.tr,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ],
    );
  }

  /// "⏱ 20 دقيقة" chip.
  Widget _timeChip(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          Images.time_v2,
          width: 14,
          height: 14,
          errorBuilder: (_, __, ___) => Icon(
            Icons.access_time,
            size: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          offer.deliveryTime ?? '',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context) {
    // RTL order: discounted price sits on the RIGHT (the prominent one), the
    // struck original to its left — matches the design.
    return Row(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (offer.originalPrice > offer.discountedPrice) ...[
          _price(context, offer.originalPrice, struck: true),
          const SizedBox(width: 4),
        ],
        _price(context, offer.discountedPrice),
      ],
    );
  }

  Widget _price(BuildContext context, double value, {bool struck = false}) {
    final Color color =
        struck ? const Color(0xFF717885) : const Color(0xFF121C19);
    // Riyal symbol to the LEFT of the number (forced LTR so it's consistent
    // regardless of the surrounding RTL layout).
    final Widget row = Row(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          Images.sar,
          width: struck ? 12 : 14,
          height: struck ? 12 : 14,
          color: color,
          errorBuilder: (_, __, ___) =>
              Text('﷼', style: robotoBold.copyWith(fontSize: 12, color: color)),
        ),
        const SizedBox(width: 2),
        Text(
          _fmt(value),
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: struck ? FontWeight.w500 : FontWeight.w700,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
    if (!struck) return row;
    return Stack(
      alignment: Alignment.center,
      children: [
        row,
        const Positioned.fill(
          child: Center(
            child: Divider(color: Color(0xFFE53935), thickness: 1.5, height: 0),
          ),
        ),
      ],
    );
  }
}

// ─── Offer detail bottom sheet ────────────────────────────────────────────────

/// Opens the tapped offer as a bottom sheet.
///
/// 🚧 Option B (interim): the offers endpoint carries no product/item id, so we
/// can only show the fields it provides (image, title, description, price,
/// store). The product "options" section + add-to-cart will be wired once the
/// backend returns an `item_id` (then this opens [MarketProductScreen] instead).
Future<void> showOfferDetailSheet(OfferItem offer) {
  return Get.bottomSheet<void>(
    _OfferDetailSheet(offer: offer),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _OfferDetailSheet extends StatelessWidget {
  final OfferItem offer;
  const _OfferDetailSheet({required this.offer});

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  String get _title {
    final t = (offer.offerTitle ?? '').trim();
    if (t.isNotEmpty) return t;
    final d = (offer.description ?? '').trim();
    return d.isNotEmpty ? d : 'special_offer'.tr;
  }

  Widget _circleBtn({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: fg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPrice = offer.discountedPrice > 0 || offer.originalPrice > 0;
    final bool hasOldPrice = offer.originalPrice > offer.discountedPrice;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
          // Grab handle.
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E5EA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image + close button + discount badge + favorite/add.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomImage(
                            image: offer.imageUrl ?? '',
                            width: double.infinity,
                            height: 230,
                            fit: BoxFit.cover,
                            placeholder: Images.placeholder,
                          ),
                        ),
                      ),
                      // Favorite + add buttons stacked on the left, straddling
                      // the image's bottom edge (matches the design).
                      Positioned(
                        left: 22,
                        bottom: -22,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _circleBtn(
                              icon: Icons.favorite_border,
                              bg: Colors.white,
                              fg: const Color(0xFF121C19),
                              onTap: () {},
                            ),
                            const SizedBox(height: 10),
                            _circleBtn(
                              icon: Icons.add,
                              bg: const Color(0xFFD1FDD2),
                              fg: const Color(0xFF1F7A35),
                              onTap: () {
                                Get.back<void>();
                                openOfferStore(offer);
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 18,
                        left: 18,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Get.back<void>(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close,
                                  size: 20, color: Color(0xFF121C19)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Offer title (store name intentionally omitted — the
                        // design starts the details with the offer title).
                        Text(
                          _title,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            height: 1.4,
                            color: Color(0xFF121C19),
                          ),
                        ),
                        if ((offer.description ?? '').trim().isNotEmpty &&
                            (offer.description ?? '').trim() != _title) ...[
                          const SizedBox(height: 6),
                          Text(
                            offer.description!.trim(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              height: 1.5,
                              color: Color(0xFF717885),
                            ),
                          ),
                        ],
                        if (hasPrice) ...[
                          const SizedBox(height: 12),
                          Row(
                            textDirection: TextDirection.ltr,
                            children: [
                              // Discount text on the LEFT, prices on the RIGHT.
                              if (_discountText() != null)
                                _discountChip(_discountText()!),
                              const Spacer(),
                              if (hasOldPrice) ...[
                                _sheetPrice(offer.originalPrice, struck: true),
                                const SizedBox(width: 8),
                              ],
                              _sheetPrice(offer.discountedPrice),
                            ],
                          ),
                        ],
                        // Bottom breathing room so the floating cart pill never
                        // overlaps the price.
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
          // Floating cart + search pill (design: green rounded pill, centred
          // above the bottom edge).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(child: _floatingActions()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Discount label shown in the price row (e.g. "خصم 44%"). Prefers the
  /// payload's discount_amount/type; otherwise derives the percentage from the
  /// original vs. discounted price. Returns null when there's no discount.
  String? _discountText() {
    if (offer.discountAmount > 0) {
      final suffix = offer.discountType == 'percent' ? '%' : '';
      return '${'discount_label'.tr} ${_fmt(offer.discountAmount)}$suffix';
    }
    if (offer.originalPrice > offer.discountedPrice && offer.originalPrice > 0) {
      final pct = (((offer.originalPrice - offer.discountedPrice) /
                  offer.originalPrice) *
              100)
          .round();
      if (pct > 0) return '${'discount_label'.tr} $pct%';
    }
    return null;
  }

  Widget _discountChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1F7A35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Green rounded pill (128×64) split into two distinct-shaded sections: a cart
  /// circle (darker green) and a search circle (brighter green).
  Widget _floatingActions() {
    const Color base = Color(0xFF1F7A35);
    final Color cartColor = Color.lerp(base, Colors.black, 0.18)!;
    final Color searchColor = Color.lerp(base, Colors.white, 0.22)!;
    return Material(
      color: base,
      borderRadius: BorderRadius.circular(25),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 128,
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _fabIcon(
              asset: Images.bag_v2,
              fallback: Icons.shopping_bag_outlined,
              bg: cartColor,
              onTap: () {
                Get.back<void>();
                Get.toNamed(RouteHelper.getCartRoute());
              },
            ),
            _fabIcon(
              asset: Images.search_v2,
              fallback: Icons.search,
              bg: searchColor,
              onTap: () {
                Get.back<void>();
                // Scope the search to the active module (rule #1).
                Get.to<void>(() => HomeSearchScreen(
                      moduleId: Get.isRegistered<SplashController>()
                          ? Get.find<SplashController>().module?.id
                          : null,
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _fabIcon({
    required String asset,
    required IconData fallback,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            asset,
            width: 24,
            height: 24,
            color: Colors.white,
            errorBuilder: (_, __, ___) =>
                Icon(fallback, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _sheetPrice(double value, {bool struck = false}) {
    final Color color =
        struck ? const Color(0xFF9AA0A6) : const Color(0xFF1F7A35);
    final Widget row = Row(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          Images.sar,
          width: struck ? 13 : 16,
          height: struck ? 13 : 16,
          color: color,
          errorBuilder: (_, __, ___) =>
              Text('﷼', style: robotoBold.copyWith(fontSize: 13, color: color)),
        ),
        const SizedBox(width: 3),
        Text(
          _fmt(value),
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: struck ? FontWeight.w500 : FontWeight.w700,
            fontSize: struck ? 14 : 18,
            color: color,
          ),
        ),
      ],
    );
    if (!struck) return row;
    return Stack(
      alignment: Alignment.center,
      children: [
        row,
        const Positioned.fill(
          child: Center(
            child: Divider(color: Color(0xFFE53935), thickness: 1.5, height: 0),
          ),
        ),
      ],
    );
  }
}
