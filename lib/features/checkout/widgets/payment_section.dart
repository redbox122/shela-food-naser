// ignore_for_file: unnecessary_null_comparison, deprecated_member_use, non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_method_bottom_sheet.dart';

class PaymentSection extends StatefulWidget {
  final Widget? partialPayView;
  final Widget? Kaidha_Wallat_PayView;

  final int? storeId;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final double total;
  final bool isOfflinePaymentActive;

  const PaymentSection({
    super.key,
    required this.partialPayView,
    required this.Kaidha_Wallat_PayView,
    this.storeId,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isWalletActive,
    required this.total,
    required this.isOfflinePaymentActive,
  });

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  CheckoutController checkoutController = Get.find<CheckoutController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
        id: 'payment', // ✅ استخدام ID لتحديث جزئي
        builder: (checkoutController) {
          return Column(
            children: [
              //

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                    widget.storeId != null
                        ? 'payment_method'.tr
                        : 'choose_payment_method'.tr,
                    style: robotoMedium),
                // widget.storeId == null && !ResponsiveHelper.isDesktop(context)
                //     ? InkWell(
                //         onTap: () {
                //            Get.bottomSheet(
                //            const PaymentMethodBottomSheet(),
                //            backgroundColor: Colors.transparent,
                //               isScrollControlled: true,
                //          );
                //         },
                //         child: Image.asset(Images.paymentSelect, height: 26, width: 26),
                //       )
                //     : const SizedBox(),
              ]),
              !ResponsiveHelper.isDesktop(context)
                  ? const Divider()
                  : const SizedBox(height: Dimensions.paddingSizeSmall),

              //

              SizedBox(height: Dimensions.fontSizeSmall),

              // PaymentButtons(
              //   checkoutController: checkoutController,
              //   partialPayView: widget.partialPayView,
              // ),

              GetBuilder<KaidhaSubscriptionController>(
                  builder: (KaidhaSub_Controller) {
                return GetBuilder<ProfileController>(
                    builder: (profileController) {
                  return Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPaymentOption(
                            context: context,
                            label: 'my_wallet'.tr,
                            icon: Icons.account_balance_wallet_outlined,
                            index: 2,
                            onTap: () {
                              if (profileController
                                          .userInfoModel!.walletBalance ==
                                      0.0 ||
                                  profileController.userInfoModel == null ||
                                  profileController
                                          .userInfoModel!.walletBalance ==
                                      null) {
                                showCustomSnackBar('المحفظه فارغة من الرصيد');
                                return;
                              }

                              setState(() {
                                checkoutController.selectedButton = 2;
                                checkoutController.select_payment_Methods =
                                    null;
                              });

                              if (checkoutController.isKaidhaPay == true) {
                                //"قيدها"
                                checkoutController.change_Kaidha_Pay();
                              }

                              if (widget.partialPayView != null) {
                                if (kDebugMode) {
                                  debugPrint(
                                    '[PaymentMethod][BOTTOM_OPEN] partialWallet sheet',
                                  );
                                }
                                Get.bottomSheet(
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.vertical(
                                        top: const Radius.circular(
                                            Dimensions.radiusLarge),
                                        bottom: Radius.circular(
                                            ResponsiveHelper.isDesktop(context)
                                                ? Dimensions.radiusLarge
                                                : 0),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeLarge,
                                      vertical: Dimensions.paddingSizeLarge,
                                    ),
                                    child: widget.partialPayView,
                                  ),
                                );
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _buildPaymentOption(
                              context: context,
                              label: 'kiadha_wallet'.tr,
                              icon: Icons.credit_card_outlined,
                              index: 0,
                              onTap: () {
                                // Check if wallet data is loaded
                                if (KaidhaSub_Controller.walletKaidhaModel ==
                                        null ||
                                    KaidhaSub_Controller
                                            .walletKaidhaModel!.wallet ==
                                        null) {
                                  showCustomSnackBar(
                                      'محفظة قيدها غير متاحة - يرجى المحاولة لاحقاً');
                                  return;
                                }

                                // Log raw wallet data before any eligibility check.
                                final kw = KaidhaSub_Controller
                                    .walletKaidhaModel?.wallet;
                                debugPrint(
                                    '[Qidha][SELECT] userId=${kw?.userId}'
                                    ' status=${kw?.status}'
                                    ' sig=${kw?.signatureStatus}'
                                    ' balance=${kw?.availableBalance}'
                                    ' creditLimit=${kw?.creditLimit}');

                                // Check if wallet has sufficient balance
                                final availableBalance = KaidhaSub_Controller
                                    .walletKaidhaModel!
                                    .wallet!
                                    .availableBalance;
                                if (availableBalance == null ||
                                    availableBalance.toString() == '0.00' ||
                                    double.tryParse(
                                            availableBalance.toString()) ==
                                        0.0) {
                                  showCustomSnackBar('المحفظه فارغة من الرصيد');
                                  return;
                                }

                                // Block selection if wallet is not active
                                final String? kaidhaStatus =
                                    KaidhaSub_Controller
                                        .walletKaidhaModel!.wallet!.status
                                        ?.toLowerCase();
                                if (kaidhaStatus != 'active') {
                                  debugPrint(
                                      '[Qidha][SELECT-BLOCK] wallet status=$kaidhaStatus (not active)');
                                  showCustomSnackBar('محفظة قيدها غير مفعّلة');
                                  return;
                                }

                                // Block selection if wallet is not signed/verified
                                final dynamic sigRaw = KaidhaSub_Controller
                                    .walletKaidhaModel!.wallet!.signatureStatus;
                                final bool isSigned =
                                    sigRaw == 1 || sigRaw == true;
                                if (!isSigned) {
                                  debugPrint(
                                      '[Qidha][SELECT-BLOCK] signatureStatus=$sigRaw (not signed)');
                                  Get.dialog(
                                    AlertDialog(
                                      title: const Text('محفظة قيدها'),
                                      content: const Text(
                                          'لم يتم توقيع عقد محفظة قيدها بعد. يجب إكمال خطوة توقيع العقد لتفعيل الدفع.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: const Text('إغلاق'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Get.back();
                                            Get.toNamed(RouteHelper
                                                .getKiadaWalletSubscription());
                                          },
                                          child: const Text('إكمال التحقق'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  checkoutController.selectedButton = 0;
                                  checkoutController.select_payment_Methods =
                                      null;
                                });

                                checkoutController.setPaymentMethod(0);

                                // Ensure Qidha wallet is enabled
                                if (checkoutController.isKaidhaPay == false) {
                                  checkoutController.change_Kaidha_Pay();
                                }

                                if (checkoutController.isPartialPay == true) {
                                  //"محفظتي"
                                  checkoutController.changePartialPayment();
                                }
                                if (checkoutController.isMy_Pay == true) {
                                  //عادي
                                  checkoutController.change_My_Pay();
                                }

                                if (widget.Kaidha_Wallat_PayView != null) {
                                  Get.bottomSheet(
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.vertical(
                                          top: const Radius.circular(
                                              Dimensions.radiusLarge),
                                          bottom: Radius.circular(
                                              ResponsiveHelper.isDesktop(
                                                      context)
                                                  ? Dimensions.radiusLarge
                                                  : 0),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.paddingSizeLarge,
                                        vertical: Dimensions.paddingSizeLarge,
                                      ),
                                      child: widget.Kaidha_Wallat_PayView,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          _buildPaymentOption(
                            context: context,
                            label: 'my_bill_wallet'.tr,
                            icon: Icons.receipt_long_outlined,
                            index: 1,
                            onTap: () {
                              setState(() {
                                checkoutController.selectedButton = 1;
                              });

                              checkoutController.setPaymentMethod(2);

                              if (checkoutController.isKaidhaPay == true) {
                                //"قيدها"
                                checkoutController.change_Kaidha_Pay();
                              }

                              if (checkoutController.isMy_Pay == true) {
                                //عادي
                                checkoutController.change_My_Pay();
                              }

                              Get.bottomSheet(
                                const PaymentMethodBottomSheet(),
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                              ).then((_) {
                                setState(() {});
                              });
                            },
                          ),

                          //
                        ],
                      ),
                    ),
                  );
                });
              }),

              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              // =======================================

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:

                    //

                    checkoutController.select_payment_Methods != null &&
                            checkoutController.paymentMethodIndex == 2
                        ? ListTile(
                            leading: SmartImage(
                              url: checkoutController
                                      .select_payment_Methods!.imageUrl ??
                                  '',
                              height: 50,
                              width: 50,
                              cacheWidth: 300,
                              cacheHeight: 300,
                              errorWidget:
                                  const Icon(Icons.image_not_supported),
                            ),
                            title: Text(checkoutController
                                    .select_payment_Methods!.paymentMethodEn ??
                                ''),
                          )
                        : checkoutController.paymentMethodIndex == 1
                            ? ListTile(
                                leading: Image.asset(Images.partialWallet,
                                    height: 35, width: 35),
                                title: Text('wallet'.tr),
                              )
                            : checkoutController.paymentMethodIndex == 0
                                ? ListTile(
                                    leading: Image.asset(Images.walletIcon,
                                        height: 30, width: 30),
                                    title: Text('kiadha_wallet'.tr),
                                  )

                                // -----------------

                                : Row(
                                    children: [
                                      Icon(
                                        Icons.wallet_outlined,
                                        size: 18,
                                        color: !ResponsiveHelper.isDesktop(
                                                context)
                                            ? Theme.of(context).disabledColor
                                            : Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(
                                          width: Dimensions.paddingSizeSmall),
                                      //

                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(
                                              'select_payment_method'.tr,
                                              style: robotoMedium.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                color: !ResponsiveHelper
                                                        .isDesktop(context)
                                                    ? Theme.of(context)
                                                        .disabledColor
                                                    : checkoutController
                                                                .paymentMethodIndex ==
                                                            -1
                                                        ? Theme.of(context)
                                                            .primaryColor
                                                        : Theme.of(context)
                                                            .disabledColor,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: Dimensions
                                                      .paddingSizeExtraSmall,
                                                  right: Dimensions
                                                      .paddingSizeExtraSmall),
                                              child: Icon(Icons.error,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
              ),
            ],
          );
        });
  }

  //

  Widget _buildPaymentOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int index,
    required VoidCallback onTap,
  }) {
    final bool isSelected = index == 0
        ? checkoutController.paymentMethodIndex == 0
        : index == 1
            ? checkoutController.paymentMethodIndex == 2
            : checkoutController.paymentMethodIndex == 1;

    // Special handling for electronic payment (index 1) - make it green
    Color borderColor;
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (index == 1 && isSelected) {
      // Electronic payment selected - green theme
      borderColor = Colors.green;
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      iconColor = Colors.green;
      textColor = Colors.green;
    } else {
      // Default theme for other payment methods
      borderColor = isSelected
          ? Theme.of(context).primaryColor
          : Theme.of(context).hintColor.withValues(alpha: 0.4);
      backgroundColor = isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : Colors.transparent;
      iconColor = isSelected
          ? Theme.of(context).primaryColor
          : Theme.of(context).hintColor;
      textColor = isSelected
          ? Theme.of(context).primaryColor
          : Theme.of(context).hintColor;
    }

    // Get wallet balance based on payment method index
    final String walletBalance = _getWalletBalance(index);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              walletBalance,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.8)
                    : Theme.of(context).hintColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getWalletBalance(int index) {
    switch (index) {
      case 0: // Qidha Wallet
        final kaidhaController = Get.find<KaidhaSubscriptionController>();
        if (kaidhaController.walletKaidhaModel?.wallet?.availableBalance !=
            null) {
          final double balance = double.tryParse(kaidhaController
                  .walletKaidhaModel!.wallet!.availableBalance
                  .toString()) ??
              0.0;
          return 'رصيد: ${balance.toStringAsFixed(2)} ريال';
        }
        return 'رصيد: 0.00 ريال';

      case 2: // Regular Wallet
        final profileController = Get.find<ProfileController>();
        if (profileController.userInfoModel?.walletBalance != null) {
          final double balance =
              profileController.userInfoModel!.walletBalance!;
          return 'رصيد: ${balance.toStringAsFixed(2)} ريال';
        }
        return 'رصيد: 0.00 ريال';

      case 1: // Digital Payment
        return 'دفع آمن';

      default:
        return '';
    }
  }
}
