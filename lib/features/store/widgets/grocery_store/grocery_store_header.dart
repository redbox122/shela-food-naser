/// Grocery Store Header Widget
///
/// Displays the store banner image with overlay icons (favorite, share, search, arrow)
/// matching the exact grocery store design specifications with absolute positioning.
///
/// File: grocery_store_header.dart
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/screens/food_restaurant_search_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class GroceryStoreHeader extends StatelessWidget {
  final String coverPhotoUrl;
  final int? storeId;
  final String? heroBannerTag;

  const GroceryStoreHeader({
    super.key,
    required this.coverPhotoUrl,
    required this.storeId,
    this.heroBannerTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    const headerHeight = 162.0;
    const imageHeight = 146.0;
    const padding = 22.0;
    final contentWidth = screenWidth - (padding * 2);

    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final bool isLtr = localizationController.isLtr;

        return Container(
          width: screenWidth,
          height: headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background image container
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: screenWidth,
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: screenWidth - 16,
                    height: imageHeight,
                    decoration: ShapeDecoration(
                      image: coverPhotoUrl.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(coverPhotoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Hero(
                      tag:
                          heroBannerTag ?? 'store_image_header_${storeId ?? 0}',
                      child: coverPhotoUrl.isNotEmpty
                          ? CustomImage(
                              image: coverPhotoUrl,
                              height: imageHeight,
                              width: screenWidth - 16,
                            )
                          : Container(
                              color: tokens.surfaceSoft,
                            ),
                    ),
                  ),
                ),
              ),
              // Dark overlay
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: screenWidth - 16,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.scrim.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Content overlay - positioned at padding offset
              Positioned(
                left: 0,
                top: 8,
                child: SizedBox(
                  width: contentWidth,
                  height: 61.33,
                  child: Stack(
                    children: [
                      // Top row: Time (left) and Status icons (right)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: SizedBox(
                          width: contentWidth,
                          height: 24,
                          child: Row(
                            textDirection:
                                isLtr ? TextDirection.ltr : TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Time display (left side)
                              SizedBox(
                                width: 52,
                                height: 24,
                                child: Text(
                                  '07 : 00',
                                  textAlign: TextAlign.center,
                                  style: robotoBold.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 14,
                                    height: 1.50,
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ),
                              // Status icons (right side) - signal, wifi, battery
                              SizedBox(
                                width: 74,
                                height: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Signal bars
                                    _buildSignalBars(context),
                                    const SizedBox(width: 8),
                                    // WiFi icon
                                    Icon(
                                      Icons.wifi,
                                      color: theme.colorScheme.onPrimary,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 8),
                                    // Battery icon
                                    _buildBatteryIcon(context),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom row: Action buttons (left) and Arrow (right)
                      Positioned(
                        left: 0,
                        top: 32,
                        child: SizedBox(
                          width: contentWidth,
                          height: 29,
                          child: Row(
                            textDirection:
                                isLtr ? TextDirection.ltr : TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left side: Favorite, Share, Search buttons
                              Row(
                                textDirection: isLtr
                                    ? TextDirection.ltr
                                    : TextDirection.rtl,
                                children: [
                                  GetBuilder<FavouriteController>(
                                    builder: (favouriteController) {
                                      final bool isWished = storeId != null &&
                                          favouriteController.wishStoreIdList
                                              .contains(storeId);
                                      return _buildActionButton(
                                        context: context,
                                        icon: isWished
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        onTap: () {
                                          if (!AuthHelper.isLoggedIn()) {
                                            showCustomSnackBar(
                                                'you_are_not_logged_in'.tr);
                                            return;
                                          }
                                          if (storeId == null) return;
                                          if (isWished) {
                                            favouriteController
                                                .removeFromFavouriteList(
                                                    storeId, true);
                                          } else {
                                            favouriteController
                                                .addToFavouriteList(
                                                    null, storeId, true);
                                          }
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  _buildActionButton(
                                    context: context,
                                    icon: Icons.share,
                                    onTap: () {
                                      final storeController =
                                          Get.find<StoreController>();
                                      storeController.shareStore();
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  _buildActionButton(
                                    context: context,
                                    icon: Icons.search,
                                    onTap: () {
                                      if (storeId != null) {
                                        Get.to(() => FoodRestaurantSearchScreen(
                                            storeId: storeId!));
                                      }
                                    },
                                  ),
                                ],
                              ),
                              // Right side: Arrow button
                              _buildActionButton(
                                context: context,
                                icon: isLtr
                                    ? Icons.arrow_forward_ios
                                    : Icons.arrow_back_ios,
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 29,
        decoration: ShapeDecoration(
          color: Theme.of(context).extension<AppColorTokens>()!.surfaceSoft,
          shape: OvalBorder(),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildSignalBars(BuildContext context) {
    return SizedBox(
      width: 17.5,
      height: 12,
      child: CustomPaint(
        painter: SignalBarsPainter(
            fillColor: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildBatteryIcon(BuildContext context) {
    return SizedBox(
      width: 24.5,
      height: 12,
      child: CustomPaint(
        painter: BatteryIconPainter(
          fillColor: Theme.of(context).colorScheme.onPrimary,
          outlineColor: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

// Custom painter for signal bars
class SignalBarsPainter extends CustomPainter {
  final Color fillColor;
  SignalBarsPainter({required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Draw 4 signal bars with exact positioning from design
    const barWidth = 3.07;

    // Bar 1 (shortest) - at y: 7.51, height: 4.49
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 7.51, barWidth, 4.49),
        const Radius.circular(1.2),
      ),
      paint,
    );

    // Bar 2 - at x: 4.91, y: 5.27, height: 6.73
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.91, 5.27, barWidth, 6.73),
        const Radius.circular(1.2),
      ),
      paint,
    );

    // Bar 3 - at x: 9.62, y: 2.69, height: 9.31
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9.62, 2.69, barWidth, 9.31),
        const Radius.circular(1.2),
      ),
      paint,
    );

    // Bar 4 (tallest) - at x: 14.43, y: 0, height: 12
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14.43, 0, barWidth, 12),
        const Radius.circular(1.2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for battery icon
class BatteryIconPainter extends CustomPainter {
  final Color fillColor;
  final Color outlineColor;
  BatteryIconPainter({required this.fillColor, required this.outlineColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Battery outline (grey)
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.fill;

    // Battery fill (white)
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Main battery body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 22, 12),
        const Radius.circular(0),
      ),
      outlinePaint,
    );

    // Battery fill (inner white rectangle)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1.5, 2, 18, 8),
        const Radius.circular(1.6),
      ),
      fillPaint,
    );

    // Battery tip (right side)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 4, 1.5, 4),
        const Radius.circular(0),
      ),
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
