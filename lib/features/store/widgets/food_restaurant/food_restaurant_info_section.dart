/// Food Restaurant Info Section - Premium Apple-Luxury Design
///
/// Elegant restaurant information display with minimalist styling
///
/// File: food_restaurant_info_section.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodRestaurantInfoSection extends StatelessWidget {
  final Store store;

  const FoodRestaurantInfoSection({
    super.key,
    required this.store,
  });

  /// Calculate delivery fee based on distance
  /// Returns 5 riyals for distances <= 3km, otherwise 1.45 riyal per km
  double _calculateDeliveryFee(double? distanceInMeters) {
    if (distanceInMeters == null || distanceInMeters <= 0) {
      return 0.0;
    }
    final double distanceInKm = distanceInMeters / 1000;
    if (distanceInKm <= 3) {
      return 5.0;
    } else {
      return distanceInKm * 1.45;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryFee = _calculateDeliveryFee(store.distance);

    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final bool isLtr = localizationController.isLtr;
        final theme = Theme.of(context);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeDefault,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store.name ?? '',
                textAlign: TextAlign.center,
                style: robotoBold.copyWith(
                  fontSize: 24,
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.3,
                  letterSpacing: -0.8,
                ),
              ),
              // Show delivery fee when distance data is available
              // ⚡ FIX: -1 means parsing failed (don't show), null means out of coverage (don't show), >0 means valid
              if (store.distance != null &&
                  store.distance! > 0 &&
                  store.distance! != -1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'delivery_fee'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: 14,
                        color: theme.disabledColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SvgPicture.asset(
                      Images.fastDelivery,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        theme.disabledColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // ⚡ TASK 2: Animated delivery fee with bounce effect
                    _buildAnimatedDeliveryFee(context, deliveryFee),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              // Horizontal info row with dividers (matching Figma)
              // ✅ FIX: Use SingleChildScrollView for overflow + Expanded for responsive layout
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Show distance chip when distance data is available
                    // ⚡ TASK 2: Animated metric counter for distance
                    // ⚡ FIX: -1 means parsing failed (don't show), null means out of coverage (don't show), >0 means valid
                    if (store.distance != null &&
                        store.distance! > 0 &&
                        store.distance! != -1) ...[
                      _buildInfoChip(
                        context: context,
                        label: 'distance'.tr,
                        value: '', // Empty - valueWidget will handle animation
                        valueWidget: _buildAnimatedDistance(context, store.distance!),
                        isLtr: isLtr,
                        showLocationIcon: true,
                        onLocationTap: () {
                          Get.toNamed(RouteHelper.getMapRoute(
                            AddressModel(
                              id: store.id,
                              address: store.address,
                              latitude: store.latitude,
                              longitude: store.longitude,
                              contactPersonNumber: '',
                              contactPersonName: '',
                              addressType: '',
                            ),
                            'store',
                            Get.find<SplashController>()
                                    .getModuleConfig(
                                        Get.find<SplashController>()
                                            .module!
                                            .moduleType!)
                                    .newVariation ??
                                false,
                            storeName: store.name,
                          ));
                        },
                      ),
                      _buildDivider(context),
                    ],
                    _buildInfoChip(
                      context: context,
                      label: 'min_delivery_time'.tr,
                      value: (store.deliveryTime != null &&
                              store.deliveryTime!.isNotEmpty)
                          ? store.deliveryTime!
                          : '30-15',
                      isLtr: isLtr,
                    ),
                    _buildDivider(context),
                    _buildInfoChip(
                      context: context,
                      label: 'rating'.tr,
                      value: store.avgRating != null
                          ? store.avgRating!.toStringAsFixed(1)
                          : 'N/A',
                      isLtr: isLtr,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({
    required BuildContext context,
    required String label,
    required String value,
    required bool isLtr,
    Widget? valueWidget, // Optional widget for complex values like currency
    bool showLocationIcon = false, // Show location icon next to value
    VoidCallback? onLocationTap, // Callback when location icon is tapped
  }) {
    const TextAlign textAlign = TextAlign.center;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6), // ✅ Reduced from 8
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Value row with optional location icon
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use valueWidget if provided, otherwise use value text
              // ✅ Added constraints and overflow handling
              ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 60), // ✅ Prevent overflow
                child: valueWidget ??
                    Text(
                      value,
                      textAlign: textAlign,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(
                        fontSize: 15, // ✅ Reduced from 17
                        color: theme.textTheme.bodyLarge?.color,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
              ),
              // Location icon (only shown for distance)
              if (showLocationIcon && onLocationTap != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onLocationTap,
                  child: Icon(
                    Icons.location_on,
                    size: 16, // ✅ Reduced from 18
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3), // ✅ Reduced from 4
          // ✅ Added constraints for label text
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 70),
            child: Text(
              label,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(
                fontSize: 12, // ✅ Reduced from 14
                color: theme.disabledColor,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Container(
      width: 0.8, // ✅ Reduced from 1
      height: 25, // ✅ Reduced from 30
      margin: const EdgeInsets.symmetric(horizontal: 3), // ✅ Reduced from 4
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.outlineSoft.withValues(alpha: 0.3),
            tokens.outlineSoft,
            tokens.outlineSoft.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  /// ⚡ TASK 2: Animated distance counter (0.0 -> actual value with bounce)
  /// Animates from 0.0 to the final distance value over 600ms with easeOutBack curve
  Widget _buildAnimatedDistance(BuildContext context, double distanceInMeters) {
    final targetDistance = distanceInMeters / 1000;
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetDistance),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack, // Bounce effect
      builder: (context, animatedValue, child) {
        return Text(
          '${animatedValue.toStringAsFixed(1)} ${'km'.tr}',
          textAlign: TextAlign.center,
          style: robotoBold.copyWith(
            fontSize: 15,
            color: theme.textTheme.bodyLarge?.color,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        );
      },
    );
  }

  /// ⚡ TASK 2: Animated delivery fee counter with bounce effect
  /// Animates from 0.0 to the final delivery fee value over 600ms with easeOutBack curve
  Widget _buildAnimatedDeliveryFee(BuildContext context, double targetFee) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetFee),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack, // Bounce effect
      builder: (context, animatedValue, child) {
        return PriceConverter.convertPrice2(
          animatedValue,
          textStyle: robotoRegular.copyWith(
            fontSize: 14,
            color: Theme.of(context).disabledColor,
            height: 1.4,
          ),
        );
      },
    );
  }
}
