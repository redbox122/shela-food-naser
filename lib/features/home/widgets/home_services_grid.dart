import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/features/home/screens/module_storefront_screen.dart';
import 'package:sixam_mart/features/home/screens/neighborhood_markets_screen.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// Headline colour from design token hsba(162, 37%, 11%).
const Color _headlineColor = Color(0xFF121C19);

/// 🎨 REDESIGN: "خدماتنا" services grid — two columns × three rows of equal
/// tiles (163×58, 8px radius; widths flex to fill the row).
///
/// RTL right column : Market, Neighborhood markets, Pickup & delivery.
/// RTL left column  : Restaurants, Cafes, Pharmacy.
///
/// Presentation-only: each tile navigates into its matching storefront screen;
/// it never triggers home data loading.
class HomeServicesGrid extends StatelessWidget {
  const HomeServicesGrid({super.key});

  // Left column tiles (3 of them). Right column tiles are taller (91) so the
  // two columns end at the same height: 2×91 + gap ≈ 3×58 + 2×gap.
  static const double _tileHeight = 58;
  static const double _tallTileHeight = 91;
  static const double _gap = Dimensions.paddingSizeSmall;

  // Greens shared by the market-family tiles (market / neighborhood / delivery).
  static const Color _greenFill = Color(0xFFE7F7EA);
  static const Color _greenLabel = Color(0xFF1F7A35);

  // 🚧 TEMPORARY: open the per-service storefront screen (centered title for
  // now; real design to come). [moduleType] is carried for the future screen.
  void _openService(String label, String moduleType, {int? moduleId}) {
    Get.to<void>(
      () => ModuleStorefrontScreen(
        title: label,
        moduleType: moduleType,
        moduleId: moduleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_ServiceTile> rightColumn = [
      _ServiceTile(
        label: 'hyper_market_shella'.tr,
        imageAsset: Images.Market,
        fill: _greenFill,
        labelColor: _greenLabel,
        // Opens the هايبر شلة store (store 1) — banner header + categories +
        // سلوجان الشركة sections. The store lives in module 1; the cart add is
        // module-scoped, so it must be opened with the store's real module
        // (passing the wrong module makes the add fail with `store_closed`).
        onTap: () => Get.to<void>(
          () => const MarketStoreScreen(
            storeId: 1,
            moduleId: 1,
            isHyperStorefront: true,
          ),
        ),
      ),
      _ServiceTile(
        label: 'neighborhood_markets'.tr,
        imageAsset: Images.neighborhoodMarkets,
        imageColor: const Color(0xFF4F9B5D),
        fill: _greenFill,
        labelColor: _greenLabel,
        // Opens the neighborhood-markets storefront (same layout as the market
        // screen, scoped to its own module), not the temporary placeholder.
        onTap: () => Get.to<void>(
          () => NeighborhoodMarketsScreen(
            title: 'neighborhood_markets'.tr,
            moduleType: AppConstants.grocery,
          ),
        ),
      ),
    ];

    final List<_ServiceTile> leftColumn = [
      _ServiceTile(
        label: 'the_restaurants'.tr,
        imageAsset: Images.restaurants,
        fill: const Color(0xFFFFF1E7),
        labelColor: const Color(0xFFD17A2E),
        onTap: () =>
            _openService('the_restaurants'.tr, AppConstants.food, moduleId: 3),
      ),
      _ServiceTile(
        label: 'the_cafes'.tr,
        imageAsset: Images.cafes,
        fill: const Color(0xFFF6EFE7),
        labelColor: const Color(0xFF9B5E2E),
        onTap: () => _openService('the_cafes'.tr, AppConstants.food),
      ),
      _ServiceTile(
        label: 'the_pharmacy'.tr,
        imageAsset: Images.pharmacy,
        fill: const Color(0xFFE5FFFA),
        labelColor: const Color(0xFF1F8C7E),
        onTap: () => _openService('the_pharmacy'.tr, AppConstants.pharmacy),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'our_services'.tr,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.2,
              color: _headlineColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Right column: 2 tall tiles (91) — matches the left column's
              // 3 standard tiles (58) so both columns end at the same height.
              Expanded(child: _buildColumn(rightColumn, _tallTileHeight)),
              const SizedBox(width: _gap),
              Expanded(child: _buildColumn(leftColumn, _tileHeight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(List<_ServiceTile> tiles, double tileHeight) {
    return Column(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          SizedBox(height: tileHeight, child: tiles[i]),
        ],
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String label;
  final String imageAsset;

  /// Optional tint applied to the asset (used to recolour flat-icon assets).
  final Color? imageColor;
  final Color fill;
  final Color labelColor;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.label,
    required this.imageAsset,
    required this.fill,
    required this.labelColor,
    required this.onTap,
    this.imageColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    return Material(
      color: fill,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // Icon on the leading (RTL right) side, label filling the rest,
        // right-aligned.
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: Dimensions.paddingSizeSmall,
            end: Dimensions.paddingSizeSmall,
          ),
          child: Row(
            children: [
              Image.asset(
                imageAsset,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                color: imageColor,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.2,
                    color: labelColor,
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
