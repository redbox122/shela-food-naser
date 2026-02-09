import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Confirmation dialog before executing transfer
/// Shows transfer details and asks for user confirmation
class TransferConfirmationDialog extends StatelessWidget {
  final String recipientName;
  final String recipientPhone;
  final double amount;
  final String paymentSource;
  final VoidCallback onConfirm;

  const TransferConfirmationDialog({
    super.key,
    required this.recipientName,
    required this.recipientPhone,
    required this.amount,
    required this.paymentSource,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final String sourceText = paymentSource == 'wallet' 
        ? 'regular_wallet'.tr 
        : 'qidha_wallet'.tr;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Title
            Text(
              'confirm_transfer'.tr,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeExtraLarge,
              ),
            ),
            
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Amount - BIG
            Text(
              PriceConverter.convertPrice(amount),
              style: robotoBold.copyWith(
                fontSize: 36,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Transfer details
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, 'recipient'.tr, recipientName),
                  const Divider(),
                  _buildDetailRow(context, 'phone'.tr, recipientPhone),
                  const Divider(),
                  _buildDetailRow(context, 'payment_source'.tr, sourceText),
                ],
              ),
            ),
            
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                    ),
                    child: Text(
                      'confirm'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds detail row
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).disabledColor,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
