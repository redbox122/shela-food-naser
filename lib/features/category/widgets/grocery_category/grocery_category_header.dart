/// Grocery Category Header Widget
/// 
/// Displays the green header with store name, category name, search bar,
/// and action buttons (back, favorite, cart) matching the grocery category design.
/// 
/// File: grocery_category_header.dart
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/screens/food_restaurant_search_screen.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryCategoryHeader extends StatelessWidget {
  final String storeName;
  final String categoryName;
  final int? storeId;

  const GroceryCategoryHeader({
    super.key,
    required this.storeName,
    required this.categoryName,
    this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryHeader] build() - File: grocery_category_header.dart');
    }
    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final bool isLtr = localizationController.isLtr;

        return Container(
          width: double.infinity,
          color: const Color(0xFF31A342), // Green color from design
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top row: Back arrow, Store name with cart, Favorite star
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                  child: Row(
                    textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back arrow
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            isLtr ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      // Store name with cart icon
                      Row(
                        textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            storeName.isNotEmpty ? storeName : 'ماركت جرير',
                            style: robotoRegular.copyWith(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Favorite star
                      GetBuilder<FavouriteController>(
                        builder: (favouriteController) {
                          final bool isWished = storeId != null &&
                              favouriteController.wishStoreIdList.contains(storeId);
                          return GestureDetector(
                            onTap: () {
                              if (kDebugMode) {
                                debugPrint('[GroceryCategoryHeader] Favorite tapped');
                              }
                              if (!AuthHelper.isLoggedIn()) {
                                showCustomSnackBar('you_are_not_logged_in'.tr);
                                return;
                              }
                              if (storeId == null) return;
                              if (isWished) {
                                favouriteController.removeFromFavouriteList(storeId, true);
                              } else {
                                favouriteController.addToFavouriteList(null, storeId, true);
                              }
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWished ? Icons.star : Icons.star_border,
                                color: const Color(0xFFEBF942),
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Category name with percentage icon
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                  ),
                  child: Row(
                    textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBF942), // Yellow
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '%',
                            style: robotoBold.copyWith(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoryName,
                        style: robotoMedium.copyWith(
                          fontSize: 13,
                          color: const Color(0xFFEBF942), // Yellow
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    0,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (kDebugMode) {
                        debugPrint(
                            '📍 [GroceryCategoryHeader] Search bar tapped');
                        debugPrint('   🔍 Navigating to search screen for store ID: $storeId');
                      }
                      if (storeId != null) {
                        Get.to(() => FoodRestaurantSearchScreen(storeId: storeId!));
                      }
                    },
                    child: Container(
                      height: 29,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              'ابحث عن اي منتج تريده.......',
                              textAlign: isLtr ? TextAlign.left : TextAlign.right,
                              style: robotoRegular.copyWith(
                                fontSize: 10,
                                color: AppColors.gryColor_2,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.search,
                            size: 16,
                            color: AppColors.gryColor_2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


