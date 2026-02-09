import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/screens/food_restaurant_search_screen.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';

class FoodRestaurantHeader extends StatelessWidget {
  final String coverPhotoUrl;
  final String logoUrl;
  final int? storeId;
  final String? heroBannerTag;
  final String? heroLogoTag;

  const FoodRestaurantHeader({
    super.key,
    required this.coverPhotoUrl,
    required this.logoUrl,
    required this.storeId,
    this.heroBannerTag,
    this.heroLogoTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 167,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Hero(
              tag: heroBannerTag ?? 'store_image_header_${storeId ?? 0}',
              placeholderBuilder: (context, heroSize, child) {
                return Container(
                  width: heroSize.width,
                  height: heroSize.height,
                  color: Colors.black.withValues(alpha: 0.3),
                  child: child,
                );
              },
              child: CustomImage(
                image: coverPhotoUrl,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          // Logo positioned at bottom center, overlaying the banner
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Hero(
                    tag: heroLogoTag ?? 'store_logo_${storeId ?? 0}',
                    placeholderBuilder: (context, heroSize, child) {
                      return Container(
                        width: heroSize.width,
                        height: heroSize.height,
                        color: AppColors.backgroundColor.withValues(alpha: 0.3),
                        child: child,
                      );
                    },
                    child: CustomImage(
                      image: logoUrl,
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: GetBuilder<LocalizationController>(
              builder: (localizationController) {
                final bool isLtr = localizationController.isLtr;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeDefault,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: Favorite, Search, and Cart icons (always on left)
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.favorite_border,
                            onTap: () {
                              // TODO: Implement favorite functionality
                            },
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),
                          _buildActionButton(
                            icon: Icons.search,
                            onTap: () {
                              if (storeId != null) {
                                Get.to(() => FoodRestaurantSearchScreen(
                                    storeId: storeId!));
                              }
                            },
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),
                          _buildActionButton(
                            icon: Icons.shopping_cart_outlined,
                            onTap: () {
                              Get.toNamed(RouteHelper.getCartRoute());
                            },
                          ),
                        ],
                      ),
                      // Right side: Back button (arrow direction based on language)
                      _buildActionButton(
                        icon: isLtr
                            ? Icons.arrow_back_ios
                            : Icons.arrow_forward_ios,
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 29,
        decoration: const BoxDecoration(
          color: AppColors.wtColor_2,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.textColor,
        ),
      ),
    );
  }
}
