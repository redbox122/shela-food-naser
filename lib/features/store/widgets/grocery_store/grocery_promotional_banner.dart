/// Grocery Promotional Banner Widget (Green Section)
///
/// Displays the main promotional banner with Arabic and English text,
/// sale tags, and product illustrations matching the grocery store design.
///
/// File: grocery_promotional_banner.dart
library;

import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryPromotionalBanner extends StatelessWidget {
  final List<StoreBannerModel> storeBanners;

  const GroceryPromotionalBanner({
    super.key,
    required this.storeBanners,
  });

  @override
  Widget build(BuildContext context) {
    // Use first banner if available, otherwise show default design
    final hasBanner = storeBanners.isNotEmpty;
    final banner = hasBanner ? storeBanners.first : null;

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Stack(
        children: [
          // Background image if available
          if (banner?.imageFullUrl != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: SmartImage(
                  url: banner!.imageFullUrl!,
                  cacheWidth: 800,
                  cacheHeight: 800,
                  fit: BoxFit.cover,
                  errorWidget: const SizedBox(),
                ),
              ),
            ),
          // Content overlay
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(
              children: [
                // Left side: Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Arabic text
                      Text(
                        banner?.title ??
                            'تعرف على آخر عروض متجر سوبر ماركت اون لاين',
                        style: robotoBold.copyWith(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // English text
                      Text(
                        'Learn about the latest offers Supermarket online',
                        style: robotoRegular.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Pagination dots
                      Row(
                        children: [
                          _buildDot(context, true),
                          const SizedBox(width: 6),
                          _buildDot(context, false),
                          const SizedBox(width: 6),
                          _buildDot(context, false),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right side: Sale tags and illustrations (placeholder)
                const SizedBox(width: 16),
                // Sale tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                child: Text(
                  'Sale',
                  style: robotoBold.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
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

  Widget _buildDot(BuildContext context, bool isActive) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).extension<AppColorTokens>()!.outlineSoft,
        shape: BoxShape.circle,
      ),
    );
  }
}


