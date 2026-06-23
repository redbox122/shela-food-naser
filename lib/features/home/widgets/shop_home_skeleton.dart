import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// 🎨 Loading skeleton that mirrors the redesigned home layout
/// (banner → "خدماتنا" services grid → "العروض الحالية" offers rail → discover
/// banner) so the skeleton → loaded transition is jump-free and on-brand.
class ShopHomeSkeleton extends StatelessWidget {
  const ShopHomeSkeleton({super.key});

  // Services grid dimensions — mirror HomeServicesGrid (tall 91 / standard 58,
  // 8px radius).
  static const double _tallTile = 91;
  static const double _tile = 58;

  @override
  Widget build(BuildContext context) {
    final Color base =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    final Color highlight =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Greeting header (avatar + two lines), matching HomeHeader.
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                children: [
                  _box(width: 44, height: 44, radius: 22),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(width: 120, height: 12, radius: 4),
                      const SizedBox(height: 8),
                      _box(width: 80, height: 12, radius: 4),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Promotional banner (613/289 ratio, 16px radius) — HomeBannerView.
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              child: AspectRatio(
                aspectRatio: 613 / 289,
                child: _box(radius: 16),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // "خدماتنا" headline + 2-column services grid (HomeServicesGrid).
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(width: 120, height: 22, radius: 6),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Right column: 2 tall tiles.
                      Expanded(
                        child: Column(
                          children: [
                            _box(height: _tallTile, radius: 8),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            _box(height: _tallTile, radius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      // Left column: 3 standard tiles.
                      Expanded(
                        child: Column(
                          children: [
                            _box(height: _tile, radius: 8),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            _box(height: _tile, radius: 8),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            _box(height: _tile, radius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // "العروض الحالية" headline + horizontal offers rail.
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              child: _box(width: 140, height: 22, radius: 6),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault),
                itemCount: 4,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                itemBuilder: (_, __) => _box(width: 110, radius: 8),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // "اكتشف خدمات أكثر" promo banner (≈96px) — HomeDiscoverBannerView.
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              child: _box(height: 96, radius: 12),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
        ),
      ),
    );
  }

  /// A solid placeholder block; the [Shimmer] ancestor paints the sweep over it.
  Widget _box({double? width, double? height, double radius = 8}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
