import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/wallet_transfer/controllers/wallet_transfer_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Widget for recipient phone number input with validation
/// Shows validated recipient information after successful validation
class RecipientInputWidget extends StatelessWidget {
  final TextEditingController phoneController;

  const RecipientInputWidget({
    super.key,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletTransferController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phone number input
            CustomTextField(
              titleText: 'recipient_phone'.tr,
              hintText: 'enter_recipient_phone'.tr,
              controller: phoneController,
              inputType: TextInputType.phone,
              isNumber: true,
              labelText: 'recipient_phone'.tr,
              suffixChild: _buildValidateButton(controller),
              onChanged: (value) {
                if (controller.validatedRecipient != null) {
                  controller.clearValidatedRecipient();
                }
              },
            ),
            
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Show validated recipient info
            if (controller.validatedRecipient != null)
              _buildValidatedRecipientCard(context, controller),
          ],
        );
      },
    );
  }

  /// Builds validate button
  Widget _buildValidateButton(WalletTransferController controller) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: controller.isValidating
            ? null
            : () {
                if (phoneController.text.isNotEmpty) {
                  controller.validateRecipient(phoneController.text);
                }
              },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
        ),
        child: controller.isValidating
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'validate_recipient'.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
      ),
    );
  }

  /// Builds validated recipient information card - simple
  Widget _buildValidatedRecipientCard(
    BuildContext context,
    WalletTransferController controller,
  ) {
    final recipient = controller.validatedRecipient!;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor,
        ),
      ),
      child: Row(
        children: [
          // Recipient image
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: CustomImage(
                image: recipient.image ?? '',
                height: 50,
                width: 50,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          
          // Recipient info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      'recipient_validated'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  '${'sending_to'.tr}: ${recipient.name}',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
                Text(
                  recipient.phone ?? '',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
