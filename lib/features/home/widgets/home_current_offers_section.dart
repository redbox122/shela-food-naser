import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/screens/current_offers_screen.dart';
import 'package:sixam_mart/features/home/widgets/market/current_offers_repository.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: "العروض الحالية" — horizontal rail of current offers.
///
/// Wired to `GET /api/v2/stores/offers` (cross-module). Each card shows the
/// offer image, store logo, store name, offer description, and the original
/// (struck) + discounted price.
class HomeCurrentOffersSection extends StatefulWidget {
  const HomeCurrentOffersSection({super.key});

  static const double _railHeight = 152;
  static const double _cardWidth = 155.5;

  @override
  State<HomeCurrentOffersSection> createState() =>
      _HomeCurrentOffersSectionState();
}

class _HomeCurrentOffersSectionState extends State<HomeCurrentOffersSection> {
  List<OfferItem> _offers = const [];
  bool _loading = true;

  /// The rail shows only the first [_collapsedCount] offers; "عرض المزيد" opens
  /// the full [CurrentOffersScreen].
  static const int _collapsedCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final all = await fetchCurrentOffers();
    if (!mounted) return;
    setState(() {
      _offers = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _offers.isEmpty) {
      return const SizedBox.shrink();
    }

    // The rail shows the first 3 offers; "عرض المزيد" opens the full screen.
    final List<OfferItem> visible = _offers.take(_collapsedCount).toList();
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
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) =>
                        _OfferCard(offer: visible[index]),
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

  /// Discount line shown below the store name — never a price. Prefers a
  /// server-provided description; otherwise the percentage computed from the
  /// prices; otherwise the payload's discount_amount; otherwise the title.
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
                            // Discount below the name (never a price).
                            Text(
                              _discountText(),
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
          ],
        ),
      ),
    );
  }

}
