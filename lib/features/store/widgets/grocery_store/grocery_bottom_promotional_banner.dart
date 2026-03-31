/// Grocery Bottom Promotional Banner Widget (Orange Section)
///
/// Displays the bottom promotional banner with Arabic text and discount tag
/// matching the grocery store design specifications.
///
/// File: grocery_bottom_promotional_banner.dart
library;

import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryBottomPromotionalBanner extends StatelessWidget {
  final List<StoreBannerModel> storeBanners;

  const GroceryBottomPromotionalBanner({
    super.key,
    required this.storeBanners,
  });

  @override
  Widget build(BuildContext context) {
    // Use second banner if available, otherwise show default design
    final hasBanner = storeBanners.length > 1;
    final banner = hasBanner
        ? storeBanners[1]
        : (storeBanners.isNotEmpty ? storeBanners.first : null);

    // If banner has image, show full image without overlay
    if (banner?.imageFullUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: SmartImage(
          url: banner!.imageFullUrl!,
          cacheWidth: 800,
          cacheHeight: 800,
          fit: BoxFit.fitWidth,
          errorWidget: _buildDefaultBanner(context, banner),
        ),
      );
    }

    // Fallback: show default design without image
    return _buildDefaultBanner(context, banner);
  }

  Widget _buildDefaultBanner(BuildContext context, StoreBannerModel? banner) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: tokens.warningText.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'تخفيضات',
                      style: robotoBold.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      banner?.title ??
                          'اشترى كل احتياجاتك اليومية و أنت في البيت',
                      textAlign: TextAlign.center,
                      style: robotoBold.copyWith(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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

