import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/screens/module_storefront_screen.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// Headline colour from design token hsba(162, 37%, 11%).
const Color _headlineColor = Color(0xFF121C19);

/// 🎨 REDESIGN: "خدماتنا" bento grid.
///
/// Three service tiles that route into their matching module:
///  - Market (grocery)   → tall tile on the leading side
///  - Restaurants (food) → top tile on the trailing side
///  - Pharmacy           → bottom tile on the trailing side
///
/// Presentation-only: it reads the module list and delegates navigation to
/// [SplashController.switchModule]; it never triggers data loading.
class HomeServicesGrid extends StatelessWidget {
  const HomeServicesGrid({super.key});

  static const double _gridHeight = 124;
  static const double _gap = Dimensions.paddingSizeSmall;

  // 🚧 TEMPORARY: open the per-service storefront screen (centered title for
  // now; real design to come). [moduleType] is carried for the future screen.
  void _openService(String label, String moduleType) {
    Get.to<void>(
      () => ModuleStorefrontScreen(title: label, moduleType: moduleType),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            height: _gridHeight,
            child: Row(
              children: [
                // Trailing (RTL right): Restaurants (top) + Pharmacy (bottom)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _ServiceTile(
                          label: 'the_restaurants'.tr,
                          imageAsset: Images.restaurants,
                          fill: const Color(0xFFFFF1E7),
                          labelColor: const Color(0xFFD17A2E),
                          horizontal: true,
                          onTap: () => _openService(
                              'the_restaurants'.tr, AppConstants.food),
                        ),
                      ),
                      const SizedBox(height: _gap),
                      Expanded(
                        child: _ServiceTile(
                          label: 'the_pharmacy'.tr,
                          imageAsset: Images.pharmacy,
                          fill: const Color(0xFFE5FFFA),
                          labelColor: const Color(0xFF1F8C7E),
                          horizontal: true,
                          onTap: () => _openService(
                              'the_pharmacy'.tr, AppConstants.pharmacy),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _gap),
                // Leading (RTL left): Market (tall)
                Expanded(
                  child: _ServiceTile(
                    label: 'the_market'.tr,
                    imageAsset: Images.Market,
                    fill: const Color(0xFFE7F7EA),
                    labelColor: const Color(0xFF1F7A35),
                    onTap: () =>
                        _openService('the_market'.tr, AppConstants.grocery),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String label;
  final String imageAsset;
  final Color fill;
  final Color labelColor;

  /// Small tiles (restaurants/pharmacy) use a horizontal layout: text on the
  /// leading side, icon on the trailing side. The tall Market tile uses a
  /// vertical layout: label on top, illustration at the bottom.
  final bool horizontal;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.label,
    required this.imageAsset,
    required this.fill,
    required this.labelColor,
    required this.onTap,
    this.horizontal = false,
  });

  TextStyle get _labelStyle => const TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 1.2,
      ).copyWith(color: labelColor);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusLarge);

    return Material(
      color: fill,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: horizontal ? _buildHorizontal() : _buildVertical(),
      ),
    );
  }

  // Restaurants / Pharmacy: label on the leading-left, icon at the bottom-right.
  Widget _buildHorizontal() {
    return Stack(
      children: [
        // Text on the left.
        Positioned(
          top: Dimensions.paddingSizeSmall,
          left: Dimensions.paddingSizeExtraLarge,
          child: Text(
            label,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _labelStyle,
          ),
        ),
        // Icon on the right, at the bottom.
        Positioned(
          bottom: 4,
          right: 6,
          child: Image.asset(
            imageAsset,
            height: 38,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // Market (tall): label on top-right, cart illustration at the bottom-left.
  Widget _buildVertical() {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          child: Image.asset(
            imageAsset,
            height: 75,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Positioned(
          top: Dimensions.paddingSizeDefault,
          left: Dimensions.paddingSizeExtraOverLarge,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: _labelStyle.copyWith(fontSize: 24),
          ),
        ),
      ],
    );
  }
}
