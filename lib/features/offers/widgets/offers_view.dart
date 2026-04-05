// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../common/widgets/custom_image.dart';
import '../../../helper/route_helper.dart';
import '../../../util/app_colors.dart';
import '../../../util/styles.dart';

const double _kOfferImageExtent = 118.0;
const double _kOfferCardVerticalMargin = 4.0;
const double _kOfferListHeight =
    _kOfferImageExtent + _kOfferCardVerticalMargin * 2;

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
    return GetBuilder<Offers_Controller>(
      builder: (Offers_Controller controller) {
        final List<Datum> rawOffers = controller.offersMode?.data ?? <Datum>[];
        final List<Datum> offers = rawOffers
            .where((Datum o) => !_isInvestInQidhaOfferCard(o))
            .toList();

        if (controller.isLoading == true && rawOffers.isEmpty) {
          return const _OffersLoadingSkeleton();
        }

        if (offers.isEmpty) {
          return const EmptyOffersPlaceholder(
            title: 'لا توجد عروض حالياً',
            subtitle: 'تابعنا للحصول على أحدث العروض',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: Dimensions.fontSizeLarge),
            const _OffersSectionHeader(),
            SizedBox(
              height: _kOfferListHeight,
              child: AnimationLimiter(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
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
                                  offerDiscount: offers[index]
                                      .discountMax
                                      ?.toDouble(),
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
    final Color primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  primaryColor,
                  primaryColor.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'offers_and_discounts'.tr,
              style: robotoBold.copyWith(
                fontSize: ResponsiveHelper.isDesktop(context)
                    ? Dimensions.fontSizeExtraLarge
                    : Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.2,
              ),
            ),
          ),
          Icon(
            Icons.local_offer_rounded,
            size: 26,
            color: primaryColor.withValues(alpha: 0.88),
          ),
        ],
      ),
    );
  }
}

class _OffersLoadingSkeleton extends StatelessWidget {
  const _OffersLoadingSkeleton();

  double _cardWidth(BuildContext context) {
    final double screenW = MediaQuery.sizeOf(context).width;
    if (ResponsiveHelper.isDesktop(context)) {
      return 300;
    }
    return (screenW * 0.82).clamp(230.0, 300.0);
  }

  @override
  Widget build(BuildContext context) {
    final double cardW = _cardWidth(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: Dimensions.fontSizeLarge),
        const _OffersSectionHeader(),
        SizedBox(
          height: _kOfferListHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
            ),
            itemCount: 4,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: _kOfferCardVerticalMargin,
                ),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: cardW,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context)
                          .disabledColor
                          .withValues(alpha: 0.12),
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              );
            },
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

  double _cardWidth(BuildContext context) {
    final double screenW = MediaQuery.sizeOf(context).width;
    if (ResponsiveHelper.isDesktop(context)) {
      return 300;
    }
    return (screenW * 0.82).clamp(230.0, 300.0);
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = _cardWidth(context);
    final Color primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: _kOfferCardVerticalMargin,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          height: _kOfferImageExtent,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: _kOfferImageExtent,
                height: _kOfferImageExtent,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: const BorderRadiusDirectional.only(
                        topStart: Radius.circular(20),
                        bottomStart: Radius.circular(20),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          CustomImage(
                            image: offer.banner ?? '',
                            width: _kOfferImageExtent,
                            height: _kOfferImageExtent,
                            placeholder: Images.placeholder,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.orangeColor,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.orangeColor.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Custom_Text(
                          context,
                          text: '${offer.discountMax ?? 0}%',
                          style: font10White400W(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    12,
                    10,
                    12,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Custom_Text(
                        context,
                        text: offer.name ?? '',
                        textOverFlow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: font10Black600W(context),
                      ),
                      const SizedBox(height: 8),
                      Custom_Text(
                        context,
                        text: 'عدد المنتجات: ${offer.itemsCount ?? 0}',
                        style: font11Grey700W(context),
                      ),
                    ],
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
              color: Theme.of(context)
                  .primaryColor
                  .withValues(alpha: 0.1),
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
              Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: Theme.of(context).disabledColor,
              ),
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
