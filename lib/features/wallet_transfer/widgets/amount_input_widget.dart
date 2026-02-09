import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Widget for amount input with balance display
/// Shows available balance based on selected payment source
class AmountInputWidget extends StatelessWidget {
  final TextEditingController amountController;
  final double availableBalance;
  final String paymentSource;

  const AmountInputWidget({
    super.key,
    required this.amountController,
    required this.availableBalance,
    required this.paymentSource,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount input
        CustomTextField(
          titleText: 'amount_to_send'.tr,
          hintText: 'enter_amount'.tr,
          controller: amountController,
          inputType: TextInputType.number,
          isAmount: true,
          isNumber: true,
          labelText: 'amount_to_send'.tr,
        ),

        const SizedBox(height: Dimensions.paddingSizeSmall),

        // Available balance display
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            border: Border.all(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'available_balance'.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              Text(
                PriceConverter.convertPrice(availableBalance),
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Quick amount buttons (optional)
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _buildQuickAmountButtons(context),
      ],
    );
  }

  /// Builds quick amount selection buttons
  Widget _buildQuickAmountButtons(BuildContext context) {
    final quickAmounts = [50, 100, 200, 500];

    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      children: quickAmounts.map((amount) {
        return OutlinedButton(
          onPressed: () {
            if (amount <= availableBalance) {
              amountController.text = amount.toString();
            }
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
          ),
          child: Text(
            PriceConverter.convertPrice(amount.toDouble()),
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        );
      }).toList(),
    );
  }
}





