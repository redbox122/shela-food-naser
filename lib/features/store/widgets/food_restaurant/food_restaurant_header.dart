import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/screens/food_restaurant_search_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

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
    final theme = Theme.of(context);
    return Container(
      height: 167,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.scrim.withValues(alpha: 0.2),
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
                  color: theme.colorScheme.scrim.withValues(alpha: 0.3),
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
              color: theme.colorScheme.scrim.withValues(alpha: 0.2),
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
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.18),
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
                        color: theme.colorScheme.surface.withValues(alpha: 0.3),
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
                                    favouriteController.addToFavouriteList(
                                        null, storeId, true);
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),
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
                          const SizedBox(width: Dimensions.paddingSizeDefault),
                          _buildCartActionButton(context),
                        ],
                      ),
                      // Right side: Back button (arrow direction based on language)
                      _buildActionButton(
                        context: context,
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

  Widget _buildCartActionButton(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return GestureDetector(
      onTap: () => Get.toNamed<void>(RouteHelper.getCartRoute()),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 28,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 20,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          GetBuilder<CartController>(
            id: 'cart_count',
            builder: (CartController cartController) {
              final int cartQuantity = cartController.totalCartQuantity;
              if (cartQuantity <= 0) {
                return const SizedBox.shrink();
              }
              final String countLabel =
                  cartQuantity > 99 ? '99+' : cartQuantity.toString();
              return PositionedDirectional(
                top: -4,
                end: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  child: Text(
                    countLabel,
                    style: robotoRegular.copyWith(
                      fontSize: countLabel.length > 2 ? 8 : 10,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 29,
        decoration: BoxDecoration(
          color: tokens.surfaceSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}
