// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

Widget PartialPayView(BuildContext context, {required totalPrice, required isPrescription}) {
  return GetBuilder<CheckoutController>(
    id: 'payment', // ✅ استخدام ID لتحديث جزئي
    builder: (checkoutController) {
      // ✅ FIX: Removed !(isPrescription) condition - wallet payment should be available for all orders
      // The isPrescription flag was incorrectly blocking wallet view for normal orders (storeId != null)
      final profileController = Get.find<ProfileController>();
      final bool hasWalletBalance = profileController.userInfoModel != null &&
              profileController.userInfoModel!.walletBalance != null &&
              profileController.userInfoModel!.walletBalance! > 0;
      final bool walletEnabled = Get.find<SplashController>().configModel!.customerWalletStatus == 1;

      return hasWalletBalance && walletEnabled
          ? AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                color: Get.find<ThemeController>().darkTheme
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.05),
                border: Border.all(color: Theme.of(context).primaryColor, width: 0.5),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                image: !ResponsiveHelper.isDesktop(context)
                    ? DecorationImage(
                        alignment: Alignment.bottomRight,
                        colorFilter: ColorFilter.mode(Colors.white.withValues(alpha: 0.1), BlendMode.dstATop),
                        image: const AssetImage(Images.partialWallet),
                      )
                    : null,
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: ResponsiveHelper.isDesktop(context)
                  ? Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1
                              ? Row(children: [
                                  Container(
                                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    'applied'.tr,
                                    style: robotoMedium.copyWith(
                                        color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault),
                                  )
                                ])
                              : Text(
                                  'do_you_want_to_use_now'.tr,
                                  style: robotoMedium.copyWith(
                                      color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault),
                                ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          PriceConverter.convertPrice2(
                            Get.find<ProfileController>().userInfoModel!.walletBalance!,
                            textStyle: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          checkoutController.paymentMethodIndex == 1
                              ? PriceConverter.convertPrice2(
                                  Get.find<ProfileController>().userInfoModel!.walletBalance! - (totalPrice as num).toDouble(),
                                  prefixText: '${'remaining_wallet_balance'.tr}: ',
                                  textStyle: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                  ),
                                )
                              : const SizedBox(),
                        ]),
                      ),
                      InkWell(
                        onTap: () {
                          if (Get.find<ProfileController>().userInfoModel!.walletBalance! < (totalPrice as num).toDouble()) {
                            checkoutController.changePartialPayment();
                          } else {
                            checkoutController.setPaymentMethod(1);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 0.5),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                          child: Text(
                            'use'.tr,
                            style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ])
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          //

                          // Row(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     Image.asset(Images.partialWallet, height: 30, width: 30),
                          //     const SizedBox(width: Dimensions.paddingSizeSmall),
                          //     Column(
                          //       crossAxisAlignment: CrossAxisAlignment.start,
                          //       children: [
                          //         PriceConverter.convertPrice2(
                          //           Get.find<ProfileController>().userInfoModel!.walletBalance!,
                          //           textStyle: robotoBold.copyWith(
                          //             fontSize: Dimensions.fontSizeOverLarge,
                          //             color: Theme.of(context).primaryColor,
                          //           ),
                          //         ),
                          //         const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          //         Text(
                          //           checkoutController.isPartialPay
                          //               ? 'has_paid_by_your_wallet'.tr
                          //               : 'your_have_balance_in_your_wallet'.tr,
                          //           style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                          //         ),
                          //       ],
                          //     ),
                          //   ],
                          // ),

                          const SizedBox(height: 10),
                          Text('my_wallet'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          PriceConverter.convertPrice2(
                            checkoutController.viewTotalPrice,
                            textStyle: robotoBold.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeOverLarge,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Icon(Icons.contactless, color: Colors.green, size: 100),
                          const Text('أختر', style: TextStyle(fontSize: 16)),
                          const Text('اي طريقه دفع مناسبة'),
                          const SizedBox(height: 20),
                          
                          // Wallet Balance Information Card
                          Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                                      'معلومات المحفظة',
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
                                  value: '${Get.find<ProfileController>().userInfoModel!.walletBalance!.toStringAsFixed(2)} ريال',
                                  icon: Icons.account_balance_wallet,
                                ),
                                
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                
                                // Remaining Balance After Payment
                                if (checkoutController.paymentMethodIndex == 1)
                                  _buildWalletInfoRow(
                                    context: context,
                                    label: 'الرصيد المتبقي',
                                    value: '${(Get.find<ProfileController>().userInfoModel!.walletBalance! - (totalPrice as num).toDouble()).toStringAsFixed(2)} ريال',
                                    icon: Icons.account_balance,
                                  ),
                                
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                
                                // Payment Status
                                _buildWalletInfoRow(
                                  context: context,
                                  label: 'حالة الدفع',
                                  value: checkoutController.paymentMethodIndex == 1 ? 'مفعل' : 'غير مفعل',
                                  icon: checkoutController.paymentMethodIndex == 1 ? Icons.check_circle : Icons.pending,
                                  valueColor: checkoutController.paymentMethodIndex == 1 ? Colors.green : Colors.orange,
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
                              checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1
                                  ? Row(children: [
                                      Container(
                                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                                      ),
                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                      Text(
                                        'applied'.tr,
                                        style: robotoMedium.copyWith(
                                            color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                                      )
                                    ])
                                  : Text(
                                      'do_you_want_to_use_now'.tr,
                                      style: robotoMedium.copyWith(
                                          color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                                    ),
                              GetBuilder<KaidhaSubscription_Controller>(
                                builder: (KaidhaSubController) {
                                  return InkWell(
                                    onTap: () {
                                      // Enable regular wallet payment (set to true, don't toggle)
                                      if (!checkoutController.isMy_Pay) {
                                        checkoutController.change_My_Pay();
                                      }

                                      if (Get.find<ProfileController>().userInfoModel!.walletBalance! < (totalPrice as num).toDouble()) {
                                        checkoutController.changePartialPayment();
                                      } else {
                                        // Set payment method to regular wallet (index 1)
                                        checkoutController.setPaymentMethod(1);
                                      }
                                      
                                      // Close the bottom sheet
                                      Navigator.of(context).pop();
                                      
                                      // Show success message
                                      showCustomSnackBar('تم اختيار المحفظة العادية للدفع', isError: false);
                                    },
                                    child: Container(
                                      width: 130,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        border: Border.all(
                                            color: Theme.of(context).primaryColor,
                                            width: 0.5),
                                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                                      child: Center(
                                        child: Text(
                                          'use'.tr,
                                          style: robotoBold.copyWith(
                                              fontSize: Dimensions.fontSizeLarge,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          //
                          SizedBox(height: Dimensions.fontSizeExtraLarge),

                          checkoutController.paymentMethodIndex == 1
                              ? PriceConverter.convertPrice2(
                                  Get.find<ProfileController>().userInfoModel!.walletBalance! - (totalPrice as num).toDouble(),
                                  prefixText: '${'remaining_wallet_balance'.tr}: ',
                                  textStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                                )
                              : const SizedBox(),
                        ],
                      ),
                    ),
            )
          : const SizedBox();
    },
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
