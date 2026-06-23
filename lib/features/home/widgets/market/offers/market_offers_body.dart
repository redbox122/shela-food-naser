import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_models.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_product_card.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Scrolling content of the offers screen: a skeleton grid while loading, an
/// empty state when there is nothing, otherwise the selected category's
/// sub_categories stacked as titled sections (each a 3-col product grid). The
/// white second bar scrolls the body to a section via [sectionKeys].
class MarketOffersBody extends StatelessWidget {
  final bool loading;
  final List<SubCat> subs;

  /// One key per section (same length/order as [subs]); the second-bar tabs use
  /// these to scroll the matching section into view.
  final List<GlobalKey> sectionKeys;

  final ScrollController scrollController;

  final Color accent;
  final int? storeId;
  final int moduleId;

  const MarketOffersBody({
    super.key,
    required this.loading,
    required this.subs,
    required this.sectionKeys,
    required this.scrollController,
    required this.accent,
    required this.storeId,
    required this.moduleId,
  });

  static const SliverGridDelegate _grid =
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    mainAxisSpacing: 12,
    crossAxisSpacing: 10,
    // Design card is 104×130.
    childAspectRatio: 104 / 130,
  );

  @override
  Widget build(BuildContext context) {
    if (loading) return _gridSkeleton();
    if (subs.isEmpty) return _emptyState('no_data_available'.tr);

    final slivers = <Widget>[];
    for (int i = 0; i < subs.length; i++) {
      final sub = subs[i];
      // Section title — its key lets the second bar scroll here.
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            key: i < sectionKeys.length ? sectionKeys[i] : null,
            // Tighter top/bottom so sections sit closer together.
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeExtraSmall,
            ),
            child: Text(
              sub.name,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.2,
                // Section titles follow the store logo color (the chips stay
                // fixed green).
                color: accent,
              ),
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault),
          sliver: SliverGrid(
            gridDelegate: _grid,
            delegate: SliverChildBuilderDelegate(
              (_, j) => OfferProductCard(
                product: sub.products[j],
                storeId: storeId,
                moduleId: moduleId,
                // Product card chrome stays fixed green — not logo-tinted.
                accent: const Color(0xFF1F7A35),
              ),
              childCount: sub.products.length,
            ),
          ),
        ),
      );
    }
    slivers.add(const SliverToBoxAdapter(
        child: SizedBox(height: Dimensions.paddingSizeLarge)));

    return CustomScrollView(
      controller: scrollController,
      slivers: slivers,
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Color(0xFF717885),
        ),
      ),
    );
  }

  /// Skeleton bones rendered from the real [OfferProductCard] layout with dummy
  /// data, so the loading grid matches the live product cards exactly.
  Widget _gridSkeleton() {
    final OfferProduct dummy = OfferProduct(
      id: 0,
      name: 'اسم المنتج التجريبي',
      image: '',
      price: 51.95,
      discountedPrice: 31.95,
      discountPercentage: 6,
    );
    return Skeletonizer(
      child: GridView.builder(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        itemCount: 9,
        gridDelegate: _grid,
        itemBuilder: (_, __) => OfferProductCard(
          product: dummy,
          storeId: storeId,
          moduleId: moduleId,
          accent: const Color(0xFF1F7A35),
        ),
      ),
    );
  }
}
