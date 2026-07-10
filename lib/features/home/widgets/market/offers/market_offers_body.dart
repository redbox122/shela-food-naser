import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/screens/market_product_screen.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_models.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_product_card.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

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

  /// When true, products are shown in a vertical list instead of the 3-col grid.
  final bool isListView;

  const MarketOffersBody({
    super.key,
    required this.loading,
    required this.subs,
    required this.sectionKeys,
    required this.scrollController,
    required this.accent,
    required this.storeId,
    required this.moduleId,
    this.isListView = false,
  });

  static const SliverGridDelegate _grid =
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    mainAxisSpacing: 12,
    crossAxisSpacing: 10,
    // Design card is 104×130, but the fixed 85px image + padding + a 2-line
    // name + price sum a hair over a 104/130 cell (the ~1.3px bottom overflow).
    // A touch more height clears it without visibly changing the card.
    childAspectRatio: 104 / 134,
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
      if (isListView) {
        slivers.add(SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, j) => _OfferListCard(
              product: sub.products[j],
              storeId: storeId,
              moduleId: moduleId,
            ),
            childCount: sub.products.length,
          ),
        ));
      } else {
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
                  accent: const Color(0xFF1F7A35),
                ),
                childCount: sub.products.length,
              ),
            ),
          ),
        );
      }
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

/// Horizontal list card for list-view mode: image + name/price on right, add
/// button on left (RTL layout).
class _OfferListCard extends StatelessWidget {
  final OfferProduct product;
  final int? storeId;
  final int moduleId;

  const _OfferListCard({
    required this.product,
    this.storeId,
    required this.moduleId,
  });

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: (product.id == null || product.id == 0)
              ? null
              : () => MarketProductScreen.show(
                    itemId: product.id!,
                    storeId: storeId,
                    moduleId: moduleId,
                  ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEFEFF1)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product image (right side in RTL)
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(7)),
                  child: Stack(
                    children: [
                      CustomImage(
                        image: product.image ?? '',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: Images.placeholder,
                      ),
                      if (product.discountPercent > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFDCDC),
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(6)),
                            ),
                            child: Text(
                              '-${product.discountPercent}%',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Name + price
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name ?? '',
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF121C19),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Image.asset(
                                Images.sar,
                                width: 14,
                                height: 14,
                                color: const Color(0xFF121C19),
                                errorBuilder: (_, __, ___) => Text('﷼',
                                    style: robotoBold.copyWith(
                                        fontSize: 14,
                                        color: const Color(0xFF121C19))),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _fmt(product.shownPrice),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF121C19),
                                ),
                              ),
                              if (product.hasDiscount) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _fmt(product.price),
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: Color(0xFFB3B5BB),
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Add button (left side in RTL)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: OfferAddControl(
                    product: product,
                    storeId: storeId,
                    moduleId: moduleId,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
