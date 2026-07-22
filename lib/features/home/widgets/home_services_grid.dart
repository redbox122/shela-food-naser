import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/features/home/screens/neighborhood_markets_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
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
  static const double _tileHeight = 64;
  static const double _gap = Dimensions.paddingSizeSmall;

  // Greens shared by the market-family tiles (market / neighborhood / delivery).
  static const Color _greenFill = Color(0xFFE7F7EA);
  static const Color _greenLabel = Color(0xFF1F7A35);

  /// Opens a module: market modules (ecommerce/grocery) go to their dedicated
  /// storefront; every other module is selected so its home lists that
  /// module's own stores.
  void _openModule(BuildContext context, ModuleModel module) {
    final String type = (module.moduleType ?? '').toLowerCase();
    // هايبر شلة — single-store market storefront (store 1). Now that the
    // catalog is populated, entry is open again (gate removed 2026-07-13).
    if (type == AppConstants.ecommerce) {
      Get.to<void>(() => MarketStoreScreen(
            storeId: 1,
            moduleId: module.id ?? 1,
            isHyperStorefront: true,
          ));
      return;
    }
    // Every other module (grocery / restaurants / cafés / pharmacy / new) opens
    // the shared module storefront (categories → banner → brands → offers →
    // stores) scoped to its own module, so its stores show — same design as
    // المحلات التجارية.
    Get.to<void>(() => NeighborhoodMarketsScreen(
          title: module.moduleName ?? '',
          moduleType: type,
          moduleId: module.id ?? 0,
        ));
  }

  /// "قريباً" sheet — kept for quick re-gating of هايبر شله if ever needed.
  // ignore: unused_element
  void _showHyperComingSoon(BuildContext context) {
    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DCE1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: _greenLabel.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_rounded,
                  color: _greenLabel, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'هايبر شله — قريباً',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Color(0xFF121C19),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'نعمل حالياً على تطوير القسم بتحديثات جوهرية لتجربة تسوّق أفضل. يعود قريباً بإذن الله 🚀',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.7,
                color: Color(0xFF8A8A8A),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _greenLabel,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Get.back<void>(),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isMarketFamily(ModuleModel m) {
    final t = (m.moduleType ?? '').toLowerCase();
    return t == AppConstants.ecommerce || t == AppConstants.grocery;
  }

  @override
  Widget build(BuildContext context) {
    // Driven entirely by the dashboard's module list, so any module added or
    // disabled in the dashboard reflects here automatically.
    return GetBuilder<SplashController>(builder: (splash) {
      final List<ModuleModel> modules = splash.moduleList ?? const [];
      if (modules.isEmpty) return const SizedBox.shrink();

      // Market-family modules on the RTL-right column; food/pharmacy/new
      // modules on the left — preserving the current layout.
      final List<ModuleModel> right = modules.where(_isMarketFamily).toList();
      final List<ModuleModel> left =
          modules.where((m) => !_isMarketFamily(m)).toList();

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
                Expanded(child: _buildColumn(context, right)),
                const SizedBox(width: _gap),
                Expanded(child: _buildColumn(context, left)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildColumn(BuildContext context, List<ModuleModel> modules) {
    return Column(
      children: [
        for (int i = 0; i < modules.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          SizedBox(
            height: _tileHeight,
            child: _moduleTile(context, modules[i]),
          ),
        ],
      ],
    );
  }

  /// Builds a tile for [module] — keeps the familiar asset/colours for the
  /// known section types and falls back to the dashboard icon for new modules.
  Widget _moduleTile(BuildContext context, ModuleModel module) {
    final String type = (module.moduleType ?? '').toLowerCase();
    final String name = module.moduleName ?? '';
    final bool isCafe = name.contains('قهو') ||
        name.contains('مقاه') ||
        name.toLowerCase().contains('cafe');

    String? asset;
    Color? imageColor;
    Color fill = _greenFill;
    Color labelColor = _greenLabel;
    switch (type) {
      case AppConstants.ecommerce:
        asset = Images.Market;
        break;
      case AppConstants.grocery:
        asset = Images.neighborhoodMarkets;
        imageColor = const Color(0xFF4F9B5D);
        break;
      case AppConstants.pharmacy:
        asset = Images.pharmacy;
        fill = const Color(0xFFE5FFFA);
        labelColor = const Color(0xFF1F8C7E);
        break;
      case AppConstants.food:
        if (isCafe) {
          asset = Images.cafes;
          fill = const Color(0xFFF6EFE7);
          labelColor = const Color(0xFF9B5E2E);
        } else {
          asset = Images.restaurants;
          fill = const Color(0xFFFFF1E7);
          labelColor = const Color(0xFFD17A2E);
        }
        break;
      default:
        asset = null; // new/unknown module → use the dashboard icon.
    }

    return _ServiceTile(
      label: name,
      imageAsset: asset,
      iconUrl: asset == null ? module.iconFullUrl : null,
      imageColor: imageColor,
      fill: fill,
      labelColor: labelColor,
      comingSoon: false, // هايبر شله مفتوح الآن (بلا شارة قريباً)
      onTap: () => _openModule(context, module),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String label;

  /// Local asset for a known section; null → use [iconUrl] (dashboard icon).
  final String? imageAsset;
  final String? iconUrl;

  /// Optional tint applied to the asset (used to recolour flat-icon assets).
  final Color? imageColor;
  final Color fill;
  final Color labelColor;
  final VoidCallback onTap;

  /// When true the tile shows a "قريباً" badge (section temporarily gated).
  final bool comingSoon;

  const _ServiceTile({
    required this.label,
    required this.fill,
    required this.labelColor,
    required this.onTap,
    this.imageAsset,
    this.iconUrl,
    this.imageColor,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    final Widget tile = Material(
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
              SizedBox(
                width: 50,
                height: 50,
                child: (imageAsset != null)
                    ? Image.asset(
                        imageAsset!,
                        fit: BoxFit.contain,
                        color: imageColor,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : (iconUrl != null && iconUrl!.isNotEmpty)
                        ? CustomImage(
                            image: iconUrl!,
                            fit: BoxFit.contain,
                            height: 50,
                            width: 50,
                          )
                        : const SizedBox.shrink(),
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

    if (!comingSoon) return tile;
    // Gated section: dim the tile and pin a "قريباً" badge on the corner.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(opacity: 0.72, child: tile),
        PositionedDirectional(
          top: 6,
          start: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1F7A35),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'قريباً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w800,
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
