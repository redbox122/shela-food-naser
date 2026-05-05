import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/wallet/controllers/wallet_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';

class AddFundDialogueWidget extends StatefulWidget {
  const AddFundDialogueWidget({super.key});

  @override
  State<AddFundDialogueWidget> createState() => _AddFundDialogueWidgetState();
}

class _AddFundDialogueWidgetState extends State<AddFundDialogueWidget> {
  final TextEditingController inputAmountController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool _isLoadingMethods = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[ADD_FUND_DIALOG][OPEN]');
    Get.find<WalletController>().isTextFieldEmpty('', isUpdate: false);
    Get.find<WalletController>().changeDigitalPaymentName('', isUpdate: false);
    Get.find<WalletController>()
        .setSelectedPaymentMethod(null, isUpdate: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) {
        debugPrint('[ADD_FUND_DIALOG][DISPOSED_SKIP]');
        return;
      }
      debugPrint('[ADD_FUND_DIALOG][POST_FRAME_LOAD]');
      _loadPaymentMethods(1000.0);
    });
  }

  Future<void> _loadPaymentMethods(double amount) async {
    if (_isLoadingMethods) {
      debugPrint('[ADD_FUND_DIALOG][DUPLICATE_LOAD_BLOCKED]');
      return;
    }
    if (!mounted || _isDisposed) {
      debugPrint('[ADD_FUND_DIALOG][DISPOSED_SKIP]');
      return;
    }
    _isLoadingMethods = true;
    debugPrint('[ADD_FUND_DIALOG][LOAD_PAYMENT_METHODS_START]');
    try {
      await Get.find<WalletController>().loadPaymentMethodsForWallet(amount);
      final int count = Get.find<WalletController>().paymentMethods.length;
      debugPrint('[ADD_FUND_DIALOG][LOAD_PAYMENT_METHODS_DONE] count=$count');
    } catch (e) {
      debugPrint('[ADD_FUND_DIALOG][LOAD_PAYMENT_METHODS_ERROR] error=$e');
    } finally {
      _isLoadingMethods = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    inputAmountController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Widget _buildPaymentMethodsList(WalletController walletController) {
    if (walletController.isLoadingPaymentMethods) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (walletController.paymentMethods.isEmpty) {
      return Text('no_payment_method_is_available'.tr, style: robotoMedium);
    }

    return ListView.builder(
      itemCount: walletController.paymentMethods.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final paymentMethod = walletController.paymentMethods[index];
        final isSelected =
            walletController.selectedPaymentMethod?.paymentMethodId ==
                paymentMethod.paymentMethodId;

        return InkWell(
          onTap: () {
            walletController.setSelectedPaymentMethod(paymentMethod);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeLarge,
            ),
            child: Row(children: [
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).disabledColor),
                ),
                child: Icon(
                  Icons.check,
                  color: isSelected ? Colors.white : Colors.transparent,
                  size: 16,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              // Payment method icon (if available)
              if (paymentMethod.imageUrl != null &&
                  paymentMethod.imageUrl!.isNotEmpty)
                CustomImage(
                  height: 20,
                  fit: BoxFit.contain,
                  image: paymentMethod.imageUrl!,
                ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  paymentMethod.paymentMethodAr ??
                      paymentMethod.paymentMethodEn ??
                      'Unknown',
                  style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Align(
        alignment: Alignment.topRight,
        child: InkWell(
          onTap: () {
            Get.back();
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.all(3),
            child: const Icon(Icons.clear),
          ),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      GetBuilder<WalletController>(builder: (walletController) {
        return Container(
          constraints: BoxConstraints(
              minHeight: context.height * 0.2, maxHeight: context.height * 0.8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
          ),
          width: context.width,
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  Text('add_fund_to_wallet'.tr,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge)),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text('add_fund_form_secured_digital_payment_gateways'.tr,
                      style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall),
                      textAlign: TextAlign.center),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  CustomTextField(
                    titleText: 'enter_amount'.tr,
                    hintText: 'enter_amount'.tr,
                    showLabelText: false,
                    inputType: TextInputType.number,
                    focusNode: focusNode,
                    inputAction: TextInputAction.done,
                    controller: inputAmountController,
                    textAlign: TextAlign.center,
                    onChanged: (String value) {
                      try {
                        if (double.parse(value) > 0) {
                          walletController.isTextFieldEmpty(value);
                          // Reload payment methods with new amount
                          _loadPaymentMethods(double.parse(value));
                        }
                      } catch (e) {
                        showCustomSnackBar('invalid_input'.tr);
                        walletController.isTextFieldEmpty('');
                      }
                    },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  walletController.amountEmpty &&
                          inputAmountController.text.isNotEmpty
                      ? Row(children: [
                          Text('payment_method'.tr,
                              style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeLarge)),
                          const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall),
                          Expanded(
                              child: Text(
                                  'faster_and_secure_way_to_pay_bill'.tr,
                                  style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).hintColor))),
                        ])
                      : const SizedBox(),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  walletController.amountEmpty &&
                          inputAmountController.text.isNotEmpty
                      ? _buildPaymentMethodsList(walletController)
                      : const SizedBox(),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ]),
              ),
            ),
            CustomButton(
              buttonText: 'add_fund'.tr,
              isLoading: walletController.isLoading,
              onPressed: () async {
                if (inputAmountController.text.isEmpty) {
                  showCustomSnackBar('please_provide_transfer_amount'.tr);
                } else if (double.parse(inputAmountController.text) <= 0) {
                  showCustomSnackBar(
                      'you_can_not_add_less_then_zero_amount_in_wallet'.tr);
                } else if (inputAmountController.text == '0') {
                  showCustomSnackBar(
                      'you_can_not_add_zero_amount_in_wallet'.tr);
                } else if (walletController.selectedPaymentMethod == null) {
                  showCustomSnackBar('please_select_payment_method'.tr);
                } else {
                  final double amount = double.parse(inputAmountController.text
                      .replaceAll(
                          Get.find<SplashController>()
                              .configModel!
                              .currencySymbol!,
                          ''));

                  // Reload payment methods with the actual amount
                  await _loadPaymentMethods(amount);

                  // Process MyFatoorah payment
                  final bool success = await walletController
                      .processMyFatoorahWalletPayment(amount);
                  if (success) {
                    Get.back();
                  }
                }
              },
            ),
          ]),
        );
      })
    ]);
  }
}
