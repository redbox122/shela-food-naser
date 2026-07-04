import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class PriceConverter {
  //

  static String convertPrice(double? price,
      {double? discount,
      String? discountType,
      bool forDM = false,
      bool isFoodVariation = false,
      String? formatedStringPrice,
      bool forTaxi = false}) {
    if (discount != null && discountType != null) {
      if (discountType == 'amount' && !isFoodVariation) {
        price = price! - discount;
      } else if (discountType == 'percent') {
        price = price! - ((discount / 100) * price);
      }
    }
    final bool isRightSide =
        Get.find<SplashController>().configModel!.currencySymbolDirection ==
            'right';
    // الرمز الرسمي للريال السعودي:
    // String currencySymbol = Get.find<SplashController>().configModel!.currencySymbol ?? "ر.س";

    if (forTaxi && price! > 100000) {
      return '${isRightSide ? '' : ' '}'
          '${intl.NumberFormat.compact().format(price)}'
          '${isRightSide ? '  ' : ''}';
    }

    return isRightSide
        ? '${price!.toStringAsFixed(2)} '
        : '  ${price!.toStringAsFixed(2)}';
  }

  static Widget convertPrice2(
    double? price, {
    double? discount,
    String? discountType,
    TextStyle? textStyle,
    String? prefixText,
    Color? symbolColor,
  }) {
    if (price == null) {
      return const SizedBox();
    }

    double discountedPrice = price;

    bool hasDiscount = false;

    // حساب السعر بعد الخصم إذا وجد
    if (discount != null && discountType != null) {
      if (discountType == 'amount') {
        discountedPrice = price - discount;
      } else if (discountType == 'percent') {
        discountedPrice = price - (discount / 100) * price;
      }

      hasDiscount = discountedPrice < price;
    }

    final String formattedPrice = discountedPrice.toStringAsFixed(2);
    final String originalPrice = price.toStringAsFixed(2);

    // Check if we're in Arabic locale with English numbers
    // bool isArabic = Get.find<LocalizationController>().isLtr == false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // For Arabic with English numbers, put prefixText at the beginning
        if (prefixText != null) Text(prefixText, style: textStyle),

        /// السعر الأصلي مع خط (إذا فيه خصم)
        if (hasDiscount) ...[
          Text(
            originalPrice,
            style: textStyle?.copyWith(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 5),
          Image.asset(
            Images.sar,
            width: 15,
            height: 15,
            color: symbolColor,
            cacheWidth: 48,
            cacheHeight: 48,
          ),
          const SizedBox(width: 5),
        ],

        /// السعر بعد الخصم (واضح)
        Text(formattedPrice, style: textStyle),

        const SizedBox(width: 5),
        Image.asset(
          Images.sar,
          width: 15,
          height: 15,
          color: symbolColor,
          cacheWidth: 48,
          cacheHeight: 48,
        ),
      ],
    );
  }

  static Widget convertAnimationPrice(double? price,
      {double? discount,
      String? discountType,
      bool forDM = false,
      TextStyle? textStyle}) {
    if (discount != null && discountType != null) {
      if (discountType == 'amount') {
        price = price! - discount;
      } else if (discountType == 'percent') {
        price = price! - ((discount / 100) * price);
      }
    }
    final bool isRightSide =
        Get.find<SplashController>().configModel!.currencySymbolDirection ==
            'right';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedFlipCounter(
        duration: const Duration(milliseconds: 500),
        value: toFixed(price!),
        textStyle: textStyle ?? robotoMedium,
        fractionDigits: forDM
            ? 0
            : Get.find<SplashController>().configModel!.digitAfterDecimalPoint!,
        prefix: isRightSide
            ? ''
            : '${Get.find<SplashController>().configModel!.currencySymbol!} ',
        suffix: isRightSide
            ? '${Get.find<SplashController>().configModel!.currencySymbol!} '
            : '',
      ),
    );
  }

  static double? convertWithDiscount(
      double? price, double? discount, String? discountType,
      {bool isFoodVariation = false}) {
    if (price == null || discount == null || discountType == null) return null;

    if (discountType == 'amount' && !isFoodVariation) {
      price = price - discount;
    } else if (discountType == 'percent') {
      price = price - ((discount / 100) * price);
    }

    return price;
  }

  static double calculation(
      double amount, double? discount, String type, int quantity) {
    double calculatedAmount = 0;
    if (type == 'amount' || type == 'fixed') {
      calculatedAmount = discount! * quantity;
    } else if (type == 'percent') {
      calculatedAmount = (discount! / 100) * (amount * quantity);
    }
    return calculatedAmount;
  }

  static String percentageCalculation(
      String price, String discount, String discountType) {
    return '$discount${discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol} OFF';
  }

  static double toFixed(double val, {int digits = 2}) {
    final num mod = power(10, digits);
    // Use proper rounding instead of floor() to match toStringAsFixed() behavior
    // This ensures consistency across all price displays (e.g., 5.236 → 5.24, not 5.23)
    return ((double.parse(val.toString()) * mod).round().toDouble() / mod);
  }

  static int power(int x, int n) {
    int retval = 1;
    for (int i = 0; i < n; i++) {
      retval *= x;
    }
    return retval;
  }
}
