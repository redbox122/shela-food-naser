/// Grocery Category Banner Widget
/// 
/// Displays promotional banner for category page with carousel indicators.
/// 
/// File: grocery_category_banner.dart
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/dimensions.dart';

class GroceryCategoryBanner extends StatelessWidget {
  final List<StoreBannerModel> storeBanners;

  const GroceryCategoryBanner({
    super.key,
    required this.storeBanners,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryBanner] build() - File: grocery_category_banner.dart');
    }

    // Use first banner if available
    final hasBanner = storeBanners.isNotEmpty;
    final banner = hasBanner ? storeBanners.first : null;

    if (!hasBanner) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      height: 116,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Stack(
        children: [
          // Banner image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: CustomImage(
                image: banner!.imageFullUrl ?? '',
              ),
            ),
          ),
          // Carousel indicators (bottom center)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIndicator(true),
                const SizedBox(width: 4),
                _buildIndicator(false),
                const SizedBox(width: 4),
                _buildIndicator(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFEBF942) // Yellow
            : const Color(0xFFD9D9D9), // Gray
        shape: BoxShape.circle,
      ),
    );
  }
}

