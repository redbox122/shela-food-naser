import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';

/// Image Cache Warmer
///
/// Preloads images into Flutter's image cache during splash screen
/// to ensure instant display when MultiModuleHomeScreen appears
class ImageCacheWarmer {
  /// Warm images from a list of URLs
  /// 
  /// Silently preloads images in the background without blocking UI
  /// Returns the number of successfully warmed images
  static Future<int> warmImages(BuildContext context, List<String?> imageUrls) async {
    if (imageUrls.isEmpty) return 0;

    int warmedCount = 0;
    final List<Future<void>> warmFutures = [];

    for (final url in imageUrls) {
      if (url == null || url.isEmpty || url == 'null') continue;

      // Create a future to warm each image
      warmFutures.add(
        precacheImage(
          NetworkImage(url),
          context,
        )
            .timeout(
          const Duration(seconds: 5),
          onTimeout: () {/* silently skip slow/unavailable images */},
        )
            .then((_) {
          warmedCount++;
          if (kDebugMode) {
            debugPrint('ImageCacheWarmer: Warmed image: $url');
          }
        }).catchError((Object error) {
          if (kDebugMode) {
            debugPrint('ImageCacheWarmer: Failed to warm image $url: $error');
          }
        }),
      );
    }

    // Wait for all images to warm (but don't block if some fail)
    await Future.wait(warmFutures);

    if (kDebugMode) {
      debugPrint('ImageCacheWarmer: Warmed $warmedCount/${imageUrls.length} images');
    }

    return warmedCount;
  }

  /// Warm images from banner and brand data
  ///
  /// Extracts image URLs from banner and brand controllers and warms them
  static Future<void> warmBannerAndBrandImages(BuildContext context) async {
    if (kDebugMode) {
      debugPrint('ImageCacheWarmer: Starting to warm banner and brand images...');
    }

    final List<String?> imageUrls = [];

    // Extract banner image URLs
    if (Get.isRegistered<BannerController>()) {
      final bannerController = Get.find<BannerController>();
      
      // Featured banners (used in multi-module screen)
      if (bannerController.featuredBannerList != null) {
        imageUrls.addAll(bannerController.featuredBannerList!);
      }
      
      // Regular banners
      if (bannerController.bannerImageList != null) {
        imageUrls.addAll(bannerController.bannerImageList!);
      }
    }

    // Extract brand image URLs
    if (Get.isRegistered<BrandsController>()) {
      final brandsController = Get.find<BrandsController>();
      
      if (brandsController.brandList != null) {
        for (final brand in brandsController.brandList!) {
          if (brand.imageFullUrl != null && brand.imageFullUrl!.isNotEmpty) {
            imageUrls.add(brand.imageFullUrl!);
          }
        }
      }
    }

    if (imageUrls.isEmpty) {
      if (kDebugMode) {
        debugPrint('ImageCacheWarmer: No images to warm');
      }
      return;
    }

    // Warm all images
    await warmImages(context, imageUrls);
  }
}

