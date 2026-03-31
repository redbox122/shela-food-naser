/// Food Restaurant Action Buttons Widget
///
/// This file contains the action buttons toolbar for the restaurant details page.
/// It includes grid/list toggle, price sorting, and search buttons.
/// Design matches the existing store_screen.dart button style.
///
/// File: food_restaurant_action_buttons.dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodRestaurantActionButtons extends StatelessWidget {
  final int? storeId;

  const FoodRestaurantActionButtons({
    super.key,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        return GetBuilder<LocalizationController>(
          builder: (localizationController) {
            final bool isLtr = localizationController.isLtr;
            final theme = Theme.of(context);
            final tokens = theme.extension<AppColorTokens>()!;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: isLtr
                  ? [
                      // LTR: Buttons on LEFT, Title on RIGHT
                      Row(
                        children: [
                          // Grid View Button (leftmost in LTR)
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: tokens.surfaceSoft,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Grid View Button (left)
                                  _buildSegmentButton(
                                    context: context,
                                    icon: Icons.grid_view_rounded,
                                    isSelected: storeController.isVertical,
                                    onTap: () {
                                      if (!storeController.isVertical) {
                                        storeController.setVerticalItems(true);
                                      }
                                    },
                                    isLeft: true,
                                  ),
                                  // List View Button (right)
                                  _buildSegmentButton(
                                    context: context,
                                    icon: Icons.view_list_rounded,
                                    isSelected: !storeController.isVertical,
                                    onTap: () {
                                      if (storeController.isVertical) {
                                        storeController.setVerticalItems(false);
                                      }
                                    },
                                    isLeft: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Price Sort Button
                          InkWell(
                            onTap: () {
                              storeController
                                  .set_Price(!storeController.isPriceAscending);
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: tokens.surfaceSoft,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                storeController.isPriceAscending
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_up_rounded,
                                size: 20,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Title
                      Text(
                        'items'.tr,
                        style: robotoBold.copyWith(
                          fontSize: 20,
                          color: theme.textTheme.bodyLarge?.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ]
                  : [
                      // RTL: Title on RIGHT, Buttons on LEFT
                      Text(
                        'items'.tr,
                        style: robotoBold.copyWith(
                          fontSize: 20,
                          color: theme.textTheme.bodyLarge?.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          // Price Sort Button (rightmost in RTL)
                          InkWell(
                            onTap: () {
                              storeController
                                  .set_Price(!storeController.isPriceAscending);
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: tokens.surfaceSoft,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                storeController.isPriceAscending
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_up_rounded,
                                size: 20,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 3D Segmented Control for Grid/List View Toggle
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: tokens.surfaceSoft,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Grid View Button (left in control)
                                  _buildSegmentButton(
                                    context: context,
                                    icon: Icons.grid_view_rounded,
                                    isSelected: storeController.isVertical,
                                    onTap: () {
                                      if (!storeController.isVertical) {
                                        storeController.setVerticalItems(true);
                                      }
                                    },
                                    isLeft: true,
                                  ),
                                  // List View Button (right in control)
                                  _buildSegmentButton(
                                    context: context,
                                    icon: Icons.view_list_rounded,
                                    isSelected: !storeController.isVertical,
                                    onTap: () {
                                      if (storeController.isVertical) {
                                        storeController.setVerticalItems(false);
                                      }
                                    },
                                    isLeft: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: isSelected
              ? (isLeft
                  ? const BorderRadius.horizontal(
                      right: Radius.circular(10),
                    )
                  : const BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ))
              : null,
          border: isSelected
              ? Border.all(color: theme.primaryColor, width: 1.5)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? theme.primaryColor : theme.disabledColor,
        ),
      ),
    );
  }
}
