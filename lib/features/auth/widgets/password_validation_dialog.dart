import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/features/auth/controllers/deliveryman_registration_controller.dart';

/// Password validation dialog that shows only the failed validation rules
class PasswordValidationDialog extends StatelessWidget {
  final bool forStoreRegistration;

  const PasswordValidationDialog({super.key, this.forStoreRegistration = true});

  @override
  Widget build(BuildContext context) {
    if (forStoreRegistration) {
      return GetBuilder<StoreRegistrationController>(
        builder: (storeRegController) {
          // Get only the failed validation rules
          final List<ValidationRule> failedRules =
              _getFailedRulesFromStore(storeRegController);
          return _buildDialog(failedRules, context);
        },
      );
    } else {
      return GetBuilder<DeliverymanRegistrationController>(
        builder: (deliveryRegController) {
          // Get only the failed validation rules
          final List<ValidationRule> failedRules =
              _getFailedRulesFromDelivery(deliveryRegController);
          return _buildDialog(failedRules, context);
        },
      );
    }
  }

  Widget _buildDialog(List<ValidationRule> failedRules, BuildContext context) {
    if (failedRules.isEmpty) {
      // If no failed rules, don't show dialog
      return const SizedBox.shrink();
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'password_requirements'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              'password_must_contain'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Failed rules list
            ...failedRules.map((rule) => _buildRuleItem(rule, context)),

            const SizedBox(height: 24),

            // OK Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ok'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ValidationRule> _getFailedRulesFromStore(
      StoreRegistrationController controller) {
    final List<ValidationRule> failedRules = [];

    if (!controller.lengthCheck) {
      failedRules.add(ValidationRule('8_or_more_character'.tr, false));
    }
    if (!controller.numberCheck) {
      failedRules.add(ValidationRule('1_number'.tr, false));
    }
    if (!controller.uppercaseCheck) {
      failedRules.add(ValidationRule('1_upper_case'.tr, false));
    }
    if (!controller.lowercaseCheck) {
      failedRules.add(ValidationRule('1_lower_case'.tr, false));
    }
    if (!controller.spatialCheck) {
      failedRules.add(ValidationRule('1_special_character'.tr, false));
    }

    return failedRules;
  }

  List<ValidationRule> _getFailedRulesFromDelivery(
      DeliverymanRegistrationController controller) {
    final List<ValidationRule> failedRules = [];

    if (!controller.lengthCheck) {
      failedRules.add(ValidationRule('8_or_more_character'.tr, false));
    }
    if (!controller.numberCheck) {
      failedRules.add(ValidationRule('1_number'.tr, false));
    }
    if (!controller.uppercaseCheck) {
      failedRules.add(ValidationRule('1_upper_case'.tr, false));
    }
    if (!controller.lowercaseCheck) {
      failedRules.add(ValidationRule('1_lower_case'.tr, false));
    }
    if (!controller.spatialCheck) {
      failedRules.add(ValidationRule('1_special_character'.tr, false));
    }

    return failedRules;
  }

  Widget _buildRuleItem(ValidationRule rule, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.close,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule.text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ValidationRule {
  final String text;
  final bool isValid;

  ValidationRule(this.text, this.isValid);
}

/// Helper function to show password validation dialog
void showPasswordValidationDialog({bool forStoreRegistration = true}) {
  Get.dialog(
    PasswordValidationDialog(forStoreRegistration: forStoreRegistration),
  );
}
