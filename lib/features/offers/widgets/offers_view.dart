// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import '../../../helper/route_helper.dart';
import '../../../util/styles.dart';

const double _kOfferCardWidth = 330.0;
// Height matches the componant.png art ratio (1134x493 ≈ 2.30) so the green
// circle in the background stays round.
const double _kOfferCardHeight = 150.0;
const double _kOfferCardVerticalMargin = 4.0;
const double _kOfferListHeight =
    _kOfferCardHeight + _kOfferCardVerticalMargin * 2;

/// Hidden on home offers strip; same entry remains under Menu → More.
bool _isInvestInQidhaOfferCard(Datum offer) {
  final String name = (offer.name ?? '').trim();
  if (name.isEmpty) {
    return false;
  }
  final String localized = 'invest_her_bond'.tr.trim();
  if (name == localized) {
    return true;
  }
  return name.contains('أستثمر') && name.contains('قيدها');
}

class OffersView extends StatelessWidget {
  const OffersView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OffersController>(
      builder: (OffersController controller) {
        final List<Datum> rawOffers = controller.offersMode?.data ?? <Datum>[];
        final List<Datum> offers = rawOffers
            .where((Datum o) => !_isInvestInQidhaOfferCard(o))
            .toList();

        // No offers → hide the section entirely. The skeleton is shown ONLY
        // while a fetch is genuinely in flight (controller.isLoading). We must
        // NOT key the skeleton off `offersMode == null`, because on the
        // multi-module screen offers may never be fetched, which would keep the
        // skeleton spinning forever.
        if (offers.isEmpty) {
          return controller.isLoading
              ? const _OffersLoadingSkeleton()
              : const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            const _OffersSectionHeader(),
            SizedBox(
              height: _kOfferListHeight,
              child: AnimationLimiter(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Offers(
                            offer: offers[index],
                            onTap: () {
                              Get.toNamed<void>(
                                RouteHelper.getOffersItemScreen(
                                  offers[index].id,
                                  offers[index].name,
                                  offerDiscount:
                                      offers[index].discountMax?.toDouble(),
                                ),
                              );
                              controller.getOffersItemList(
                                id: offers[index].id.toString(),
                                offset: 1,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OffersSectionHeader extends StatelessWidget {
  const _OffersSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              'offers_and_discounts'.tr,
              style: tajawalBold.copyWith(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersLoadingSkeleton extends StatelessWidget {
  const _OffersLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final Color bone =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: Dimensions.fontSizeLarge),
        const _OffersSectionHeader(),
        SizedBox(
          height: _kOfferListHeight,
          child: Skeletonizer(
            enabled: true,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
              ),
              itemCount: 3,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 12,
                    top: _kOfferCardVerticalMargin,
                    bottom: _kOfferCardVerticalMargin,
                  ),
                  child: Container(
                    width: _kOfferCardWidth,
                    height: _kOfferCardHeight,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    // Mirrors the real card: circle on the right (RTL start),
                    // title/subtitle/button on the left.
                    child: Row(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: bone,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 14,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: bone,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 11,
                                width: 90,
                                decoration: BoxDecoration(
                                  color: bone,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 26,
                                width: 110,
                                decoration: BoxDecoration(
                                  color: bone,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class Offers extends StatelessWidget {
  final Datum offer;
  final GestureTapCallback? onTap;

  const Offers({super.key, required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final int discount = (offer.discountMax ?? 0).round();

    // componant.png already contains the rounded white card + the green circle
    // on the right; we only overlay the text. Circle geometry was measured from
    // the asset as fractions of the card width.
    const double circleCenterFrac = 0.782;
    const double circleDiamFrac = 0.389;
    const double discLeft =
        (circleCenterFrac - circleDiamFrac / 2) * _kOfferCardWidth;
    const double discWidth = circleDiamFrac * _kOfferCardWidth;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _kOfferCardWidth,
        height: _kOfferCardHeight,
        // Flush the first card's leading (right in RTL) edge with the section
        // header; keep the inter-card gap on the trailing side only.
        margin: const EdgeInsetsDirectional.fromSTEB(
          0,
          _kOfferCardVerticalMargin,
          12,
          _kOfferCardVerticalMargin,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: <Widget>[
            // Background card art.
            Positioned.fill(
              child: Image.asset(
                'assets/image/componant.png',
                fit: BoxFit.fill,
              ),
            ),

            // Discount text overlaid on the green circle (right side).
            Positioned(
              top: 0,
              bottom: 0,
              left: discLeft,
              width: discWidth,
              child: Center(
                child: _OfferDiscountText(discount: discount),
              ),
            ),

            // "خصم حصري" badge pinned to the top-right (over the green area).
            const Positioned(
              top: 8,
              right: 10,
              child: _ExclusiveBadge(),
            ),

            // White-area content (left side): badge, title, count, button.
            Positioned(
              top: 6,
              bottom: 6,
              left: 10,
              right: _kOfferCardWidth - discLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    offer.name ?? 'خصومات حصرية',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tajawalBold.copyWith(
                      fontWeight:
                          FontWeight.w800, // Figma: ExtraBold (→ Bold 700)
                      fontSize: 15,
                      height: 1.2,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اكثر من ${offer.itemsCount ?? 0} منتج ضمن العروض',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tajawalMedium.copyWith(
                      fontSize: 12,
                      height: 1.216,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 160,
                    height: 38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            'استكشف العروض',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tajawalBold.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.chevron_right,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "خصم حصري" pill shown at the top of an offer card.
class _ExclusiveBadge extends StatelessWidget {
  const _ExclusiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        // Figma: hsba(240, 23%, 42%) → #52526B.
        color: Color(0xFF52526B),
        // Figma: rounded top-right + bottom-left only (diagonal).
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.local_offer, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'خصم حصري',
            style: tajawalBold.copyWith(
              color: Colors.white,
              fontSize: 7.11,
              height: 10.66 / 7.11,
              letterSpacing: 0.32,
            ),
          ),
        ],
      ),
    );
  }
}

/// "خصم حتى N% / لفترة محدودة" text overlaid on the green circle of the card
/// background art (the circle itself lives in componant.png).
class _OfferDiscountText extends StatelessWidget {
  final int discount;
  const _OfferDiscountText({required this.discount});

  @override
  Widget build(BuildContext context) {
    // NOTE: Figma specified the Cairo family for these texts, but the project
    // bundles only Tajawal (per user direction "خليه tajwal"). Weights above the
    // bundled max (Tajawal tops out at Bold 700) fall back to the nearest weight.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'خصم حتى',
          textAlign: TextAlign.right,
          style: tajawalMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600, // Figma: SemiBold
            fontSize: 13,
            height: 1.0,
            letterSpacing: 0.32,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$discount%',
          textAlign: TextAlign.center,
          style: tajawalBold.copyWith(
            color: Colors.white,
            fontWeight:
                FontWeight.w900, // Figma: Black (falls back to Bold 700)
            fontSize: 44,
            height: 1.0,
            letterSpacing: -1.58,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'لفترة محدودة',
          textAlign: TextAlign.right,
          style: tajawalMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600, // Figma: SemiBold
            fontSize: 13,
            height: 1.0,
            letterSpacing: 0.32,
          ),
        ),
      ],
    );
  }
}

/// Empty state placeholder for offers section
/// Shows a friendly message when no offers are available
class EmptyOffersPlaceholder extends StatelessWidget {
  final String title;
  final String? subtitle;

  const EmptyOffersPlaceholder({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: Dimensions.fontSizeLarge),
        const _OffersSectionHeader(),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeLarge,
            horizontal: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                title,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  subtitle!,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
