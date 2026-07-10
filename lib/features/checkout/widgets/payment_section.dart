// ignore_for_file: unnecessary_null_comparison, deprecated_member_use, non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
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
                    textAlign: TextAlign.right,
                    style: tajawalBold.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.6,
                      letterSpacing: 0,
                    )),
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
              const SizedBox(height: Dimensions.paddingSizeSmall),

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
                            imageAsset: Images.myWalletIcon,
                            index: 2,
                            onTap: () {
                              // Guard null FIRST — the old order unwrapped
                              // userInfoModel! before the == null check, so a
                              // not-yet-loaded profile crashed on tapping wallet.
                              final info = profileController.userInfoModel;
                              if (info == null ||
                                  info.walletBalance == null ||
                                  info.walletBalance == 0.0) {
                                _showEmptyWalletBottomSheet();
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
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF1E293B)
                                          : Theme.of(context).cardColor,
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
                              imageAsset: Images.quidhaWalletIcon,
                              index: 0,
                              onTap: () {
                                debugPrint('[QIDHA_CHECKOUT][SELECTED]');
                                final userInfo =
                                    profileController.userInfoModel;
                                // Source of truth for the wallet state is the
                                // KaidhaSubscriptionController (same source as
                                // the displayed balance); fall back to the
                                // profile flags only when it's unavailable. This
                                // fixes the "subscription required" prompt
                                // showing even though a funded, active wallet
                                // already exists.
                                final walletModel =
                                    KaidhaSub_Controller.walletKaidhaModel;
                                final wallet = walletModel?.wallet;
                                final bool hasWallet =
                                    walletModel?.hasWallet == true ||
                                        wallet != null ||
                                        userInfo?.hasQidhaWallet == true;
                                // Type-robust checks: the API may return these
                                // as int (1), string ("1") or bool, so compare
                                // on the stringified value. A non-empty
                                // signature path also implies a signed contract.
                                final String sigStatus =
                                    wallet?.signatureStatus?.toString() ?? '';
                                final String walletStatus =
                                    wallet?.status?.toString().toLowerCase() ??
                                        '';
                                final bool hasSignaturePath =
                                    (wallet?.signaturePath?.toString() ?? '')
                                        .isNotEmpty;
                                final bool isSigned = sigStatus == '1' ||
                                    sigStatus == 'true' ||
                                    hasSignaturePath ||
                                    userInfo?.qidhaWalletSigned == true;
                                final bool isActive =
                                    walletStatus == 'active' ||
                                        walletStatus == '1' ||
                                        walletStatus == 'true' ||
                                        userInfo?.qidhaWalletActive == true;
                                final double profileBalance =
                                    userInfo?.qidhaWalletBalance ?? 0.0;
                                final double walletBalance = double.tryParse(
                                        '${wallet?.availableBalance ?? profileBalance}') ??
                                    profileBalance;
                                debugPrint(
                                    '[QIDHA_CHECKOUT][STATUS] hasWallet=$hasWallet signed=$isSigned active=$isActive balance=$walletBalance '
                                    'rawSigStatus=${wallet?.signatureStatus} rawStatus=${wallet?.status} rawSigPath=${wallet?.signaturePath}');

                                if (!hasWallet) {
                                  debugPrint(
                                      '[QIDHA_CHECKOUT][BLOCKED] reason=not_subscribed');
                                  _showQidhaSubscriptionRequiredDialog();
                                  return;
                                }
                                if (!isSigned) {
                                  debugPrint(
                                      '[QIDHA_CHECKOUT][BLOCKED] reason=signature_required');
                                  _showQidhaSignatureRequiredDialog();
                                  return;
                                }
                                if (!isActive) {
                                  debugPrint(
                                      '[QIDHA_CHECKOUT][BLOCKED] reason=inactive');
                                  _showQidhaPendingActivationDialog();
                                  return;
                                }
                                if (walletBalance < widget.total) {
                                  debugPrint(
                                      '[QIDHA_CHECKOUT][BLOCKED] reason=insufficient_balance');
                                  showCustomSnackBar(
                                      'insufficient_qidha_balance'.tr);
                                  return;
                                }
                                if (KaidhaSub_Controller.walletKaidhaModel ==
                                        null ||
                                    KaidhaSub_Controller
                                            .walletKaidhaModel!.wallet ==
                                        null) {
                                  debugPrint(
                                      '[QIDHA_CHECKOUT][ERROR] reason=api_unavailable');
                                  showCustomSnackBar(
                                      'محفظة قيدها غير متاحة - يرجى المحاولة لاحقًا');
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
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF1E293B)
                                            : Theme.of(context).cardColor,
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
                            imageAsset: Images.receiptAddIcon,
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

              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Inline warning shown when the user taps pay without picking a
              // payment method. Cleared automatically once a method is selected.
              if (checkoutController.payMethodError)
                Builder(builder: (context) {
                  final bool isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3320)
                          : const Color(0xFFFCF0D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'please_select_payment_method'.tr,
                            textAlign: TextAlign.right,
                            style: tajawalBold.copyWith(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark
                                  ? const Color(0xFFF5E6C8)
                                  : const Color(0xFF121C19),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFF5E6C8)
                                : const Color(0xFF1C1C1C),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.priority_high,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF3A3320)
                                  : Colors.white),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        });
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int index,
    required VoidCallback onTap,
    String? imageAsset,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = index == 0
        ? checkoutController.paymentMethodIndex == 0
        : index == 1
            ? checkoutController.paymentMethodIndex == 2
            : checkoutController.paymentMethodIndex == 1;

    // Special handling for electronic payment (index 1) - make it green
    Color borderColor;
    Color backgroundColor;
    Color iconColor;

    // Active container background per design.
    const Color activeBg = Color(0xFFEBFEEB);
    if (index == 1 && isSelected) {
      // Electronic payment selected - green theme
      borderColor = Colors.green;
      backgroundColor = activeBg;
      iconColor = Colors.green;
    } else {
      // Default theme for other payment methods
      borderColor = isSelected
          ? Theme.of(context).primaryColor
          : Theme.of(context).hintColor.withValues(alpha: 0.4);
      backgroundColor = isSelected ? activeBg : Colors.transparent;
      iconColor = isSelected
          ? Theme.of(context).primaryColor
          : Theme.of(context).hintColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: 128,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            imageAsset != null
                ? Image.asset(imageAsset,
                    width: 24,
                    height: 24,
                    color: (isDark && !isSelected)
                        ? Colors.white
                        : const Color(0xFF010201))
                : Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tajawalBold.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                  letterSpacing: 0,
                  color: (isDark && !isSelected)
                      ? Colors.white
                      : const Color(0xff010201)),
            ),
            const SizedBox(height: 4),
            _buildWalletBalance(context, index),
          ],
        ),
      ),
    );
  }

  /// Balance line under a payment card. Wallet/Qidha show the amount with the
  /// SAR currency symbol; digital payment shows the "secure pay" label.
  Widget _buildWalletBalance(BuildContext context, int index) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = index == 0
        ? checkoutController.paymentMethodIndex == 0
        : index == 1
            ? checkoutController.paymentMethodIndex == 2
            : checkoutController.paymentMethodIndex == 1;
    final TextStyle style = tajawalMedium.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0,
      color: (isDark && !isSelected) ? Colors.white : const Color(0xFF121C19),
    );

    if (index == 1) {
      // Digital Payment
      return Text('secure_payment'.tr,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }

    double balance = 0.0;
    if (index == 0) {
      // Qidha Wallet
      final kaidhaController = Get.find<KaidhaSubscriptionController>();
      balance = double.tryParse(
              '${kaidhaController.walletKaidhaModel?.wallet?.availableBalance ?? 0}') ??
          0.0;
    } else {
      // Regular Wallet
      final profileController = Get.find<ProfileController>();
      balance = profileController.userInfoModel?.walletBalance ?? 0.0;
    }

    return PriceConverter.convertPrice2(balance, textStyle: style);
  }

  /// Bottom sheet shown when the user's wallet has no balance — offers to top
  /// up instead of the old plain snackbar.
  Future<void> _showEmptyWalletBottomSheet() async {
    await Get.bottomSheet<void>(
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusExtraLarge),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeExtraLarge,
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeLarge),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'wallet_empty'.tr,
                textAlign: TextAlign.center,
                style: tajawalBold.copyWith(
                  fontSize: 22,
                  height: 33 / 22,
                  letterSpacing: 0,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF121C19),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'add_balance_to_complete_payment'.tr,
                textAlign: TextAlign.center,
                style: tajawalMedium.copyWith(
                  fontSize: 18,
                  height: 1.6,
                  letterSpacing: 0,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFB9C0CC)
                      : const Color(0xFF545454),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back<void>();
                    Get.toNamed(RouteHelper.getWalletRoute());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                  ),
                  child: Text(
                    'add_balance'.tr,
                    style: tajawalBold.copyWith(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _showQidhaSubscriptionRequiredDialog() async {
    await Get.bottomSheet<void>(
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusExtraLarge),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeExtraLarge,
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeLarge),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'qidha_subscription_required'.tr,
                textAlign: TextAlign.center,
                style: tajawalBold.copyWith(
                  fontSize: 22,
                  height: 33 / 22,
                  letterSpacing: 0,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF121C19),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'subscribe_activate_to_use_qidha'.tr,
                textAlign: TextAlign.center,
                style: tajawalMedium.copyWith(
                  fontSize: 18,
                  height: 1.6,
                  letterSpacing: 0,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFB9C0CC)
                      : const Color(0xFF4C5452),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back<void>();
                    debugPrint('[QIDHA_CHECKOUT][ROUTE] qidha_subscription');
                    Get.toNamed(RouteHelper.getKiadaWalletSubscription());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                  ),
                  child: Text(
                    'subscribe_now'.tr,
                    style: tajawalBold.copyWith(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Shown when the Qidha wallet exists + is signed but not yet activated.
  /// Uses the [Images.quidha_info] illustration (129.21 × 81.83) per design.
  Future<void> _showQidhaPendingActivationDialog() async {
    await Get.dialog<void>(
      Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              constraints: BoxConstraints(maxWidth: Get.width * 0.85),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // X close (top-start → left in RTL), matching the design.
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: InkWell(
                      onTap: () => Get.back<void>(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF6F5F8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 18,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF121C19)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Image.asset(
                    Images.quidha_info,
                    width: 129.21,
                    height: 81.83,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'qidha_wallet_activating'.tr,
                    textAlign: TextAlign.center,
                    style: tajawalBold.copyWith(
                      fontSize: 18,
                      height: 1.6,
                      letterSpacing: 0,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF121C19),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'please_try_later'.tr,
                    textAlign: TextAlign.center,
                    style: tajawalMedium.copyWith(
                      fontSize: 14,
                      height: 1.6,
                      letterSpacing: 0,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFB9C0CC)
                          : const Color(0xFF4C5452),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showQidhaSignatureRequiredDialog() async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text('qidha_signature_required'.tr),
        content: Text('complete_qidha_agreement_first'.tr),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: Text('later'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              debugPrint('[QIDHA_CHECKOUT][ROUTE] qidha_subscription');
              Get.toNamed(RouteHelper.getKiadaWalletSubscription());
            },
            child: Text('subscribe_now'.tr),
          ),
        ],
      ),
    );
  }
}
