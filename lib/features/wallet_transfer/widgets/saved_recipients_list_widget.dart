import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/wallet_transfer/controllers/wallet_transfer_controller.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/saved_recipient_model.dart';
import 'package:sixam_mart/features/wallet_transfer/widgets/animated_recipient_card.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Widget displaying horizontal scrollable list of saved recipients
/// Allows quick selection of frequently used contacts
class SavedRecipientsListWidget extends StatelessWidget {
  final Function(SavedRecipientModel) onRecipientSelected;

  const SavedRecipientsListWidget({
    super.key,
    required this.onRecipientSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletTransferController>(
      builder: (controller) {
        if (controller.savedRecipients == null || controller.savedRecipients!.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Text(
                'saved_recipients'.tr,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                itemCount: controller.savedRecipients!.length,
                itemBuilder: (context, index) {
                  return AnimatedRecipientCard(
                    recipient: controller.savedRecipients![index],
                    onTap: () => onRecipientSelected(controller.savedRecipients![index]),
                    onDelete: () => _showDeleteConfirmation(context, controller, controller.savedRecipients![index]),
                  );
                },
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
        );
      },
    );
  }

  /// Shows confirmation dialog before deleting recipient
  void _showDeleteConfirmation(
    BuildContext context,
    WalletTransferController controller,
    SavedRecipientModel recipient,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_recipient'.tr),
        content: Text('confirm_delete_recipient'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteSavedRecipient(recipient.id!);
            },
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

