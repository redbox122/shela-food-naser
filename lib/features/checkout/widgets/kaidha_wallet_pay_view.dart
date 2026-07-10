// ignore_for_file: non_constant_identifier_names, prefer_const_constructors, avoid_unnecessary_containers, camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class Kaidha_Wallet_Pay_BottomSheet extends StatefulWidget {
  const Kaidha_Wallet_Pay_BottomSheet({super.key});

  @override
  State<Kaidha_Wallet_Pay_BottomSheet> createState() =>
      _Kaidha_Wallet_Pay_BottomSheetState();
}

class _Kaidha_Wallet_Pay_BottomSheetState
    extends State<Kaidha_Wallet_Pay_BottomSheet> {
  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Theme-aware colors: white/slate in dark, original light values in light.
    final Color headline = isDark ? Colors.white : const Color(0xFF121C19);
    final Color subtitle = isDark ? const Color(0xFF94A3B8) : const Color(0xFF545454);
    final Color infoCardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F5F8);
    return GetBuilder<KaidhaSubscriptionController>(
      builder: (KaidhaSubController) {
        return GetBuilder<CheckoutController>(
          builder: (checkoutController) {
            final wallet = KaidhaSubController.walletKaidhaModel?.wallet;
            final double balance =
                double.tryParse('${wallet?.availableBalance ?? 0}') ?? 0;
            final double? purchaseLimit = wallet?.purchaseLimit != null
                ? double.tryParse('${wallet!.purchaseLimit}')
                : null;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Green circular card icon.
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                    ),
                    child: Image.asset(
                      Images.quidhaWalletIcon,
                      color: Color(0xffFFFFFF),
                      width: 50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount with SAR symbol.
                  PriceConverter.convertPrice2(
                    checkoutController.viewTotalPrice,
                    textStyle: tajawalBold.copyWith(
                      color: primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('pay_with_qidha'.tr,
                      textAlign: TextAlign.center,
                      style: tajawalBold.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: 0,
                        color: headline,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'use_wallet_balance_to_pay'.tr,
                    textAlign: TextAlign.center,
                    style: tajawalMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      letterSpacing: 0,
                      color: subtitle,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Wallet info card.
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: infoCardBg,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                      border: isDark
                          ? Border.all(color: const Color(0xFF334155))
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('wallet_info'.tr,
                            textAlign: TextAlign.right,
                            style: tajawalBold.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.6,
                              letterSpacing: 0,
                              color: headline,
                            )),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        _buildWalletInfoRow(
                          context: context,
                          label: 'available_balance'.tr,
                          value: PriceConverter.convertPrice2(
                            balance,
                            textStyle: tajawalBold.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                              color: headline,
                            ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        _buildWalletInfoRow(
                          context: context,
                          label: 'purchase_limit'.tr,
                          value: purchaseLimit != null
                              ? PriceConverter.convertPrice2(
                                  purchaseLimit,
                                  textStyle: tajawalBold.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0,
                                    color: const Color(0xFF121C19),
                                  ),
                                )
                              : Text('not_specified'.tr,
                                  style: tajawalBold.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0,
                                    color: headline,
                                  )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Use Qidha wallet — primary action.
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!checkoutController.isKaidhaPay) {
                          checkoutController.change_Kaidha_Pay();
                        }
                        checkoutController.setPaymentMethod(0);
                        Navigator.of(context).pop();
                        showSelectionSnackBar('تم اختيار محفظة قيدها للدفع');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                      ),
                      child: Text('use_qidha_wallet'.tr,
                          style: tajawalBold.copyWith(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.white,
                          )),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cancel.
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFFF6F6F6),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                      ),
                      child: Text('cancel'.tr,
                          style: tajawalBold.copyWith(
                            fontSize: 15,
                            color: isDark
                                ? const Color(0xFF111B18)
                                : const Color(0xFF717885),
                          )),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWalletInfoRow({
    required BuildContext context,
    required String label,
    required Widget value,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tajawalMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.6,
            letterSpacing: 0,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF515151),
          ),
        ),
        value,
      ],
    );
  }
}
