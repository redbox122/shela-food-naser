import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 UNIFIED store card — the single row-style store card used across every
/// store list in the app (market/sections, search, favourites, alternative
/// stores in order history, …). RTL layout: square logo leads on the right,
/// info (name · rating + distance · delivery time · badges) on the left.
///
/// It takes plain primitives (not a specific model) so any caller can map its
/// own data into it — keeping ONE design that a future tweak updates everywhere.
/// Per the catalogue rule, a store with no logo should not be built into a list
/// at all, so [logo] is expected to be a real image url.
class StoreListCard extends StatelessWidget {
  final String? name;

  /// Full image url for the store logo/cover.
  final String? logo;

  /// Average rating (0–5).
  final double rating;

  /// Distance from the customer in METRES (0 / negative → hidden).
  final double distanceMetres;

  /// Delivery-time label as returned by the backend, e.g. "20 - 40".
  final String? deliveryTime;

  final bool freeDelivery;
  final bool qidha;
  final bool hasOffer;

  /// Discount amount/percent + type ('percent' / 'amount') + min purchase, used
  /// to render the "خصم …" badge. [discountValue] 0 → no discount badge.
  final double discountValue;
  final String discountType;
  final double minPurchase;

  final VoidCallback? onTap;

  const StoreListCard({
    super.key,
    required this.name,
    required this.logo,
    this.rating = 0,
    this.distanceMetres = 0,
    this.deliveryTime,
    this.freeDelivery = false,
    this.qidha = false,
    this.hasOffer = false,
    this.discountValue = 0,
    this.discountType = '',
    this.minPurchase = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusLarge);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
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
        // RTL row: logo square leads on the right, info on the left.
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImage(
                image: logo ?? '',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: Images.placeholder,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name (own line, right-aligned).
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      name ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.3,
                        color: Color(0xFF121C19),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating + distance badges side by side.
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE7F7EA),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            textDirection: TextDirection.ltr,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Image.asset(
                                Images.star_v2,
                                width: 12,
                                height: 12,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.star, size: 12),
                              ),
                            ],
                          ),
                        ),
                        // Distance pill (filled Shella-green), e.g. "3.5 كم".
                        if (_distanceText(distanceMetres) != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF30913F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  _distanceText(distanceMetres)!,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Delivery time: ⏱ "20 - 40 دقيقة".
                  if (deliveryTime != null && deliveryTime!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Image.asset(
                          Images.time_v2,
                          width: 15,
                          height: 15,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.access_time,
                            size: 15,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$deliveryTime دقيقة',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF717885),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Badges.
                  if (qidha || freeDelivery || discountValue > 0 || hasOffer) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (qidha)
                          _Badge(
                            label: 'qidha_system'.tr,
                            bg: const Color(0xFFE7F7EA),
                            fg: const Color(0xFF1F7A35),
                            icon: Icons.verified_user_outlined,
                          ),
                        if (freeDelivery)
                          _Badge(
                            label: 'free_delivery'.tr,
                            bg: const Color(0xFFE7F7EA),
                            fg: const Color(0xFF1F7A35),
                          ),
                        if (discountValue > 0)
                          _Badge(
                            label: _discountLabel(),
                            bg: const Color(0xFFF1ECFF),
                            fg: const Color(0xFF6B4FBB),
                          )
                        else if (hasOffer)
                          _Badge(
                            label: 'offers'.tr,
                            bg: const Color(0xFFF1ECFF),
                            fg: const Color(0xFF6B4FBB),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Distance label from metres: under 1 km → "800 م", otherwise "1.2 كم".
  /// Returns null when unknown (0 / no coordinates) so nothing is shown.
  static String? _distanceText(double metres) {
    if (metres <= 0) return null;
    if (metres < 1000) return '${metres.round()} م';
    return '${(metres / 1000).toStringAsFixed(1)} كم';
  }

  /// "خصم 45% على 250" (percent) or "خصم 45 على 250" (amount). The "على {min}"
  /// part is dropped when there is no minimum purchase.
  String _discountLabel() {
    final value = _fmt(discountValue);
    final suffix = discountType == 'percent' ? '%' : '';
    final base = '${'discount_label'.tr} $value$suffix';
    if (minPurchase > 0) {
      return '$base ${'on'.tr} ${_fmt(minPurchase)}';
    }
    return base;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
