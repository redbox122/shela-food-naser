import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/home/screens/current_offers_screen.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/features/home/widgets/market/current_offers_repository.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: "العروض الحالية" — horizontal rail of current offers.
///
/// Wired to `GET /api/v2/stores/offers` (cross-module). Each card shows the
/// offer image, store logo, store name, offer description, and the original
/// (struck) + discounted price.
class HomeCurrentOffersSection extends StatefulWidget {
  /// When set, only this module's offers are shown (storefront screens).
  /// Null → aggregate offers across all modules (multi-module home).
  final int? moduleId;

  /// When true, the rail auto-scrolls every 10s, sliding right→left then
  /// left→right (used on the home, where all sections' offers are shown).
  final bool autoScroll;

  const HomeCurrentOffersSection(
      {super.key, this.moduleId, this.autoScroll = false});

  static const double _railHeight = 182;
  static const double _cardWidth = 155.5;

  @override
  State<HomeCurrentOffersSection> createState() =>
      _HomeCurrentOffersSectionState();
}

class _HomeCurrentOffersSectionState extends State<HomeCurrentOffersSection> {
  List<OfferItem> _offers = const []; // full list (for "عرض المزيد")
  List<OfferItem> _ordered = const []; // diversified (sections interleaved)
  bool _loading = true;

  /// "عرض المزيد" appears once there are more than this many offers; the rail
  /// itself is a horizontal strip the user swipes to reveal more.
  static const int _collapsedCount = 3;

  /// Drives the auto-scroll animation and stays attached to the rail.
  final ScrollController _scrollController = ScrollController();

  /// Periodic timer advancing the rail when [widget.autoScroll] is on.
  Timer? _autoScrollTimer;

  /// Current auto-scroll direction (toggles at each edge): true = right→left.
  bool _autoScrollForward = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final all = await fetchCurrentOffers(moduleId: widget.moduleId);
    if (!mounted) return;
    setState(() {
      _offers = all;
      // On the multi-module home, interleave by section so swiping the strip
      // alternates restaurants/cafés/markets/hyper instead of one section's run.
      _ordered = widget.moduleId == null ? _diversify(all) : all;
      _loading = false;
    });
    if (widget.autoScroll && _ordered.length > 1) _startAutoScroll();
  }

  /// Every 10s slide one card; reverse direction at each end so the rail loops
  /// right→left then left→right (و العكس).
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer =
        Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final ScrollPosition pos = _scrollController.position;
      // Step ≈ one card; flip direction when reaching either edge.
      const double step =
          HomeCurrentOffersSection._cardWidth + 8;
      double target =
          _scrollController.offset + (_autoScrollForward ? step : -step);
      if (target >= pos.maxScrollExtent) {
        target = pos.maxScrollExtent;
        _autoScrollForward = false;
      } else if (target <= pos.minScrollExtent) {
        target = pos.minScrollExtent;
        _autoScrollForward = true;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Round-robins offers across modules (one per section per round) so the
  /// horizontal strip alternates sections as the user swipes through it.
  List<OfferItem> _diversify(List<OfferItem> offers) {
    if (offers.length <= 1) return offers;
    final Map<int?, List<OfferItem>> byModule = {};
    for (final o in offers) {
      (byModule[o.moduleId] ??= <OfferItem>[]).add(o);
    }
    final groups = byModule.values.toList();
    final out = <OfferItem>[];
    int i = 0;
    bool added = true;
    while (added) {
      added = false;
      for (final g in groups) {
        if (i < g.length) {
          out.add(g[i]);
          added = true;
        }
      }
      i++;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _offers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Horizontal strip: shows ALL offers (diversified order); swipe to reveal
    // more. "عرض المزيد" opens the full vertical screen.
    final List<OfferItem> visible = _ordered;
    final bool canExpand = !_loading && _offers.length > _collapsedCount;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'current_offers'.tr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 1.4,
                      color: Color(0xFF121C19),
                    ),
                  ),
                ),
                if (canExpand)
                  _SeeMoreButton(
                    label: 'view_more'.tr,
                    onTap: () => Get.to<void>(
                      () => CurrentOffersScreen(offers: _offers),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            height: HomeCurrentOffersSection._railHeight,
            child: _loading
                ? _buildSkeleton(context)
                : ListView.separated(
                    controller: widget.autoScroll ? _scrollController : null,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => _OfferCard(offer: visible[index]),
                  ),
          ),
        ],
      ),
    );
  }

  /// Skeleton bones rendered from the real [_OfferCard] layout with dummy data,
  /// so the loading rail matches the live cards exactly.
  Widget _buildSkeleton(BuildContext context) {
    final OfferItem dummy = OfferItem(
      storeName: 'اسم المتجر',
      description: 'وصف العرض الحالي',
      storeLogo: '',
      imageUrl: '',
      originalPrice: 51.95,
      discountedPrice: 31.95,
    );
    return Skeletonizer(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => _OfferCard(offer: dummy),
      ),
    );
  }
}

/// "عرض المزيد" pill shown beside the section header to reveal the rest of the
/// collapsed offers list (presentation-only; the tap handler is the caller's).
class _SeeMoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SeeMoreButton({required this.label, required this.onTap});

  /// Disabled-button text token hsba(0, 0%, 33%) ≈ #545454.
  static const Color _fg = Color(0xFF545454);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        // Container spec: 83×26, 6px padding, 4px radius, 10px gap.
        child: Container(
          width: 83,
          height: 26,
          decoration: BoxDecoration(
            color: Color(0xffF6F5F8),
          ),
          padding: const EdgeInsets.all(6),
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.right,
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
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferItem offer;

  const _OfferCard({required this.offer});

  // Height of the top offer image; the logo straddles its bottom edge.
  static const double _imageHeight = 68;
  static const double _logoWidth = 40;
  static const double _logoHeight = 46;

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);


  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    return InkWell(
      borderRadius: radius,
      onTap: () => showOfferDetailSheet(offer),
      child: Container(
        width: HomeCurrentOffersSection._cardWidth,
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top: the offer image.
                CustomImage(
                  image: offer.imageUrl ?? '',
                  width: HomeCurrentOffersSection._cardWidth,
                  height: _imageHeight,
                  fit: BoxFit.cover,
                  placeholder: Images.placeholder,
                ),
                // Bottom: info section.
                Expanded(
                  child: Container(
                    color: const Color(0xFFF6F5F8),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Store name — sits beside the logo on the right.
                            Padding(
                              padding: const EdgeInsets.only(right: 50),
                              child: Text(
                                offer.storeName ?? '',
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.2,
                                  color: Color(0xFF121C19),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Price: new (red, bold) + old (struck grey).
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(Images.sar,
                                      width: 9,
                                      height: 9,
                                      color: const Color(0xFFE53935)),
                                  const SizedBox(width: 2),
                                  Text(
                                    _fmt(offer.discountedPrice),
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                  if (offer.originalPrice >
                                      offer.discountedPrice) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      _fmt(offer.originalPrice),
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                        color: Color(0xFF9AA0A6),
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: Color(0xFF9AA0A6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        // 🛵 Delivery line: time + free (green) / fee.
                        Row(
                          children: [
                            const Text('🛵', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            if ((offer.deliveryTime ?? '').isNotEmpty)
                              Text(
                                offer.deliveryTime!,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 9,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            const Spacer(),
                            if (offer.freeDelivery)
                              Text(
                                'free_delivery'.tr,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                  color: Color(0xFF1F7A35),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Store logo straddling the image / info boundary, on the right.
            Positioned(
              right: Dimensions.paddingSizeSmall,
              top: _imageHeight - (_logoHeight / 2),
              child: Container(
                width: _logoWidth,
                height: _logoHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  border: Border.all(color: Colors.white, width: 2),
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
            // Quick-add (+) button — yellow, bottom-left of the card. Wired to
            // the cart via the offer's item_id; turns into a counter once added.
            if (offer.itemId != null)
              Positioned(
                left: 6,
                bottom: 6,
                child: _OfferAddButton(offer: offer),
              ),
            // ⚡ Discount badge on the image (bottom-left), yellow.
            if (_discountPct() > 0)
              Positioned(
                left: 6,
                top: _imageHeight - 18,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚡ ${'discount_label'.tr} ${_discountPct()}%',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      height: 1.2,
                      color: Color(0xFF121C19),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Discount percentage from the prices (0 when there is no real discount).
  int _discountPct() {
    if (offer.originalPrice > offer.discountedPrice && offer.originalPrice > 0) {
      return (((offer.originalPrice - offer.discountedPrice) /
                  offer.originalPrice) *
              100)
          .round();
    }
    return 0;
  }
}

/// Yellow quick-add control on an offer card. Shows a (+) when the item isn't in
/// the cart; once added it becomes a compact green counter (− qty +). Rebuilds
/// live with the cart via [GetBuilder].
class _OfferAddButton extends StatelessWidget {
  final OfferItem offer;
  const _OfferAddButton({required this.offer});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (_) {
        // Items with required options never blind-add: the (+) always routes to
        // the product detail page so the customer completes the options there.
        if (offer.hasVariations) {
          return _yellowPlus(() => _openOfferItemDetails(offer));
        }
        final int qty = _offerCartQty(offer.itemId);
        if (qty == 0) {
          // First add: drop into the cart, then open the store with its cart bar.
          return _yellowPlus(() => _addOfferToCart(offer, openStore: true));
        }
        return Container(
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF1F7A35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _step(Icons.remove, () => _decOfferFromCart(offer)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              // Stepper increment: just adjust the quantity, stay in place.
              _step(Icons.add, () => _addOfferToCart(offer, openStore: false)),
            ],
          ),
        );
      },
    );
  }

  /// The prominent yellow circular (+) used for the first add / options route.
  Widget _yellowPlus(VoidCallback onTap) {
    return Material(
      color: const Color(0xFFFFC107),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.add, size: 18, color: Color(0xFF121C19)),
        ),
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }
}

/// Units of the offer's item currently in the cart.
int _offerCartQty(int? itemId) {
  if (itemId == null || !Get.isRegistered<CartController>()) return 0;
  int q = 0;
  for (final c in Get.find<CartController>().cartList) {
    if (c.item?.id == itemId) q += c.quantity ?? 0;
  }
  return q;
}

/// Cart line id for the offer's item (null when not in the cart).
int? _offerCartLineId(int? itemId) {
  if (itemId == null || !Get.isRegistered<CartController>()) return null;
  for (final c in Get.find<CartController>().cartList) {
    if (c.item?.id == itemId) return c.id;
  }
  return null;
}

/// Opens the product detail page for an offer's item — used when the item has
/// options/variations so the customer can complete them before adding.
void _openOfferItemDetails(OfferItem offer) {
  if (offer.itemId == null) return;
  Get.toNamed<void>(RouteHelper.getItemDetailsRoute(offer.itemId, false));
}

/// Opens the offer's store page (with the cover header so the sticky cart bar
/// shows), so the customer lands inside the store right after adding.
void _openOfferStore(OfferItem offer) {
  if (offer.storeId == null) return;
  Get.to<void>(() => MarketStoreScreen(
        storeId: offer.storeId,
        moduleId: offer.moduleId ?? 3,
        name: offer.storeName,
        logo: offer.storeLogo,
        rating: offer.rating,
        freeDelivery: offer.freeDelivery,
        deliveryTime: offer.deliveryTime,
        useCoverHeader: true,
      ));
}

/// Adds one unit of the offer's item to the online cart, aligning the active /
/// cache module to the offer's module first (so the cart saves under the right
/// module). Confirms clearing the cart when it already holds another store.
/// When [openStore] is true (the first prominent add), lands the customer inside
/// the store with its cart bar; the stepper increment passes false to stay put.
Future<void> _addOfferToCart(OfferItem offer, {bool openStore = false}) async {
  if (offer.itemId == null || !Get.isRegistered<CartController>()) return;
  final cartController = Get.find<CartController>();

  if (cartController.existAnotherStoreItem(offer.storeId, offer.moduleId)) {
    final bool confirmed = await _confirmClearOfferCart();
    if (!confirmed) return;
    await cartController.clearCartList();
  }

  if (Get.isRegistered<SplashController>() && offer.moduleId != null) {
    final sc = Get.find<SplashController>();
    for (final m in sc.moduleList ?? const []) {
      if (m.id == offer.moduleId) {
        if (sc.module?.id != offer.moduleId) await sc.setModuleHeaderOnly(m);
        await sc.setCacheModuleOnly(m);
        break;
      }
    }
  }

  final cart = OnlineCart(
    null,
    offer.itemId,
    null,
    offer.discountedPrice.toString(),
    '',
    [],
    [],
    1,
    [],
    [],
    [],
    'Item',
    itemType: 'Item',
    storeId: offer.storeId,
  );
  try {
    bool ok = await cartController.addToCartOnline(cart);
    if (!ok && cartController.lastAddToCartErrorCode == 'different_store') {
      final bool confirmed = await _confirmClearOfferCart();
      if (!confirmed) return;
      await cartController.clearCartList();
      ok = await cartController.addToCartOnline(cart);
    }
    if (!ok) {
      showCustomSnackBar('failed_to_add_to_cart'.tr, isError: true);
    } else if (openStore) {
      // Added from the prominent (+): land the customer inside the store so they
      // see the updated cart bar and don't have to find the store themselves.
      _openOfferStore(offer);
    }
  } catch (e) {
    showCustomSnackBar(e.toString(), isError: true);
  }
}

/// Removes one unit of the offer's item (or the whole line at zero).
Future<void> _decOfferFromCart(OfferItem offer) async {
  if (!Get.isRegistered<CartController>()) return;
  final cartController = Get.find<CartController>();
  final int? lineId = _offerCartLineId(offer.itemId);
  if (lineId == null) return;
  try {
    if (_offerCartQty(offer.itemId) <= 1) {
      await cartController.removeFromCartById(lineId);
    } else {
      await cartController.setQuantityById(false, lineId, 9999, 0);
    }
  } catch (e) {
    showCustomSnackBar(e.toString(), isError: true);
  }
}

/// "هذا المتجر مختلف…" confirm dialog before clearing a cross-store cart.
Future<bool> _confirmClearOfferCart() async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('cart_has_other_store_items'.tr,
          style: const TextStyle(
              fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 16)),
      content: Text('clear_cart_to_continue'.tr,
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Get.back<bool>(result: false),
          child: Text('cancel'.tr,
              style: const TextStyle(fontFamily: 'Tajawal')),
        ),
        TextButton(
          onPressed: () => Get.back<bool>(result: true),
          child: Text('clear_and_add'.tr,
              style: const TextStyle(
                  fontFamily: 'Tajawal', color: Color(0xFFE53935))),
        ),
      ],
    ),
  );
  return result == true;
}
