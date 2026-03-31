/// Grocery Store Info Section Widget
///
/// Displays store information card with name, delivery hours, delivery cost, and distance
/// matching the exact grocery store design specifications with logo above card.
/// Uses absolute positioning to match the exact design layout.
///
/// File: grocery_store_info_section.dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryStoreInfoSection extends StatefulWidget {
  final Store store;

  const GroceryStoreInfoSection({
    super.key,
    required this.store,
  });

  @override
  State<GroceryStoreInfoSection> createState() =>
      _GroceryStoreInfoSectionState();
}

class _GroceryStoreInfoSectionState extends State<GroceryStoreInfoSection> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final theme = Theme.of(context);
        final tokens = theme.extension<AppColorTokens>()!;
        final bool isLtr = localizationController.isLtr;
        final cardWidth = MediaQuery.of(context).size.width -
            (Dimensions.paddingSizeDefault * 2);
        const cardHeight = 116.0;
        const totalHeight = 131.0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          child: SizedBox(
            width: cardWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main card
                Positioned(
                  left: 0,
                  top: 15,
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: tokens.outlineSoft,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Store name (right side - RTL: left, LTR: right)
                        Positioned(
                          left: isLtr ? null : cardWidth * 0.735, // 225/306
                          right: isLtr ? cardWidth * 0.265 : null, // 81/306
                          top: 24,
                          child: Text(
                            store.name ?? '',
                            textAlign: TextAlign.center,
                            style: robotoMedium.copyWith(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 14,
                              height: 1.50,
                            ),
                          ),
                        ),
                        // Delivery hours (left side - RTL: right, LTR: left)
                        Positioned(
                          left: isLtr ? 8 : null,
                          right: isLtr ? null : cardWidth - 99, // 8 + 91
                          top: 49,
                          child: Text(
                            _formatDeliveryHours(store),
                            textAlign: TextAlign.center,
                            style: robotoRegular.copyWith(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 10,
                              height: 1.50,
                            ),
                          ),
                        ),
                        // Store type "سوبر ماركت" (below store name - right side)
                        Positioned(
                          left: isLtr ? null : cardWidth * 0.797, // 244/306
                          right: isLtr ? cardWidth * 0.203 : null, // 62/306
                          top: 49,
                          child: Text(
                            'سوبر ماركت',
                            textAlign: TextAlign.center,
                            style: robotoRegular.copyWith(
                              color: tokens.warningText,
                              fontSize: 10,
                              height: 1.50,
                            ),
                          ),
                        ),
                        // 🔧 FIX: Hide distance and delivery fee labels/values if distance is invalid (out of zone)
                        // ⚡ FIX: -1 means parsing failed (don't show), >0 means valid, exclude -1 sentinel
                        if (store.distance != null &&
                            store.distance! > 0 &&
                            store.distance! != -1 &&
                            store.distance! < 100000) ...[
                          // "قيمة التوصيل" label (right side)
                          Positioned(
                            left: isLtr ? null : cardWidth * 0.572, // 175/306
                            right: isLtr ? cardWidth * 0.428 : null, // 131/306
                            top: 76,
                            child: Text(
                              'قيمة التوصيل',
                              textAlign: TextAlign.center,
                              style: robotoRegular.copyWith(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 10,
                                height: 1.50,
                              ),
                            ),
                          ),
                          // "المسافة" label (left side)
                          Positioned(
                            left: isLtr ? cardWidth * 0.235 : null, // 72/306
                            right: isLtr ? null : cardWidth * 0.765, // 234/306
                            top: 76,
                            child: Text(
                              'المسافة',
                              textAlign: TextAlign.center,
                              style: robotoRegular.copyWith(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 10,
                                height: 1.50,
                              ),
                            ),
                          ),
                          // Divider line
                          Positioned(
                            left: 0,
                            top: 72,
                            child: Container(
                              width: cardWidth,
                              height: 1,
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    strokeAlign: BorderSide.strokeAlignCenter,
                                    color: tokens.outlineSoft,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Delivery fee price (right side, below delivery value)
                          // ⚡ TASK 1: Count-up animation for delivery fee
                          Positioned(
                            left: isLtr ? null : cardWidth * 0.618, // 189/306
                            right: isLtr ? cardWidth * 0.382 : null, // 117/306
                            top: 95,
                            child: _buildDeliveryFeeAnimation(store),
                          ),
                          // "15 كم" distance (left side, below distance label)
                          // ⚡ TASK 1: Count-up animation for distance
                          Positioned(
                            left: isLtr ? cardWidth * 0.255 : null, // 78/306
                            right: isLtr ? null : cardWidth * 0.745, // 228/306
                            top: 95,
                            child: _buildDistanceAnimation(store),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Logo positioned above card, centered
                Positioned(
                  left: (cardWidth / 2) - 15, // Center the 30px logo
                  top: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CustomImage(
                      image: store.logoFullUrl ?? '',
                      width: 30,
                      height: 30,
                      placeholder: Images.placeholder,
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

  String _formatDeliveryHours(Store store) {
    if (store.schedules != null && store.schedules!.isNotEmpty) {
      final schedule = store.schedules!.first;
      final openingTime = schedule.openingTime ?? '';
      final closingTime = schedule.closingTime ?? '';

      if (openingTime.isNotEmpty && closingTime.isNotEmpty) {
        return '$openingTime - $closingTime';
      } else if (openingTime.isNotEmpty) {
        return openingTime;
      } else if (closingTime.isNotEmpty) {
        return closingTime;
      }
    }

    if (store.storeOpeningTime != null && store.storeOpeningTime!.isNotEmpty) {
      return store.storeOpeningTime!;
    }

    return '10:00 PM - 1:00 AM'; // Default value
  }

  /// ⚡ TASK 1: Count-up animation for distance (0.0 -> actual value over 400ms)
  Widget _buildDistanceAnimation(Store store) {
    if (store.distance == null ||
        store.distance! <= 0 ||
        store.distance! >= 100000) {
      return const SizedBox.shrink();
    }

    final targetDistance = store.distance! / 1000;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetDistance),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutExpo,
      builder: (context, animatedValue, child) {
        return Text(
          '${animatedValue.toStringAsFixed(1)} كم',
          textAlign: TextAlign.center,
          style: robotoRegular.copyWith(
            color: Theme.of(context).disabledColor,
            fontSize: 10,
            height: 1.50,
          ),
        );
      },
    );
  }

  /// ⚡ TASK 1: Count-up animation for delivery fee
  Widget _buildDeliveryFeeAnimation(Store store) {
    if (store.freeDelivery == true) {
      return Text(
        'free'.tr,
        textAlign: TextAlign.center,
        style: robotoRegular.copyWith(
          color: Theme.of(context).extension<AppColorTokens>()!.warningText,
          fontSize: 10,
          height: 1.50,
        ),
      );
    }

    if (store.minimumShippingCharge == null ||
        store.minimumShippingCharge! <= 0) {
      return Text(
        'N/A',
        textAlign: TextAlign.center,
        style: robotoRegular.copyWith(
          color: Theme.of(context).extension<AppColorTokens>()!.warningText,
          fontSize: 10,
          height: 1.50,
        ),
      );
    }

    final targetFee = store.minimumShippingCharge!.toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetFee),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutExpo,
      builder: (context, animatedValue, child) {
        return Text(
          PriceConverter.convertPrice(animatedValue),
          textAlign: TextAlign.center,
          style: robotoRegular.copyWith(
            color: Theme.of(context).extension<AppColorTokens>()!.warningText,
            fontSize: 10,
            height: 1.50,
          ),
        );
      },
    );
  }
}
