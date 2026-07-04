// ignore_for_file: non_constant_identifier_names, prefer_const_constructors, avoid_unnecessary_containers, camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
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
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      decoration: BoxDecoration(
        color:
            tokens?.successSoft ?? theme.colorScheme.primary.withValues(alpha: 0.10),
        border: Border.all(color: Theme.of(context).primaryColor, width: 0.5),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        image: !ResponsiveHelper.isDesktop(context)
            ? DecorationImage(
                alignment: Alignment.bottomRight,
                colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.1), BlendMode.dstATop),
                image: const AssetImage(Images.partialWallet),
              )
            : null,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: GetBuilder<KaidhaSubscriptionController>(
        builder: (KaidhaSubController) {
          return GetBuilder<CheckoutController>(
            builder: (checkoutController) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text('pay_pay_qidha'.tr,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    PriceConverter.convertPrice2(
                      checkoutController.viewTotalPrice,
                      textStyle: robotoBold.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeOverLarge,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Icon(Icons.contactless,
                        color: Colors.green, size: 100),
                    const SizedBox(height: 20),

                    // Wallet Balance Information Card
                    Container(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'pay_wallet_info'.tr,
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Icon(
                                Icons.account_balance_wallet,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // Available Balance
                          _buildWalletInfoRow(
                            context: context,
                            label: 'الرصيد المتاح',
                            value: KaidhaSubController.walletKaidhaModel?.wallet
                                        ?.availableBalance !=
                                    null
                                ? '${double.tryParse(KaidhaSubController.walletKaidhaModel!.wallet!.availableBalance.toString())?.toStringAsFixed(2) ?? '0.00'} ريال'
                                : '0.00 ريال',
                            icon: Icons.account_balance_wallet,
                          ),

                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          // Purchase Limit
                          _buildWalletInfoRow(
                            context: context,
                            label: 'حد الشراء',
                            value: KaidhaSubController.walletKaidhaModel?.wallet
                                        ?.purchaseLimit !=
                                    null
                                ? '${double.tryParse(KaidhaSubController.walletKaidhaModel!.wallet!.purchaseLimit.toString())?.toStringAsFixed(2) ?? '0.00'} ريال'
                                : 'غير محدد',
                            icon: Icons.shopping_cart,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const LinearProgressIndicator(value: 0.1),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'do_you_want_to_use_now'.tr,
                          style: robotoBold.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeLarge),
                        ),
                        InkWell(
                          onTap: () {
                            // Enable Qidha payment (set to true, don't toggle)
                            if (!checkoutController.isKaidhaPay) {
                              checkoutController.change_Kaidha_Pay();
                            }

                            // Set payment method to Qidha (index 0)
                            checkoutController.setPaymentMethod(0);

                            // Close the bottom sheet
                            Navigator.of(context).pop();

                            // Show success message
                            showCustomSnackBar('pay_qidha_wallet_selected'.tr,
                                isError: false);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 0.5),
                              borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeSmall,
                                horizontal: Dimensions.paddingSizeLarge),
                            child: Text(
                              'use'.tr,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWalletInfoRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              Text(
                value,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: valueColor ?? Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
