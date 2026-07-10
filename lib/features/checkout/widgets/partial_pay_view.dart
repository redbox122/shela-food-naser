// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

Widget PartialPayView(BuildContext context,
    {required totalPrice, required isPrescription}) {
  return GetBuilder<CheckoutController>(
    id: 'payment', // ✅ استخدام ID لتحديث جزئي
    builder: (checkoutController) {
      final theme = Theme.of(context);
      final tokens = theme.extension<AppColorTokens>();
      // ✅ FIX: Removed !(isPrescription) condition - wallet payment should be available for all orders
      // The isPrescription flag was incorrectly blocking wallet view for normal orders (storeId != null)
      final profileController = Get.find<ProfileController>();
      final bool hasWalletBalance = profileController.userInfoModel != null &&
          profileController.userInfoModel!.walletBalance != null &&
          profileController.userInfoModel!.walletBalance! > 0;
      // NOTE: the `customerWalletStatus` config gate was dropped here — the
      // "my wallet" option is shown/opened based on the actual balance, so
      // gating the sheet content on config left it rendering an empty SizedBox.

      return hasWalletBalance
          ? !ResponsiveHelper.isDesktop(context)
              ? _mobileWalletSheet(context, checkoutController, totalPrice)
              : AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  decoration: BoxDecoration(
                    color: tokens?.successSoft ??
                        theme.colorScheme.primary.withValues(alpha: 0.10),
                    border: Border.all(
                        color: Theme.of(context).primaryColor, width: 0.5),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            checkoutController.isPartialPay ||
                                    checkoutController.paymentMethodIndex == 1
                                ? Row(children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.check,
                                          size: 12, color: Colors.white),
                                    ),
                                    const SizedBox(
                                        width:
                                            Dimensions.paddingSizeExtraSmall),
                                    Text(
                                      'applied'.tr,
                                      style: robotoMedium.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: Dimensions.fontSizeDefault),
                                    )
                                  ])
                                : Text(
                                    'do_you_want_to_use_now'.tr,
                                    style: robotoMedium.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: Dimensions.fontSizeDefault),
                                  ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            PriceConverter.convertPrice2(
                              Get.find<ProfileController>()
                                  .userInfoModel!
                                  .walletBalance!,
                              textStyle: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            checkoutController.paymentMethodIndex == 1
                                ? PriceConverter.convertPrice2(
                                    Get.find<ProfileController>()
                                            .userInfoModel!
                                            .walletBalance! -
                                        (totalPrice as num).toDouble(),
                                    prefixText:
                                        '${'remaining_wallet_balance'.tr}: ',
                                    textStyle: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                    ),
                                  )
                                : const SizedBox(),
                          ]),
                    ),
                    InkWell(
                      onTap: () {
                        if (kDebugMode) {
                          debugPrint(
                            '[PaymentMethod][WALLET_USE_TAP] before paymentMethodIndex=${checkoutController.paymentMethodIndex} '
                            'isMyPay=${checkoutController.isMy_Pay}',
                          );
                        }
                        if (!checkoutController.isMy_Pay) {
                          checkoutController.change_My_Pay();
                        }
                        if (Get.find<ProfileController>()
                                .userInfoModel!
                                .walletBalance! <
                            (totalPrice as num).toDouble()) {
                          checkoutController.changePartialPayment();
                        } else {
                          checkoutController.setPaymentMethod(1);
                        }
                        if (kDebugMode) {
                          debugPrint(
                            '[PaymentMethod][WALLET_SELECTED] after paymentMethodIndex=${checkoutController.paymentMethodIndex}',
                          );
                          debugPrint('[PaymentMethod][BOTTOM_CLOSE]');
                        }
                        Navigator.of(context).pop();
                        showCustomSnackBar('regular_wallet_selected'.tr,
                            isError: false);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 0.5),
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeSmall,
                            horizontal: Dimensions.paddingSizeLarge),
                        child: Text(
                          'use'.tr,
                          style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ]),
                )
          : const SizedBox();
    },
  );
}

// 🎨 NEW DESIGN: "محفظتي" wallet bottom-sheet content (matches Figma).
Widget _mobileWalletSheet(BuildContext context,
    CheckoutController checkoutController, dynamic totalPrice) {
  final double balance =
      Get.find<ProfileController>().userInfoModel!.walletBalance ?? 0;
  final double total = (totalPrice as num).toDouble();
  final bool coversAll = balance >= total;
  final double deducted = coversAll ? total : balance;
  final double remaining = coversAll ? balance - total : total - balance;

  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color headline = isDark ? Colors.white : const Color(0xFF121C19);
  final Color subtitle =
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF545454);
  final Color summaryBg =
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF9F8FA);

  return SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Image.asset(Images.myWalletIcon,
              width: 60, height: 60, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text('my_wallet'.tr,
            style: tajawalBold.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.6,
                color: headline)),
        const SizedBox(height: 6),
        Text(
          'use_wallet_balance_to_pay'.tr,
          textAlign: TextAlign.center,
          style: tajawalMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
              letterSpacing: 0,
              color: subtitle),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: summaryBg,
            borderRadius: BorderRadius.circular(12),
            border: isDark
                ? Border.all(color: const Color(0xFF334155))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text('payment_summary'.tr,
                    style: tajawalBold.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                        color: headline)),
              ),
              const SizedBox(height: 12),
              _walletRow(context, 'available_balance'.tr, balance),
              const SizedBox(height: 10),
              _walletRow(context, 'will_be_deducted'.tr, deducted),
              const SizedBox(height: 10),
              _walletRow(context,
                  coversAll ? 'remaining_in_wallet'.tr : 'remaining_to_pay'.tr, remaining,
                  valueColor: Theme.of(context).primaryColor),
            ],
          ),
        ),
        if (!coversAll) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  'wallet_first_then_selected_method'.tr,
                  textAlign: TextAlign.right,
                  style: tajawalMedium.copyWith(
                      fontSize: 12,
                      height: 1.6,
                      color: headline),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Color(0xFF1C1C1C), shape: BoxShape.circle),
                child: const Icon(Icons.priority_high,
                    size: 14, color: Colors.white),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: GetBuilder<KaidhaSubscriptionController>(
            builder: (kaidhaSubController) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault)),
                ),
                onPressed: () {
                  if (!checkoutController.isMy_Pay) {
                    checkoutController.change_My_Pay();
                  }
                  if (balance < total) {
                    checkoutController.changePartialPayment();
                  } else {
                    checkoutController.setPaymentMethod(1);
                  }
                  Navigator.of(context).pop();
                  showCustomSnackBar('regular_wallet_selected'.tr,
                      isError: false);
                },
                child: Text('use_wallet'.tr,
                    style: tajawalBold.copyWith(
                        color: Colors.white, fontSize: 16, height: 1.6)),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFF6F6F6),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr,
                style: tajawalBold.copyWith(
                    color: isDark
                        ? const Color(0xFF111B18)
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                    height: 1.6)),
          ),
        ),
      ],
    ),
  );
}

Widget _walletRow(BuildContext context, String label, double value,
    {Color? valueColor}) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color base = isDark ? Colors.white : const Color(0xFF121C19);
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: tajawalMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: valueColor ?? base)),
      Row(children: [
        Text(value.toStringAsFixed(2),
            style: tajawalMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                height: 1.6,
                color: valueColor ?? base)),
        const SizedBox(width: 4),
        Image.asset(Images.sar,
            width: 13,
            height: 15,
            color: valueColor ?? base),
      ]),
    ],
  );
}
